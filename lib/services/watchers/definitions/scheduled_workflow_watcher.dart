/// Recurring watcher that monitors scheduled workflow runs (e.g., nightly builds).
library;

import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/watchers/serializable_watcher.dart';
import 'package:diohub/services/watchers/watcher_definition.dart';
import 'package:diohub/services/watchers/watcher_types.dart';

class ScheduledWorkflowWatcher extends PollingWatcher with SerializableWatcher {
  ScheduledWorkflowWatcher({
    required this.repoRef,
    required this.workflowId,
    this.workflowName,
    super.interval = const Duration(hours: 1),
    super.enabled = true,
  });

  final RepoRef repoRef;
  final int workflowId;
  final String? workflowName;

  @override
  String get key => 'scheduled_workflow';
  @override
  String get instanceId =>
      '${repoRef.owner}/${repoRef.name}/$workflowId';
  @override
  String get displayName =>
      '${workflowName ?? 'Scheduled workflow'} in ${repoRef.owner}/${repoRef.name}';

  @override
  Future<List<AlertPayload>> fetchUpdates(
    WatcherContext ctx,
    DateTime? lastChecked,
  ) async {
    final response = await ctx.apiClient.get(
      '/repos/${repoRef.owner}/${repoRef.name}/actions/workflows/$workflowId/runs',
      queryParameters: {
        'event': 'schedule',
        'per_page': 5,
      },
    );

    final runs = (response.data['workflow_runs'] as List<dynamic>?) ?? [];
    if (runs.isEmpty) return [];

    final lastSeenRunId = await ctx.read<int?>('_last_scheduled_run_id');

    final completedRuns = runs.where((run) {
      final runMap = run as Map<String, dynamic>;
      return runMap['status'] == 'completed';
    }).toList();

    if (completedRuns.isEmpty) return [];

    final latestRun = completedRuns.first as Map<String, dynamic>;
    final latestRunId = latestRun['id'] as int;

    if (lastSeenRunId == null) {
      await ctx.write('_last_scheduled_run_id', latestRunId);
      return [];
    }

    if (latestRunId == lastSeenRunId) {
      return [];
    }

    await ctx.write('_last_scheduled_run_id', latestRunId);

    final conclusion = latestRun['conclusion'] as String?;
    final name = workflowName ?? latestRun['name'] as String? ?? 'Scheduled workflow';

    final icon = switch (conclusion) {
      'success' => '✅',
      'failure' => '❌',
      'cancelled' => '⚪',
      _ => '🔵',
    };

    return [
      AlertPayload(
        id: 'scheduled:${repoRef.owner}/${repoRef.name}:$workflowId:$latestRunId',
        title: '$icon $name — ${conclusion ?? 'completed'}',
        body: '${repoRef.owner}/${repoRef.name}',
        watcherKey: key,
        channels: const {
          AlertChannel.inAppToast,
          AlertChannel.systemNotification,
        },
        priority: conclusion == 'failure' ? AlertPriority.high : AlertPriority.low,
        groupKey: 'ci:${repoRef.owner}/${repoRef.name}',
        metadata: {
          'conclusion': conclusion ?? 'unknown',
          'workflow_id': workflowId.toString(),
        },
        entityRef: WorkflowRunRef(
          repo: repoRef,
          runId: latestRunId,
        ),
      ),
    ];
  }

  @override
  Map<String, dynamic> toJson() => {
        'key': key,
        'repoOwner': repoRef.owner,
        'repoName': repoRef.name,
        'workflowId': workflowId,
        'workflowName': workflowName,
        'interval': interval.inSeconds,
        'enabled': enabled,
      };

  static ScheduledWorkflowWatcher fromJson(Map<String, dynamic> json) =>
      ScheduledWorkflowWatcher(
        repoRef: RepoRef(
          owner: json['repoOwner'] as String,
          name: json['repoName'] as String,
        ),
        workflowId: json['workflowId'] as int,
        workflowName: json['workflowName'] as String?,
        interval: Duration(seconds: json['interval'] as int? ?? 3600),
        enabled: json['enabled'] as bool? ?? true,
      );
}
