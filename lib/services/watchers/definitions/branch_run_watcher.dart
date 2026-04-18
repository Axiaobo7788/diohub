/// Recurring watcher that monitors CI status for a specific branch.
library;

import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/watchers/serializable_watcher.dart';
import 'package:diohub/services/watchers/watcher_definition.dart';
import 'package:diohub/services/watchers/watcher_types.dart';

class BranchRunWatcher extends PollingWatcher with SerializableWatcher {
  BranchRunWatcher({
    required this.repoRef,
    required this.branchName,
    super.interval = const Duration(minutes: 10),
    super.enabled = true,
  });

  final RepoRef repoRef;
  final String branchName;

  @override
  String get key => 'branch_run';
  @override
  String get instanceId =>
      '${repoRef.owner}/${repoRef.name}/$branchName';
  @override
  String get displayName =>
      'CI on $branchName in ${repoRef.owner}/${repoRef.name}';

  @override
  Future<List<AlertPayload>> fetchUpdates(
    WatcherContext ctx,
    DateTime? lastChecked,
  ) async {
    final response = await ctx.apiClient.get(
      '/repos/${repoRef.owner}/${repoRef.name}/actions/runs',
      queryParameters: {
        'branch': branchName,
        'per_page': 5,
      },
    );

    final runs = (response.data['workflow_runs'] as List<dynamic>?) ?? [];
    if (runs.isEmpty) return [];

    final lastSeenRunId = await ctx.read<int?>('_last_run_id');

    final completedRuns = runs.where((run) {
      final runMap = run as Map<String, dynamic>;
      return runMap['status'] == 'completed';
    }).toList();

    if (completedRuns.isEmpty) return [];

    final latestRun = completedRuns.first as Map<String, dynamic>;
    final latestRunId = latestRun['id'] as int;

    if (lastSeenRunId == null) {
      await ctx.write('_last_run_id', latestRunId);
      return [];
    }

    if (latestRunId == lastSeenRunId) {
      return [];
    }

    await ctx.write('_last_run_id', latestRunId);

    final conclusion = latestRun['conclusion'] as String?;
    final workflowName = latestRun['name'] as String? ?? 'CI';

    final icon = switch (conclusion) {
      'success' => '✅',
      'failure' => '❌',
      'cancelled' => '⚪',
      _ => '🔵',
    };

    return [
      AlertPayload(
        id: 'branch_run:${repoRef.owner}/${repoRef.name}:$branchName:$latestRunId',
        title: '$icon $workflowName on $branchName — ${conclusion ?? 'completed'}',
        body: '${repoRef.owner}/${repoRef.name}',
        watcherKey: key,
        channels: const {
          AlertChannel.inAppToast,
          AlertChannel.systemNotification,
        },
        priority: conclusion == 'failure' ? AlertPriority.high : AlertPriority.normal,
        groupKey: 'ci:${repoRef.owner}/${repoRef.name}',
        metadata: {
          'conclusion': conclusion ?? 'unknown',
          'branch': branchName,
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
        'branchName': branchName,
        'interval': interval.inSeconds,
        'enabled': enabled,
      };

  static BranchRunWatcher fromJson(Map<String, dynamic> json) =>
      BranchRunWatcher(
        repoRef: RepoRef(
          owner: json['repoOwner'] as String,
          name: json['repoName'] as String,
        ),
        branchName: json['branchName'] as String,
        interval: Duration(seconds: json['interval'] as int? ?? 600),
        enabled: json['enabled'] as bool? ?? true,
      );
}
