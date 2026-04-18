/// Recurring watcher that monitors an issue's open/closed state.
library;

import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/watchers/serializable_watcher.dart';
import 'package:diohub/services/watchers/watcher_definition.dart';
import 'package:diohub/services/watchers/watcher_types.dart';

class IssueStateWatcher extends PollingWatcher with SerializableWatcher {
  IssueStateWatcher({
    required this.issueRef,
    this.issueTitle,
    super.interval = const Duration(minutes: 15),
    super.enabled = true,
  });

  final IssueRef issueRef;
  final String? issueTitle;

  @override
  String get key => 'issue_state';
  @override
  String get instanceId =>
      '${issueRef.repo.owner}/${issueRef.repo.name}/${issueRef.number}';
  @override
  String get displayName =>
      'Issue #${issueRef.number} state in ${issueRef.repo.owner}/${issueRef.repo.name}';

  @override
  Future<List<AlertPayload>> fetchUpdates(
    WatcherContext ctx,
    DateTime? lastChecked,
  ) async {
    final response = await ctx.apiClient.get(
      '/repos/${issueRef.repo.owner}/${issueRef.repo.name}/issues/${issueRef.number}',
    );

    final issue = response.data as Map<String, dynamic>;
    final state = issue['state'] as String;
    final lastState = await ctx.read<String?>('_last_state');

    if (lastState == null) {
      await ctx.write('_last_state', state);
      return [];
    }

    if (state == lastState) {
      return [];
    }

    await ctx.write('_last_state', state);

    final icon = state == 'open' ? '🟢' : '🔴';
    final stateLabel = state == 'open' ? 'Reopened' : 'Closed';

    return [
      AlertPayload(
        id: 'issue_state:${issueRef.repo.owner}/${issueRef.repo.name}:${issueRef.number}:${DateTime.now().millisecondsSinceEpoch}',
        title: '$icon ${issueTitle ?? 'Issue #${issueRef.number}'} — $stateLabel',
        body: '${issueRef.repo.owner}/${issueRef.repo.name}',
        watcherKey: key,
        channels: const {
          AlertChannel.inAppToast,
          AlertChannel.systemNotification,
        },
        priority: AlertPriority.normal,
        groupKey: 'issues:${issueRef.repo.owner}/${issueRef.repo.name}',
        metadata: {'state': state},
        entityRef: issueRef,
      ),
    ];
  }

  @override
  Map<String, dynamic> toJson() => {
        'key': key,
        'repoOwner': issueRef.repo.owner,
        'repoName': issueRef.repo.name,
        'issueNumber': issueRef.number,
        'issueTitle': issueTitle,
        'interval': interval.inSeconds,
        'enabled': enabled,
      };

  static IssueStateWatcher fromJson(Map<String, dynamic> json) =>
      IssueStateWatcher(
        issueRef: IssueRef(
          repo: RepoRef(
            owner: json['repoOwner'] as String,
            name: json['repoName'] as String,
          ),
          number: json['issueNumber'] as int,
        ),
        issueTitle: json['issueTitle'] as String?,
        interval: Duration(seconds: json['interval'] as int? ?? 900),
        enabled: json['enabled'] as bool? ?? true,
      );
}
