import 'dart:async';

import 'resource_worker.dart';

/// One cache-weight unit represents 4 KiB of retained data.
///
/// Resource weights are estimates rather than heap measurements, but every
/// resource must use this common unit so directories, text, and image bytes can
/// share one bounded budget.
const int resourceWeightUnitBytes = 4096;

int resourceWeightForBytes(final int bytes) =>
    bytes <= 0 ? 1 : (bytes / resourceWeightUnitBytes).ceil();

/// Whether a resource is currently visible or only retained by a page session.
enum ResourcePresence { visible, retained }

/// Scheduling priority for resource work.
enum ResourcePriority { interactive, refresh, prefetch }

/// Scheduling lane used by one resource loader.
///
/// Keeping network, CPU parsing, and image preparation on independent budgets
/// prevents one kind of expensive work from occupying every runtime slot.
/// Selecting a lane does not move work to another isolate; CPU work must call
/// [ResourceLoadContext.runInWorker] explicitly.
enum ResourceWorkKind { network, compute, decode }

/// Freshness of data already delivered by the runtime.
enum ResourceFreshness { fresh, stale }

/// Origin reported by the domain loader.
enum ResourceOrigin { network, transportCache, derived }

/// Foreground state relevant to speculative resource work.
enum ResourceAppState { active, hidden, paused }

/// Stable server and principal boundary for all resource identities.
final class ResourceScope {
  const ResourceScope({required this.serverId, required this.principal})
    : assert(serverId != ''),
      assert(principal != '');

  final String serverId;
  final String principal;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ResourceScope &&
          other.serverId == serverId &&
          other.principal == principal;

  @override
  int get hashCode => Object.hash(serverId, principal);

  @override
  String toString() => 'ResourceScope($serverId, $principal)';
}

/// Type-safe identity for one read-only resource.
///
/// Equality intentionally excludes [valueType]. Reusing the same logical
/// identity with a different generic type is therefore detected by the
/// runtime instead of silently creating two caches.
final class ResourceId<T> {
  const ResourceId({
    required this.kind,
    required this.version,
    required this.scope,
    required this.key,
  }) : assert(kind != ''),
       assert(version > 0),
       assert(key != '');

  final String kind;
  final int version;
  final ResourceScope scope;
  final String key;

  Type get valueType => T;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ResourceId &&
          other.kind == kind &&
          other.version == version &&
          other.scope == scope &&
          other.key == key;

  @override
  int get hashCode => Object.hash(kind, version, scope, key);

  @override
  String toString() => '$kind/v$version';
}

/// Exact tag used for invalidation. Tags are never fuzzy matched.
final class ResourceTag {
  const ResourceTag(this.namespace, this.value)
    : assert(namespace != ''),
      assert(value != '');

  final String namespace;
  final String value;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ResourceTag &&
          other.namespace == namespace &&
          other.value == value;

  @override
  int get hashCode => Object.hash(namespace, value);
}

/// Delivery and retention policy for one resource contract.
final class ResourcePolicy {
  const ResourcePolicy({
    required this.freshFor,
    required this.retainFor,
    this.estimatedWeight = 1,
    this.allowPrefetch = true,
  }) : assert(estimatedWeight > 0);

  final Duration freshFor;
  final Duration retainFor;
  final int estimatedWeight;
  final bool allowPrefetch;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ResourcePolicy &&
          other.freshFor == freshFor &&
          other.retainFor == retainFor &&
          other.estimatedWeight == estimatedWeight &&
          other.allowPrefetch == allowPrefetch;

  @override
  int get hashCode =>
      Object.hash(freshFor, retainFor, estimatedWeight, allowPrefetch);
}

/// Runtime-owned dependency reader exposed only while a resource is loading.
abstract interface class ResourceDependencyReader {
  Future<ResourceLoadResult<T>> require<T>(ResourceSpec<T> spec);
}

/// Context supplied to the existing domain loader.
final class ResourceLoadContext {
  const ResourceLoadContext({
    required this.priority,
    required this.generation,
    ResourceDependencyReader? dependencyReader,
    ResourceWorker? worker,
    Set<ResourceId<dynamic>> declaredDependencies =
        const <ResourceId<dynamic>>{},
  }) : _dependencyReader = dependencyReader,
       _worker = worker,
       _declaredDependencies = declaredDependencies;

  final ResourcePriority priority;
  final int generation;
  final ResourceDependencyReader? _dependencyReader;
  final ResourceWorker? _worker;
  final Set<ResourceId<dynamic>> _declaredDependencies;

  /// Resolves a statically declared dependency through the same runtime.
  ///
  /// This preserves Single Flight and cache identity across source and derived
  /// resources. Dependencies must be listed on [ResourceSpec.dependencies].
  Future<ResourceLoadResult<T>> require<T>(final ResourceSpec<T> spec) {
    if (!_declaredDependencies.contains(spec.id)) {
      throw ResourceUndeclaredDependency(spec.id);
    }
    final ResourceDependencyReader? reader = _dependencyReader;
    if (reader == null) {
      throw StateError('This ResourceLoadContext cannot resolve dependencies');
    }
    return reader.require(spec);
  }

  /// Runs a sendable, pure transformation on the configured worker isolate.
  ///
  /// Scheduling lanes limit concurrency, while this method is what actually
  /// moves CPU work away from the caller isolate. Network loaders and Flutter
  /// objects must never be passed here.
  Future<O> runInWorker<I, O>(
    final I input,
    final O Function(I input) operation,
  ) {
    final ResourceWorker? worker = _worker;
    if (worker == null) {
      throw StateError('This ResourceLoadContext has no worker configured');
    }
    return worker.run<I, O>(input, operation);
  }
}

