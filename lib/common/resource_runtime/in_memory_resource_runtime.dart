import 'dart:async';

import 'resource_models.dart';
import 'resource_runtime_base.dart';
import 'resource_scheduler.dart';
import 'resource_telemetry.dart';
import 'resource_worker.dart';

part 'resource_runtime_entry.dart';
part 'resource_runtime_dependencies.dart';
part 'resource_runtime_cache.dart';

final class ResourceCacheConfig {
  const ResourceCacheConfig({
    this.maxEntries = 128,
    this.maxEstimatedWeight = 4096,
    this.trimTargetEntries = 64,
    this.trimTargetWeight = 2048,
  }) : assert(maxEntries > 0),
       assert(maxEstimatedWeight > 0),
       assert(trimTargetEntries >= 0),
       assert(trimTargetEntries <= maxEntries),
       assert(trimTargetWeight >= 0),
       assert(trimTargetWeight <= maxEstimatedWeight);

  final int maxEntries;
  final int maxEstimatedWeight;
  final int trimTargetEntries;
  final int trimTargetWeight;
}

/// Pure Dart L1 runtime. Domain loaders and the existing transport cache remain
/// outside this class.
final class InMemoryResourceRuntime implements ResourceRuntime {
  InMemoryResourceRuntime({
    final ResourceClock clock = const SystemResourceClock(),
    final ResourceExecutorPool? executors,
    final ResourceWorker worker = const IsolateResourceWorker(),
    this.cacheConfig = const ResourceCacheConfig(),
    final ResourceTelemetry? telemetry,
  }) : _clock = clock,
       _executors = executors ?? ResourceExecutorPool(),
       _ownsExecutors = executors == null,
       _worker = worker,
       _telemetry = telemetry ?? ResourceTelemetry();

  final ResourceClock _clock;
  final ResourceExecutorPool _executors;
  final bool _ownsExecutors;
  final ResourceWorker _worker;
  final ResourceCacheConfig cacheConfig;
  final ResourceTelemetry _telemetry;
  final Map<ResourceId<dynamic>, _ResourceEntry> _entries =
      <ResourceId<dynamic>, _ResourceEntry>{};
  final Map<ResourceId<dynamic>, Set<ResourceId<dynamic>>>
  _dependentsByDependency = <ResourceId<dynamic>, Set<ResourceId<dynamic>>>{};
  ResourceEnvironment _environment = const ResourceEnvironment();
  int _nextLeaseId = 0;
  bool _disposed = false;

  @override
  ResourceTelemetry get telemetry => _telemetry;

  @override
  ResourceLease<T> acquire<T>(
    final ResourceSpec<T> spec, {
    final ResourcePresence presence = ResourcePresence.visible,
  }) {
    _checkActive();
    final _ResourceEntry entry = _entryFor(spec);
    entry.lastAccess = _clock.now();
    final int leaseId = _nextLeaseId++;
    entry.leases[leaseId] = presence;

    if (entry.wasPrefetched && !entry.prefetchClaimed) {
      entry.prefetchClaimed = true;
      _record(ResourceMetricKind.prefetchClaimed, entry);
    }
    _prepareForAccess(entry, presence);
    _enforceBudget();
    return _ResourceLease<T>(
      entry: entry,
      onPresence: (final ResourcePresence next) =>
          _setPresence(entry, leaseId, next),
      onRefresh: () => _refresh(entry),
      onRelease: () => _release(entry, leaseId),
    );
  }

  @override
  PrefetchTicket prefetch<T>(
    final ResourceSpec<T> spec, {
    final ResourcePriority priority = ResourcePriority.prefetch,
  }) {
    _checkActive();
    if (!spec.policy.allowPrefetch || !_environment.allowsSpeculativeWork) {
      _telemetry.record(
        ResourceMetricKind.prefetchCanceled,
        spec.id,
        _clock.now(),
      );
      return const _CompletedPrefetchTicket();
    }

    final _ResourceEntry entry = _entryFor(spec);
    entry.lastAccess = _clock.now();
    final ResourceSnapshot<dynamic> snapshot = entry.snapshot;
    if (snapshot is ResourceData<dynamic> && _isFresh(entry, snapshot)) {
      _record(ResourceMetricKind.freshCacheHit, entry);
      return const _CompletedPrefetchTicket();
    }
    if (snapshot is ResourceData<dynamic>) {
      _markStale(entry, snapshot);
    }
    entry.wasPrefetched = true;
    final bool joined = entry.inFlight != null;
    final Future<void> done = _ensureLoad(entry, priority);
    if (joined) {
      _record(ResourceMetricKind.singleFlightJoin, entry);
    }
    final PrefetchTicket ticket = _RuntimePrefetchTicket(
      done: done,
      claimed: () => entry.prefetchClaimed,
      onCancel: () => _cancelQueuedPrefetch(entry),
    );
    _enforceBudget();
    return ticket;
  }

