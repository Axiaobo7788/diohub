/// One-off watcher that monitors a deployment's status until completion.
library;

import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/base/rest_pagination_helper.dart';
import 'package:diohub/services/watchers/serializable_watcher.dart';
import 'package:diohub/services/watchers/watcher_definition.dart';
import 'package:diohub/services/watchers/watcher_types.dart';

class DeploymentStatusWatcher extends OneOffWatcher with SerializableWatcher {
  DeploymentStatusWatcher({
    required this.repoRef,
    required this.deploymentId,
    this.environment,
    super.interval = const Duration(minutes: 5),
    super.enabled = true,
  });

  final RepoRef repoRef;
  final int deploymentId;
  final String? environment;

  @override
  String get key => 'deployment_status';
  @override
  String get instanceId =>
      '${repoRef.owner}/${repoRef.name}/$deploymentId';
  @override
  String get displayName =>
      'Deployment to ${environment ?? 'environment'} in ${repoRef.owner}/${repoRef.name}';

  @override
  Future<OneOffResult> evaluate(WatcherContext ctx) async {
    final response = await ctx.apiClient.get(
      '/repos/${repoRef.owner}/${repoRef.name}/deployments/$deploymentId/statuses',
    );

    final statuses = extractListFromResponse<Object?>(response);
    if (statuses.isEmpty) {
      return const OneOffResult.pending();
    }

    final latestStatus = statuses.first as Map<String, dynamic>;
    final state = latestStatus['state'] as String?;

    // Terminal states
    if (state == 'success' || state == 'failure' || state == 'error') {
      final icon = switch (state) {
        'success' => '✅',
        'failure' || 'error' => '❌',
        _ => '🔵',
      };

      final stateLabel = switch (state) {
        'success' => 'Deployed successfully',
        'failure' => 'Deployment failed',
        'error' => 'Deployment error',
        _ => state ?? 'Unknown status',
      };

      return OneOffResult.completed(
        AlertPayload(
          id: 'deployment:${repoRef.owner}/${repoRef.name}:$deploymentId:${DateTime.now().millisecondsSinceEpoch}',
          title: '$icon ${environment ?? 'Deployment'} — $stateLabel',
          body: '${repoRef.owner}/${repoRef.name}',
          watcherKey: key,
          channels: const {
            AlertChannel.inAppToast,
            AlertChannel.systemNotification,
          },
          priority:
              state == 'failure' || state == 'error'
                  ? AlertPriority.high
                  : AlertPriority.normal,
          groupKey: 'deployments:${repoRef.owner}/${repoRef.name}',
          metadata: {'state': state ?? 'unknown', 'environment': environment ?? ''},
          entityRef: repoRef,
        ),
      );
    }

    // Still in progress
    return const OneOffResult.pending();
  }

  @override
  Map<String, dynamic> toJson() => {
        'key': key,
        'repoOwner': repoRef.owner,
        'repoName': repoRef.name,
        'deploymentId': deploymentId,
        'environment': environment,
        'interval': interval.inSeconds,
        'enabled': enabled,
      };

  static DeploymentStatusWatcher fromJson(Map<String, dynamic> json) =>
      DeploymentStatusWatcher(
        repoRef: RepoRef(
          owner: json['repoOwner'] as String,
          name: json['repoName'] as String,
        ),
        deploymentId: json['deploymentId'] as int,
        environment: json['environment'] as String?,
        interval: Duration(seconds: json['interval'] as int? ?? 300),
        enabled: json['enabled'] as bool? ?? true,
      );
}
