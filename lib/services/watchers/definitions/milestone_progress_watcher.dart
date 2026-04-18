/// Recurring watcher that monitors milestone progress toward completion.
library;

import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/watchers/serializable_watcher.dart';
import 'package:diohub/services/watchers/watcher_definition.dart';
import 'package:diohub/services/watchers/watcher_types.dart';

class MilestoneProgressWatcher extends PollingWatcher with SerializableWatcher {
  MilestoneProgressWatcher({
    required this.repoRef,
    required this.milestoneNumber,
    this.milestoneTitle,
    super.interval = const Duration(hours: 6),
    super.enabled = true,
  });

  final RepoRef repoRef;
  final int milestoneNumber;
  final String? milestoneTitle;

  @override
  String get key => 'milestone_progress';
  @override
  String get instanceId =>
      '${repoRef.owner}/${repoRef.name}/$milestoneNumber';
  @override
  String get displayName =>
      'Milestone ${milestoneTitle ?? '#$milestoneNumber'} in ${repoRef.owner}/${repoRef.name}';

  @override
  Future<List<AlertPayload>> fetchUpdates(
    WatcherContext ctx,
    DateTime? lastChecked,
  ) async {
    final response = await ctx.apiClient.get(
      '/repos/${repoRef.owner}/${repoRef.name}/milestones/$milestoneNumber',
    );

    final milestone = response.data as Map<String, dynamic>;
    final openIssues = milestone['open_issues'] as int? ?? 0;
    final closedIssues = milestone['closed_issues'] as int? ?? 0;
    final total = openIssues + closedIssues;

    if (total == 0) return [];

    final completionPercentage = ((closedIssues / total) * 100).round();
    final lastPercentage = await ctx.read<int?>('_last_completion_percentage');

    if (lastPercentage == null) {
      await ctx.write('_last_completion_percentage', completionPercentage);
      return [];
    }

    await ctx.write('_last_completion_percentage', completionPercentage);

    final thresholds = [25, 50, 75, 90, 100];
    final crossedThresholds = thresholds
        .where((t) => lastPercentage < t && completionPercentage >= t)
        .toList();

    if (crossedThresholds.isEmpty) return [];

    return crossedThresholds.map((threshold) {
      final icon = threshold == 100 ? '🎉' : '📊';
      final message = threshold == 100
          ? 'Completed!'
          : '$threshold% complete';

      return AlertPayload(
        id: 'milestone:${repoRef.owner}/${repoRef.name}:$milestoneNumber:$threshold',
        title: '$icon ${milestoneTitle ?? 'Milestone #$milestoneNumber'} — $message',
        body: '${repoRef.owner}/${repoRef.name} ($closedIssues/$total issues closed)',
        watcherKey: key,
        channels: const {
          AlertChannel.inAppToast,
          AlertChannel.systemNotification,
        },
        priority: threshold == 100 ? AlertPriority.high : AlertPriority.normal,
        groupKey: 'social:${repoRef.owner}/${repoRef.name}',
        metadata: {
          'milestone': milestoneNumber.toString(),
          'percentage': completionPercentage.toString(),
        },
        entityRef: repoRef,
      );
    }).toList();
  }

  @override
  Map<String, dynamic> toJson() => {
        'key': key,
        'repoOwner': repoRef.owner,
        'repoName': repoRef.name,
        'milestoneNumber': milestoneNumber,
        'milestoneTitle': milestoneTitle,
        'interval': interval.inSeconds,
        'enabled': enabled,
      };

  static MilestoneProgressWatcher fromJson(Map<String, dynamic> json) =>
      MilestoneProgressWatcher(
        repoRef: RepoRef(
          owner: json['repoOwner'] as String,
          name: json['repoName'] as String,
        ),
        milestoneNumber: json['milestoneNumber'] as int,
        milestoneTitle: json['milestoneTitle'] as String?,
        interval: Duration(seconds: json['interval'] as int? ?? 21600),
        enabled: json['enabled'] as bool? ?? true,
      );
}