  @override
  void invalidate(final ResourceSelector selector) {
    _checkActive();
    final Set<ResourceId<dynamic>> affected = _entries.values
        .where(
          (final _ResourceEntry entry) =>
              selector.matches(entry.spec.id, entry.tags),
        )
        .map((final _ResourceEntry entry) => entry.spec.id)
        .toSet();
    final ResourceId<dynamic>? selectedId = selector.id;
    if (selectedId != null) {
      affected.add(selectedId);
    }
    final List<ResourceId<dynamic>> pending = affected.toList();
    for (var index = 0; index < pending.length; index++) {
      final ResourceId<dynamic> dependency = pending[index];
      for (final ResourceId<dynamic> dependent
          in _dependentsByDependency[dependency] ??
              const <ResourceId<dynamic>>{}) {
        if (affected.add(dependent)) {
          pending.add(dependent);
        }
      }
    }
    for (final ResourceId<dynamic> id in affected) {
      final _ResourceEntry? entry = _entries[id];
      if (entry != null) {
        _invalidateEntry(entry);
      }
    }
  }

  void _invalidateEntry(final _ResourceEntry entry) {
    entry.generation++;
    final ResourceSnapshot<dynamic> snapshot = entry.snapshot;
    if (snapshot is ResourceData<dynamic>) {
      _markStale(entry, snapshot);
    }
    if (entry.inFlight != null) {
      entry.pendingRevalidate = entry.hasVisibleLease;
    } else if (entry.hasVisibleLease) {
      unawaited(_ensureLoad(entry, ResourcePriority.refresh));
    }
  }

  @override
  void evictScope(final ResourceScope scope) {
    _checkActive();
    final List<_ResourceEntry> candidates = _entries.values
        .where((final _ResourceEntry e) => e.spec.id.scope == scope)
        .toList();
    for (final _ResourceEntry entry in candidates) {
      _evict(entry, scopeEviction: true);
    }
    _updateStats();
  }

  @override
  void updateEnvironment(final ResourceEnvironment environment) {
    _checkActive();
    final ResourceEnvironment previous = _environment;
    _environment = environment;
    if (!environment.allowsSpeculativeWork) {
      for (final _ResourceEntry entry in _entries.values.toList()) {
        _cancelQueuedPrefetch(entry);
      }
    }
    if (previous.appState != ResourceAppState.active &&
        environment.appState == ResourceAppState.active) {
      for (final _ResourceEntry entry in _entries.values) {
        final ResourceSnapshot<dynamic> snapshot = entry.snapshot;
        if (entry.hasVisibleLease &&
            snapshot is ResourceData<dynamic> &&
            !_isFresh(entry, snapshot)) {
          _markStale(entry, snapshot);
          unawaited(_ensureLoad(entry, ResourcePriority.refresh));
        }
      }
    }
  }

