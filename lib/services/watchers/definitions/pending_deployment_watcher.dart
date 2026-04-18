/// Recurring watcher that monitors for pending deployment approvals.
library;

import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/watchers/serializable_watcher.dart';
import 'package:diohub/services/watchers/watcher_definition.dart';
import 'package:diohub/services/watchers/watcher_types.dart';

class PendingDeploymentWatcher extends PollingWatcher with SerializableWatcher {
  PendingDeploymentWatcher({
    required this.repoRef,
    super.interval = const Duration(minutes: 10),
    super.enabled = true,
  });

  final RepoRef repoRef;

  @override
  String get key => 'pending_deployment';
  @override
  String get instanceId => '${repoRef.owner}/${repoRef.name}';
  @override
  String get displayName =>
      'Pending deployments in ${repoRef.owner}/${repoRef.name}';

  @override
  Future<List<AlertPayload>> fetchUpdates(
    WatcherContext ctx,
    DateTime? lastChecked,
  ) async {
    final response = await ctx.apiClient.get(
      '/repos/${repoRef.owner}/${repoRef.name}/actions/runs',
      queryParameters: {
        'status': 'waiting',
        'per_page': 20,
      },
    );

    final runs = (response.data['workflow_runs'] as List<dynamic>?) ?? [];
    final pendingRuns = runs.where((run) {
      final runMap = run as Map<String, dynamic>;
      return runMap['status'] == 'waiting';
    }).toList();

    if (pendingRuns.isEmpty) return [];

    final lastSeenIds = await ctx.read<List<dynamic>?>('_last_pending_ids') ?? [];
    final lastSeenIdSet = lastSeenIds.cast<int>().toSet();

    final newPending = pendingRuns.where((run) {
      final runMap = run as Map<String, dynamic>;
      final id = runMap['id'] as int;
      return !lastSeenIdSet.contains(id);
    }).toList();

    if (newPending.isEmpty) return [];

    final currentIds = pendingRuns
        .map((r) => (r as Map<String, dynamic>)['id'] as int)
        .toList();
    await ctx.write('_last_pending_ids', currentIds);

    return newPending.map((run) {
      final runMap = run as Map<String, dynamic>;
      final runId = runMap['id'] as int;
      final name = runMap['name'] as String? ?? 'Workflow';
      final environment = runMap['display_title'] as String?;

      return AlertPayload(
        id: 'pending_deployment:${repoRef.owner}/${repoRef.name}:$runId',
        title: '⏳ $name — Approval required',
        body: '${environment != null ? '$environment in ' : ''}${repoRef.owner}/${repoRef.name}',
        watcherKey: key,
        channels: const {
          AlertChannel.inAppToast,
          AlertChannel.systemNotification,
        },
        priority: AlertPriority.high,
        groupKey: 'deployments:${repoRef.owner}/${repoRef.name}',
        metadata: {'run_id': runId.toString()},
        entityRef: WorkflowRunRef(
          repo: repoRef,
          runId: runId,
        ),
      );
    }).toList();
  }

  @override
  Map<String, dynamic> toJson() => {
        'key': key,
        'repoOwner': repoRef.owner,
        'repoName': repoRef.name,
        'interval': interval.inSeconds,
        'enabled': enabled,
      };

  static PendingDeploymentWatcher fromJson(Map<String, dynamic> json) =>
      PendingDeploymentWatcher(
        repoRef: RepoRef(
          owner: json['repoOwner'] as String,
          name: json['repoName'] as String,
        ),
        interval: Duration(seconds: json['interval'] as int? ?? 600),
        enabled: json['enabled'] as bool? ?? true,
      );
}
