part of 'in_memory_resource_runtime.dart';

extension _ResourceRuntimeDependencies on InMemoryResourceRuntime {
  Future<ResourceLoadResult<T>> _loadDependency<T>({
    required final _ResourceEntry parent,
    required final ResourceSpec<T> spec,
    required final ResourcePriority priority,
  }) async {
    if (!parent.dependencies.contains(spec.id)) {
      throw ResourceUndeclaredDependency(spec.id);
    }
    if (spec.id.scope != parent.spec.id.scope) {
      throw ResourceContractConflict(
        '${parent.spec.id} depends on a resource from another scope',
      );
    }
    if (spec.workKind == parent.spec.workKind) {
      throw ResourceDependencyExecutorConflict(parent.spec.id, spec.id);
    }

    final _ResourceEntry dependency = _entryFor(spec);
    dependency.lastAccess = _clock.now();
    ResourceSnapshot<dynamic> snapshot = dependency.snapshot;
    if (snapshot is ResourceData<dynamic> && _isFresh(dependency, snapshot)) {
      parent.loadingDependencyRevisions[spec.id] = dependency.dataRevision;
      _record(ResourceMetricKind.dependencyCacheHit, dependency);
      return ResourceLoadResult<T>(
        data: snapshot.data as T,
        origin: snapshot.origin,
        estimatedWeight: dependency.estimatedWeight,
      );
    }

    if (snapshot is ResourceData<dynamic>) {
      _markStale(dependency, snapshot);
    } else {
      _publish(dependency, const ResourceLoading<dynamic>());
    }
    if (priority == ResourcePriority.prefetch) {
      dependency.wasPrefetched = true;
    }
    await _ensureLoad(dependency, priority, allowWithoutVisibleLease: true);
    snapshot = dependency.snapshot;
    switch (snapshot) {
      case ResourceData<dynamic>():
        parent.loadingDependencyRevisions[spec.id] = dependency.dataRevision;
        _record(ResourceMetricKind.dependencyLoaded, dependency);
        return ResourceLoadResult<T>(
          data: snapshot.data as T,
          origin: snapshot.origin,
          estimatedWeight: dependency.estimatedWeight,
        );
      case ResourceFailure<dynamic>(:final error, :final stackTrace):
        Error.throwWithStackTrace(error, stackTrace ?? StackTrace.current);
      case ResourceLoading<dynamic>():
        throw StateError('Dependency did not settle: ${spec.id}');
    }
  }

  bool _dependenciesAreFresh(final _ResourceEntry parent) {
    for (final ResourceId<dynamic> id in parent.dependencies) {
      final _ResourceEntry? dependency = _entries[id];
      final ResourceSnapshot<dynamic>? snapshot = dependency?.snapshot;
      if (dependency == null ||
          snapshot is! ResourceData<dynamic> ||
          parent.dependencyRevisions[id] != dependency.dataRevision ||
          !_isFresh(dependency, snapshot)) {
        return false;
      }
    }
    return true;
  }

  void _registerDependencies<T>(final ResourceSpec<T> spec) {
    for (final ResourceId<dynamic> dependency in spec.dependencies) {
      if (dependency.scope != spec.id.scope) {
        throw ResourceContractConflict(
          '${spec.id} depends on a resource from another scope',
        );
      }
      if (dependency == spec.id || _hasDependentPath(spec.id, dependency)) {
        throw ResourceDependencyCycle(spec.id);
      }
    }
    for (final ResourceId<dynamic> dependency in spec.dependencies) {
      _dependentsByDependency
          .putIfAbsent(dependency, () => <ResourceId<dynamic>>{})
          .add(spec.id);
    }
  }

  bool _hasDependentPath(
    final ResourceId<dynamic> from,
    final ResourceId<dynamic> target,
  ) {
    final Set<ResourceId<dynamic>> visited = <ResourceId<dynamic>>{};
    final List<ResourceId<dynamic>> pending = <ResourceId<dynamic>>[from];
    while (pending.isNotEmpty) {
      final ResourceId<dynamic> current = pending.removeLast();
      if (!visited.add(current)) continue;
      if (current == target) return true;
      pending.addAll(
        _dependentsByDependency[current] ?? const <ResourceId<dynamic>>{},
      );
    }
    return false;
  }
}

bool _sameResourceIds(
  final Set<ResourceId<dynamic>> a,
  final Set<ResourceId<dynamic>> b,
) => a.length == b.length && a.containsAll(b);

final class _RuntimeDependencyReader implements ResourceDependencyReader {
  const _RuntimeDependencyReader({
    required this.runtime,
    required this.parent,
    required this.priority,
  });

  final InMemoryResourceRuntime runtime;
  final _ResourceEntry parent;
  final ResourcePriority priority;

  @override
  Future<ResourceLoadResult<T>> require<T>(final ResourceSpec<T> spec) =>
      runtime._loadDependency<T>(
        parent: parent,
        spec: spec,
        priority: priority,
      );
}
