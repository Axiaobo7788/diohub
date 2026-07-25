import 'resource_models.dart';

enum ResourceMetricKind {
  freshCacheHit,
  staleCacheHit,
  loadStarted,
  singleFlightJoin,
  prefetchStarted,
  prefetchPromoted,
  prefetchClaimed,
  prefetchCanceled,
  prefetchWasted,
  staleCompletionDropped,
  refreshFailureRetainedData,
  dependencyCacheHit,
  dependencyLoaded,
  loadCompleted,
}

final class ResourceTelemetryEvent {
  const ResourceTelemetryEvent({
    required this.kind,
    required this.resourceKind,
    required this.at,
    this.duration,
  });

  final ResourceMetricKind kind;

  /// Only the non-sensitive resource kind is recorded. Scope principals and
  /// resource keys are deliberately excluded.
  final String resourceKind;
  final DateTime at;
  final Duration? duration;
}

final class ResourceRuntimeStats {
  const ResourceRuntimeStats({
    required this.entryCount,
    required this.estimatedWeight,
    this.overEntryBudget = false,
    this.overWeightBudget = false,
  });

  final int entryCount;
  final int estimatedWeight;
  final bool overEntryBudget;
  final bool overWeightBudget;

  int get estimatedBytes => estimatedWeight * resourceWeightUnitBytes;
}

/// In-memory Debug/test telemetry sink.
final class ResourceTelemetry {
  final List<ResourceTelemetryEvent> _events = <ResourceTelemetryEvent>[];
  ResourceRuntimeStats _stats = const ResourceRuntimeStats(
    entryCount: 0,
    estimatedWeight: 0,
  );

  List<ResourceTelemetryEvent> get events =>
      List<ResourceTelemetryEvent>.unmodifiable(_events);
  ResourceRuntimeStats get stats => _stats;

  int count(final ResourceMetricKind kind) =>
      _events.where((final ResourceTelemetryEvent e) => e.kind == kind).length;

  void record(
    final ResourceMetricKind kind,
    final ResourceId<dynamic> id,
    final DateTime at, {
    final Duration? duration,
  }) {
    _events.add(
      ResourceTelemetryEvent(
        kind: kind,
        resourceKind: id.kind,
        at: at,
        duration: duration,
      ),
    );
  }

  void updateStats({
    required final int entryCount,
    required final int estimatedWeight,
    final bool overEntryBudget = false,
    final bool overWeightBudget = false,
  }) {
    _stats = ResourceRuntimeStats(
      entryCount: entryCount,
      estimatedWeight: estimatedWeight,
      overEntryBudget: overEntryBudget,
      overWeightBudget: overWeightBudget,
    );
  }
}