/// Typed value returned by an existing domain service.
final class ResourceLoadResult<T> {
  const ResourceLoadResult({
    required this.data,
    this.origin = ResourceOrigin.network,
    this.estimatedWeight,
  }) : assert(estimatedWeight == null || estimatedWeight > 0);

  final T data;
  final ResourceOrigin origin;
  final int? estimatedWeight;
}

/// Complete resource contract. The loader remains a thin call into an existing
/// domain service and must not retain a Riverpod Ref.
final class ResourceSpec<T> {
  const ResourceSpec({
    required this.id,
    required this.policy,
    required this.tags,
    required this.load,
    required this.contract,
    this.workKind = ResourceWorkKind.network,
    this.dependencies = const <ResourceId<dynamic>>{},
  }) : assert(contract != '');

  final ResourceId<T> id;
  final ResourcePolicy policy;
  final Set<ResourceTag> tags;
  final Future<ResourceLoadResult<T>> Function(ResourceLoadContext context)
  load;

  /// Stable semantic loader contract used to detect conflicting specs.
  final String contract;

  /// Scheduling lane used for the loader itself.
  final ResourceWorkKind workKind;

  /// Static resource identities that [load] may resolve through
  /// [ResourceLoadContext.require].
  final Set<ResourceId<dynamic>> dependencies;
}

sealed class ResourceSnapshot<T> {
  const ResourceSnapshot();
}

final class ResourceLoading<T> extends ResourceSnapshot<T> {
  const ResourceLoading();
}

final class ResourceData<T> extends ResourceSnapshot<T> {
  const ResourceData({
    required this.data,
    required this.freshness,
    required this.origin,
    required this.isRefreshing,
    required this.fetchedAt,
    this.lastRefreshError,
  });

  final T data;
  final ResourceFreshness freshness;
  final ResourceOrigin origin;
  final bool isRefreshing;
  final Object? lastRefreshError;
  final DateTime fetchedAt;

  ResourceData<T> copyWith({
    final ResourceFreshness? freshness,
    final bool? isRefreshing,
    final Object? lastRefreshError,
    final bool clearRefreshError = false,
  }) => ResourceData<T>(
    data: data,
    freshness: freshness ?? this.freshness,
    origin: origin,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    lastRefreshError: clearRefreshError
        ? null
        : lastRefreshError ?? this.lastRefreshError,
    fetchedAt: fetchedAt,
  );
}

final class ResourceFailure<T> extends ResourceSnapshot<T> {
  const ResourceFailure(this.error, [this.stackTrace]);

  final Object error;
  final StackTrace? stackTrace;
}

/// Injectable time source. Core tests use a manually advanced implementation.
abstract interface class ResourceClock {
  DateTime now();
}

final class SystemResourceClock implements ResourceClock {
  const SystemResourceClock();

  @override
  DateTime now() => DateTime.now();
}

/// Runtime environment. A null network value means that no reliable source is
/// available; existing transport-cache behavior remains authoritative.
final class ResourceEnvironment {
  const ResourceEnvironment({
    this.appState = ResourceAppState.active,
    this.networkAvailable,
  });

  final ResourceAppState appState;
  final bool? networkAvailable;

  bool get allowsSpeculativeWork =>
      appState == ResourceAppState.active && networkAvailable != false;
}

/// Exact selector for invalidation.
final class ResourceSelector {
  const ResourceSelector({
    this.id,
    this.scope,
    this.tags = const <ResourceTag>{},
  });

  factory ResourceSelector.forId(final ResourceId<dynamic> id) =>
      ResourceSelector(id: id);

  factory ResourceSelector.forTags(
    final Set<ResourceTag> tags, {
    final ResourceScope? scope,
  }) => ResourceSelector(tags: tags, scope: scope);

  final ResourceId<dynamic>? id;
  final ResourceScope? scope;
  final Set<ResourceTag> tags;

  bool matches<T>(final ResourceId<T> candidate, final Set<ResourceTag> value) {
    if (id != null && id != candidate) return false;
    if (scope != null && scope != candidate.scope) return false;
    return tags.isEmpty || value.containsAll(tags);
  }
}

abstract interface class ResourceLease<T> {
  ResourceSnapshot<T> get value;
  Stream<ResourceSnapshot<T>> get changes;

  void setPresence(ResourcePresence presence);
  Future<void> refresh();
  void release();
}

abstract interface class PrefetchTicket {
  Future<void> get done;
  bool get isClaimed;
  bool cancel();
}

final class ResourceContractConflict implements Exception {
  const ResourceContractConflict(this.message);

  final String message;

  @override
  String toString() => 'ResourceContractConflict: $message';
}

final class ResourceScopeEvicted implements Exception {
  const ResourceScopeEvicted(this.scope);

  final ResourceScope scope;

  @override
  String toString() => 'Resource scope was evicted: $scope';
}

final class ResourceUndeclaredDependency implements Exception {
  const ResourceUndeclaredDependency(this.id);

  final ResourceId<dynamic> id;

  @override
  String toString() => 'Resource dependency was not declared: $id';
}

final class ResourceDependencyCycle implements Exception {
  const ResourceDependencyCycle(this.id);

  final ResourceId<dynamic> id;

  @override
  String toString() => 'Resource dependency cycle detected at: $id';
}

final class ResourceDependencyExecutorConflict implements Exception {
  const ResourceDependencyExecutorConflict(this.parent, this.dependency);

  final ResourceId<dynamic> parent;
  final ResourceId<dynamic> dependency;

  @override
  String toString() =>
      'A resource cannot synchronously wait on a dependency in the same '
      'executor budget: $parent -> $dependency';
}
