/// One-off watcher that notifies when a workflow run completes.
library;

import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/services/watchers/serializable_watcher.dart';
import 'package:diohub/services/watchers/watcher_definition.dart';
import 'package:diohub/services/watchers/watcher_types.dart';

class RunStatusWatcher extends OneOffWatcher with SerializableWatcher {
  RunStatusWatcher({
    required this.runRef,
    this.runName,
    super.interval = const Duration(seconds: 30),
    super.enabled = true,
  });

  final WorkflowRunRef runRef;
  final String? runName;

  @override
  String get key => 'run_status';
  @override
  String get instanceId =>
      '${runRef.repo.owner}/${runRef.repo.name}/${runRef.runId}';
  @override
  String get displayName =>
      '${runName ?? 'Run #${runRef.runId}'} in ${runRef.repo.owner}/${runRef.repo.name}';

  @override
  Future<OneOffResult> evaluate(WatcherContext ctx) async {
    // .workflows() requires full ApiClient, so cast
    final run = await runRef.repo.workflows(ctx.apiClient as ApiClient).getWorkflowRun(runId: runRef.runId);

    if (run.status != 'completed') {
      return const OneOffResult.pending();
    }

    final conclusion = run.conclusion ?? 'unknown';
    final icon = switch (conclusion) {
      'success' => '✅',
      'failure' => '❌',
      'cancelled' => '⚪',
      _ => '🔵',
    };

    return OneOffResult.completed(
      AlertPayload(
        id: 'run:${runRef.repo.owner}/${runRef.repo.name}:${runRef.runId}',
        title: '$icon ${runName ?? 'Run #${runRef.runId}'} — $conclusion',
        body: '${runRef.repo.owner}/${runRef.repo.name}',
        watcherKey: key,
        channels: const {
          AlertChannel.inAppToast,
          AlertChannel.systemNotification,
        },
        priority:
            conclusion == 'failure' ? AlertPriority.high : AlertPriority.normal,
        groupKey: 'runs:${runRef.repo.owner}/${runRef.repo.name}',
        metadata: {'conclusion': conclusion},
        entityRef: runRef,
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'key': key,
        'repoOwner': runRef.repo.owner,
        'repoName': runRef.repo.name,
        'runId': runRef.runId,
        'runName': runName,
        'interval': interval.inSeconds,
        'enabled': enabled,
      };

  static RunStatusWatcher fromJson(Map<String, dynamic> json) =>
      RunStatusWatcher(
        runRef: WorkflowRunRef(
          repo: RepoRef(
            owner: json['repoOwner'] as String,
            name: json['repoName'] as String,
          ),
          runId: json['runId'] as int,
        ),
        runName: json['runName'] as String?,
        interval: Duration(seconds: json['interval'] as int? ?? 30),
        enabled: json['enabled'] as bool? ?? true,
      );
}