  @override
  void trimMemory() {
    _checkActive();
    _evictUntil(
      targetEntries: cacheConfig.trimTargetEntries,
      targetWeight: cacheConfig.trimTargetWeight,
    );
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final _ResourceEntry entry in _entries.values.toList()) {
      _evict(entry);
    }
    if (_ownsExecutors) {
      _executors.dispose();
    }
    _dependentsByDependency.clear();
    _updateStats();
  }

  _ResourceEntry _entryFor<T>(final ResourceSpec<T> spec) {
    final _ResourceEntry? existing = _entries[spec.id];
    if (existing != null) {
      if (existing.valueType != T) {
        throw ResourceContractConflict(
          '${spec.id} was ${existing.valueType}, requested as $T',
        );
      }
      if (existing.spec.policy != spec.policy ||
          existing.spec.contract != spec.contract ||
          existing.spec.workKind != spec.workKind ||
          !_sameTags(existing.tags, spec.tags) ||
          !_sameResourceIds(existing.dependencies, spec.dependencies)) {
        throw ResourceContractConflict(
          '${spec.id} was reused with a conflicting policy, tags, executor, '
          'dependencies, or loader contract',
        );
      }
      return existing;
    }
    _registerDependencies(spec);
    final _ResourceEntry created = _ResourceEntry(
      spec: spec as ResourceSpec<dynamic>,
      now: _clock.now(),
    );
    _entries[spec.id] = created;
    _updateStats();
    return created;
  }

  void _prepareForAccess(
    final _ResourceEntry entry,
    final ResourcePresence presence,
  ) {
    final ResourceSnapshot<dynamic> snapshot = entry.snapshot;
    if (snapshot is ResourceData<dynamic>) {
      if (_isFresh(entry, snapshot)) {
        _record(ResourceMetricKind.freshCacheHit, entry);
        return;
      }
      _record(ResourceMetricKind.staleCacheHit, entry);
      _markStale(entry, snapshot);
      if (presence == ResourcePresence.visible) {
        unawaited(_ensureLoad(entry, ResourcePriority.refresh));
      }
      return;
    }
    if (presence == ResourcePresence.retained) return;
    if (entry.inFlight != null) {
      _record(ResourceMetricKind.singleFlightJoin, entry);
      _promotePrefetch(entry);
      return;
    }
    _publish(entry, const ResourceLoading<dynamic>());
    unawaited(_ensureLoad(entry, ResourcePriority.interactive));
  }

  Future<void> _refresh(final _ResourceEntry entry) {
    if (!entry.active) return Future<void>.value();
    final ResourceSnapshot<dynamic> snapshot = entry.snapshot;
    if (snapshot is ResourceData<dynamic>) {
      _markStale(entry, snapshot);
    } else if (entry.inFlight == null) {
      _publish(entry, const ResourceLoading<dynamic>());
    }
    return _ensureLoad(entry, ResourcePriority.refresh);
  }

  Future<void> _ensureLoad(
    final _ResourceEntry entry,
    final ResourcePriority priority, {
    final bool allowWithoutVisibleLease = false,
  }) {
    final ScheduledResourceTask<ResourceLoadResult<dynamic>>? current =
        entry.inFlight;
    if (current != null) {
      _record(ResourceMetricKind.singleFlightJoin, entry);
      if (priority == ResourcePriority.interactive) {
        _promotePrefetch(entry);
      }
      return entry.inFlightDone ?? Future<void>.value();
    }

    if (priority != ResourcePriority.interactive &&
        (!_environment.allowsSpeculativeWork || !entry.hasVisibleLease) &&
        !allowWithoutVisibleLease &&
        priority != ResourcePriority.prefetch) {
      return Future<void>.value();
    }

    final ResourceSnapshot<dynamic> snapshot = entry.snapshot;
    if (snapshot is ResourceData<dynamic>) {
      _publish(
        entry,
        snapshot.copyWith(isRefreshing: true, clearRefreshError: true),
      );
    }
    final int generation = entry.generation;
    final DateTime startedAt = _clock.now();
    entry.loadingDependencyRevisions.clear();
    final ScheduledResourceTask<ResourceLoadResult<dynamic>> task =
        _executors[entry.spec.workKind].schedule<ResourceLoadResult<dynamic>>(
          priority: priority,
          operation: () => entry.spec.load(
            ResourceLoadContext(
              priority: priority,
              generation: generation,
              dependencyReader: _RuntimeDependencyReader(
                runtime: this,
                parent: entry,
                priority: priority,
              ),
              declaredDependencies: entry.dependencies,
              worker: _worker,
            ),
          ),
        );
    final Completer<void> done = Completer<void>();
    entry
      ..inFlight = task
      ..inFlightDone = done.future
      ..inFlightPriority = priority
      ..currentPrefetchCanceled = false;
    _record(ResourceMetricKind.loadStarted, entry);
    if (priority == ResourcePriority.prefetch) {
      _record(ResourceMetricKind.prefetchStarted, entry);
    }
    unawaited(_settleLoad(entry, task, done, generation, startedAt));
    return done.future;
  }

  Future<void> _settleLoad(
    final _ResourceEntry entry,
    final ScheduledResourceTask<ResourceLoadResult<dynamic>> task,
    final Completer<void> done,
    final int generation,
    final DateTime startedAt,
  ) async {
    try {
      final ResourceLoadResult<dynamic> result = await task.result;
      if (!entry.active || entry.generation != generation) {
        _record(ResourceMetricKind.staleCompletionDropped, entry);
        return;
      }
      entry
        ..estimatedWeight =
            result.estimatedWeight ?? entry.spec.policy.estimatedWeight
        ..dataRevision = entry.dataRevision + 1
        ..dependencyRevisions = Map<ResourceId<dynamic>, int>.unmodifiable(
          entry.loadingDependencyRevisions,
        );
      _publish(
        entry,
        ResourceData<dynamic>(
          data: result.data,
          freshness: ResourceFreshness.fresh,
          origin: result.origin,
          isRefreshing: false,
          fetchedAt: _clock.now(),
        ),
      );
      _record(
        ResourceMetricKind.loadCompleted,
        entry,
        duration: _clock.now().difference(startedAt),
      );
    } on ResourceTaskCanceled {
      if (entry.leases.isEmpty && entry.snapshot is ResourceLoading<dynamic>) {
        _evict(entry);
      }
    } catch (error, stackTrace) {
      if (!entry.active || entry.generation != generation) {
        _record(ResourceMetricKind.staleCompletionDropped, entry);
        return;
      }
      final ResourceSnapshot<dynamic> snapshot = entry.snapshot;
      if (snapshot is ResourceData<dynamic>) {
        _publish(
          entry,
          snapshot.copyWith(
            freshness: ResourceFreshness.stale,
            isRefreshing: false,
            lastRefreshError: error,
          ),
        );
        _record(ResourceMetricKind.refreshFailureRetainedData, entry);
      } else {
        _publish(entry, ResourceFailure<dynamic>(error, stackTrace));
      }
    } finally {
      if (identical(entry.inFlight, task)) {
        entry
          ..inFlight = null
          ..inFlightDone = null
          ..inFlightPriority = null
          ..loadingDependencyRevisions.clear();
      }
      if (!done.isCompleted) done.complete();

      final bool revalidate = entry.pendingRevalidate;
      entry.pendingRevalidate = false;
      if (entry.active && revalidate && entry.hasVisibleLease) {
        unawaited(_ensureLoad(entry, ResourcePriority.refresh));
      } else if (entry.active && !entry.hasVisibleLease) {
        final ResourceSnapshot<dynamic> snapshot = entry.snapshot;
        if (snapshot is ResourceData<dynamic> && snapshot.isRefreshing) {
          _publish(
            entry,
            snapshot.copyWith(
              freshness: ResourceFreshness.stale,
              isRefreshing: false,
            ),
          );
        }
      }
      _enforceBudget();
    }
  }

  void _promotePrefetch(final _ResourceEntry entry) {
    if (entry.inFlightPriority != ResourcePriority.prefetch) return;
    if (entry.inFlight?.promote(ResourcePriority.interactive) ?? false) {
      entry.inFlightPriority = ResourcePriority.interactive;
      _record(ResourceMetricKind.prefetchPromoted, entry);
    }
  }

  bool _cancelQueuedPrefetch(final _ResourceEntry entry) {
    if (!entry.active ||
        entry.prefetchClaimed ||
        entry.inFlightPriority != ResourcePriority.prefetch) {
      return false;
    }
    final ScheduledResourceTask<ResourceLoadResult<dynamic>>? task =
        entry.inFlight;
    if (task == null || task.hasStarted || !task.cancel()) {
      return false;
    }
    entry.currentPrefetchCanceled = true;
    _record(ResourceMetricKind.prefetchCanceled, entry);
    return true;
  }

  void _setPresence(
    final _ResourceEntry entry,
    final int leaseId,
    final ResourcePresence presence,
  ) {
    if (!entry.active || !entry.leases.containsKey(leaseId)) return;
    entry
      ..leases[leaseId] = presence
      ..lastAccess = _clock.now();
    if (presence == ResourcePresence.visible) {
      final ResourceSnapshot<dynamic> snapshot = entry.snapshot;
      if (snapshot is ResourceData<dynamic> && !_isFresh(entry, snapshot)) {
        _markStale(entry, snapshot);
        unawaited(_ensureLoad(entry, ResourcePriority.refresh));
      } else if ((snapshot is ResourceFailure<dynamic> ||
              snapshot is ResourceLoading<dynamic>) &&
          entry.inFlight == null) {
        _publish(entry, const ResourceLoading<dynamic>());
        unawaited(_ensureLoad(entry, ResourcePriority.interactive));
      }
    }
  }

  void _release(final _ResourceEntry entry, final int leaseId) {
    if (!entry.active || entry.leases.remove(leaseId) == null) return;
    entry.lastAccess = _clock.now();
    _enforceBudget();
  }

  bool _isFresh(final _ResourceEntry entry, final ResourceData<dynamic> data) =>
      data.freshness == ResourceFreshness.fresh &&
      _clock.now().difference(data.fetchedAt) <= entry.spec.policy.freshFor &&
      _dependenciesAreFresh(entry);

  void _markStale(
    final _ResourceEntry entry,
    final ResourceData<dynamic> data,
  ) {
    if (data.freshness == ResourceFreshness.stale) return;
    _publish(
      entry,
      data.copyWith(freshness: ResourceFreshness.stale, isRefreshing: false),
    );
  }

  void _publish(
    final _ResourceEntry entry,
    final ResourceSnapshot<dynamic> snapshot,
  ) {
    if (!entry.active) return;
    entry
      ..snapshot = snapshot
      ..lastAccess = _clock.now();
    entry.changes.add(snapshot);
  }

  void _record(
    final ResourceMetricKind kind,
    final _ResourceEntry entry, {
    final Duration? duration,
  }) {
    _telemetry.record(kind, entry.spec.id, _clock.now(), duration: duration);
  }

  void _checkActive() {
    if (_disposed) throw StateError('ResourceRuntime is disposed');
  }

  static bool _sameTags(final Set<ResourceTag> a, final Set<ResourceTag> b) =>
      a.length == b.length && a.containsAll(b);
}
