part of 'in_memory_resource_runtime.dart';

final class _ResourceEntry {
  _ResourceEntry({required this.spec, required final DateTime now})
    : valueType = spec.id.valueType,
      tags = Set<ResourceTag>.unmodifiable(spec.tags),
      dependencies = Set<ResourceId<dynamic>>.unmodifiable(spec.dependencies),
      lastAccess = now,
      estimatedWeight = spec.policy.estimatedWeight;

  final ResourceSpec<dynamic> spec;
  final Type valueType;
  final Set<ResourceTag> tags;
  final Set<ResourceId<dynamic>> dependencies;
  ResourceSnapshot<dynamic> snapshot = const ResourceLoading<dynamic>();
  ScheduledResourceTask<ResourceLoadResult<dynamic>>? inFlight;
  Future<void>? inFlightDone;
  ResourcePriority? inFlightPriority;
  int generation = 0;
  int dataRevision = 0;
  Map<ResourceId<dynamic>, int> dependencyRevisions =
      const <ResourceId<dynamic>, int>{};
  final Map<ResourceId<dynamic>, int> loadingDependencyRevisions =
      <ResourceId<dynamic>, int>{};
  final Map<int, ResourcePresence> leases = <int, ResourcePresence>{};
  final StreamController<ResourceSnapshot<dynamic>> changes =
      StreamController<ResourceSnapshot<dynamic>>.broadcast();
  DateTime lastAccess;
  int estimatedWeight;
  bool pendingRevalidate = false;
  bool wasPrefetched = false;
  bool prefetchClaimed = false;
  bool currentPrefetchCanceled = false;
  bool active = true;

  bool get hasVisibleLease => leases.values.any(
    (final ResourcePresence presence) => presence == ResourcePresence.visible,
  );
}

final class _ResourceLease<T> implements ResourceLease<T> {
  _ResourceLease({
    required this.entry,
    required this.onPresence,
    required this.onRefresh,
    required this.onRelease,
  });

  final _ResourceEntry entry;
  final void Function(ResourcePresence) onPresence;
  final Future<void> Function() onRefresh;
  final void Function() onRelease;
  bool _released = false;

  @override
  ResourceSnapshot<T> get value => _asTyped(entry.snapshot);

  @override
  Stream<ResourceSnapshot<T>> get changes => entry.changes.stream.map(_asTyped);

  @override
  void setPresence(final ResourcePresence presence) {
    if (_released) return;
    onPresence(presence);
  }

  @override
  Future<void> refresh() => _released ? Future<void>.value() : onRefresh();

  @override
  void release() {
    if (_released) return;
    _released = true;
    onRelease();
  }

  ResourceSnapshot<T> _asTyped(final ResourceSnapshot<dynamic> snapshot) {
    return switch (snapshot) {
      ResourceLoading<dynamic>() => ResourceLoading<T>(),
      ResourceData<dynamic>(
        :final data,
        :final freshness,
        :final origin,
        :final isRefreshing,
        :final lastRefreshError,
        :final fetchedAt,
      ) =>
        ResourceData<T>(
          data: data as T,
          freshness: freshness,
          origin: origin,
          isRefreshing: isRefreshing,
          lastRefreshError: lastRefreshError,
          fetchedAt: fetchedAt,
        ),
      ResourceFailure<dynamic>(:final error, :final stackTrace) =>
        ResourceFailure<T>(error, stackTrace),
    };
  }
}

final class _RuntimePrefetchTicket implements PrefetchTicket {
  const _RuntimePrefetchTicket({
    required this.done,
    required this.claimed,
    required this.onCancel,
  });

  @override
  final Future<void> done;
  final bool Function() claimed;
  final bool Function() onCancel;

  @override
  bool get isClaimed => claimed();

  @override
  bool cancel() => onCancel();
}

final class _CompletedPrefetchTicket implements PrefetchTicket {
  const _CompletedPrefetchTicket();

  @override
  Future<void> get done => Future<void>.value();

  @override
  bool get isClaimed => false;

  @override
  bool cancel() => false;
}
