/// Recurring watcher that monitors a pull request's merge status (mergeable state).
library;

import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/watchers/serializable_watcher.dart';
import 'package:diohub/services/watchers/watcher_definition.dart';
import 'package:diohub/services/watchers/watcher_types.dart';

class PRMergeStatusWatcher extends PollingWatcher with SerializableWatcher {
  PRMergeStatusWatcher({
    required this.prRef,
    this.prTitle,
    super.interval = const Duration(minutes: 15),
    super.enabled = true,
  });

  final PullRequestRef prRef;
  final String? prTitle;

  @override
  String get key => 'pr_merge_status';
  @override
  String get instanceId =>
      '${prRef.repo.owner}/${prRef.repo.name}/${prRef.number}';
  @override
  String get displayName =>
      'PR #${prRef.number} merge status in ${prRef.repo.owner}/${prRef.repo.name}';

  @override
  Future<List<AlertPayload>> fetchUpdates(
    WatcherContext ctx,
    DateTime? lastChecked,
  ) async {
    final response = await ctx.apiClient.get(
      '/repos/${prRef.repo.owner}/${prRef.repo.name}/pulls/${prRef.number}',
    );

    final pr = response.data as Map<String, dynamic>;
    final mergeableState = pr['mergeable_state'] as String?;
    final lastState = await ctx.read<String?>('_last_mergeable_state');

    if (lastState == null) {
      await ctx.write('_last_mergeable_state', mergeableState ?? 'unknown');
      return [];
    }

    if (mergeableState == lastState) {
      return [];
    }

    await ctx.write('_last_mergeable_state', mergeableState ?? 'unknown');

    final icon = switch (mergeableState) {
      'clean' => '✅',
      'unstable' || 'has_hooks' => '⚠️',
      'blocked' || 'behind' || 'dirty' => '❌',
      _ => '🔵',
    };

    final stateLabel = switch (mergeableState) {
      'clean' => 'Ready to merge',
      'unstable' => 'Checks failing',
      'has_hooks' => 'Checks pending',
      'blocked' => 'Merge blocked',
      'behind' => 'Behind base branch',
      'dirty' => 'Conflicts present',
      _ => mergeableState ?? 'Unknown status',
    };

    return [
      AlertPayload(
        id: 'pr_merge:${prRef.repo.owner}/${prRef.repo.name}:${prRef.number}:${DateTime.now().millisecondsSinceEpoch}',
        title: '$icon ${prTitle ?? 'PR #${prRef.number}'} — $stateLabel',
        body: '${prRef.repo.owner}/${prRef.repo.name}',
        watcherKey: key,
        channels: const {
          AlertChannel.inAppToast,
          AlertChannel.systemNotification,
        },
        priority: mergeableState == 'clean'
            ? AlertPriority.high
            : AlertPriority.normal,
        groupKey: 'prs:${prRef.repo.owner}/${prRef.repo.name}',
        metadata: {'mergeable_state': mergeableState ?? 'unknown'},
        entityRef: prRef,
      ),
    ];
  }

  @override
  Map<String, dynamic> toJson() => {
        'key': key,
        'repoOwner': prRef.repo.owner,
        'repoName': prRef.repo.name,
        'prNumber': prRef.number,
        'prTitle': prTitle,
        'interval': interval.inSeconds,
        'enabled': enabled,
      };

  static PRMergeStatusWatcher fromJson(Map<String, dynamic> json) =>
      PRMergeStatusWatcher(
        prRef: PullRequestRef(
          repo: RepoRef(
            owner: json['repoOwner'] as String,
            name: json['repoName'] as String,
          ),
          number: json['prNumber'] as int,
        ),
        prTitle: json['prTitle'] as String?,
        interval: Duration(seconds: json['interval'] as int? ?? 900),
        enabled: json['enabled'] as bool? ?? true,
      );
}
