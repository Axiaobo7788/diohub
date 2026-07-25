part of 'in_memory_resource_runtime.dart';

extension _ResourceRuntimeCache on InMemoryResourceRuntime {
  void _enforceBudget() {
    _evictUntil(
      targetEntries: cacheConfig.maxEntries,
      targetWeight: cacheConfig.maxEstimatedWeight,
    );
  }

  void _evictUntil({
    required final int targetEntries,
    required final int targetWeight,
  }) {
    List<_ResourceEntry> candidates() =>
        _entries.values
            .where(
              (final _ResourceEntry entry) =>
                  entry.leases.isEmpty && !_isDependencyOfLeasedResource(entry),
            )
            .toList()
          ..sort(_evictionOrder);

    final List<_ResourceEntry> available = candidates();
    while ((_entries.length > targetEntries ||
            _estimatedWeight > targetWeight) &&
        available.isNotEmpty) {
      _evict(available.removeAt(0));
    }
    _updateStats();
  }

  bool _isDependencyOfLeasedResource(final _ResourceEntry entry) {
    final Set<ResourceId<dynamic>> visited = <ResourceId<dynamic>>{};
    final List<ResourceId<dynamic>> pending = <ResourceId<dynamic>>[
      entry.spec.id,
    ];
    while (pending.isNotEmpty) {
      final ResourceId<dynamic> current = pending.removeLast();
      if (!visited.add(current)) {
        continue;
      }
      for (final ResourceId<dynamic> dependentId
          in _dependentsByDependency[current] ??
              const <ResourceId<dynamic>>{}) {
        final _ResourceEntry? dependent = _entries[dependentId];
        if (dependent == null || !dependent.active) {
          continue;
        }
        if (dependent.leases.isNotEmpty) {
          return true;
        }
        pending.add(dependentId);
      }
    }
    return false;
  }

  int _evictionOrder(final _ResourceEntry a, final _ResourceEntry b) {
    int rank(final _ResourceEntry entry) {
      if (entry.wasPrefetched && !entry.prefetchClaimed) {
        return 0;
      }
      final Duration idle = _clock.now().difference(entry.lastAccess);
      if (idle >= entry.spec.policy.retainFor) {
        return 1;
      }
      return 2;
    }

    final int priority = rank(a).compareTo(rank(b));
    return priority != 0 ? priority : a.lastAccess.compareTo(b.lastAccess);
  }

  void _evict(final _ResourceEntry entry, {final bool scopeEviction = false}) {
    if (!entry.active || !identical(_entries[entry.spec.id], entry)) {
      return;
    }
    _entries.remove(entry.spec.id);
    entry
      ..active = false
      ..generation = entry.generation + 1;
    if (entry.wasPrefetched &&
        !entry.prefetchClaimed &&
        !entry.currentPrefetchCanceled) {
      _record(ResourceMetricKind.prefetchWasted, entry);
    }
    entry.inFlight?.cancel();
    for (final ResourceId<dynamic> dependency in entry.dependencies) {
      final Set<ResourceId<dynamic>>? dependents =
          _dependentsByDependency[dependency];
      dependents?.remove(entry.spec.id);
      if (dependents?.isEmpty ?? false) {
        _dependentsByDependency.remove(dependency);
      }
    }
    if (scopeEviction && entry.leases.isNotEmpty) {
      entry.snapshot = ResourceFailure<dynamic>(
        ResourceScopeEvicted(entry.spec.id.scope),
      );
      entry.changes.add(entry.snapshot);
    }
    unawaited(entry.changes.close());
  }

  int get _estimatedWeight => _entries.values.fold<int>(
    0,
    (final int total, final _ResourceEntry entry) =>
        total + entry.estimatedWeight,
  );

  void _updateStats() {
    final int estimatedWeight = _estimatedWeight;
    _telemetry.updateStats(
      entryCount: _entries.length,
      estimatedWeight: estimatedWeight,
      overEntryBudget: _entries.length > cacheConfig.maxEntries,
      overWeightBudget: estimatedWeight > cacheConfig.maxEstimatedWeight,
    );
  }
}
