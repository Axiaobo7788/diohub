/// Recurring watcher that monitors star count milestones for a repository.
library;

import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/watchers/serializable_watcher.dart';
import 'package:diohub/services/watchers/watcher_definition.dart';
import 'package:diohub/services/watchers/watcher_types.dart';

class StarCountWatcher extends PollingWatcher with SerializableWatcher {
  StarCountWatcher({
    required this.repoRef,
    super.interval = const Duration(hours: 12),
    super.enabled = true,
  });

  final RepoRef repoRef;

  @override
  String get key => 'star_count';
  @override
  String get instanceId => '${repoRef.owner}/${repoRef.name}';
  @override
  String get displayName =>
      'Star milestones for ${repoRef.owner}/${repoRef.name}';

  @override
  Future<List<AlertPayload>> fetchUpdates(
    WatcherContext ctx,
    DateTime? lastChecked,
  ) async {
    final response = await ctx.apiClient.get(
      '/repos/${repoRef.owner}/${repoRef.name}',
    );

    final repoData = response.data as Map<String, dynamic>;
    final starCount = repoData['stargazers_count'] as int? ?? 0;
    final lastCount = await ctx.read<int?>('_last_star_count') ?? 0;

    if (lastCount == 0) {
      await ctx.write('_last_star_count', starCount);
      return [];
    }

    await ctx.write('_last_star_count', starCount);

    final milestones = [10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000, 25000, 50000, 100000];
    final crossedMilestones = milestones.where((m) => lastCount < m && starCount >= m).toList();

    if (crossedMilestones.isEmpty) return [];

    return crossedMilestones.map((milestone) {
      return AlertPayload(
        id: 'star_milestone:${repoRef.owner}/${repoRef.name}:$milestone',
        title: '⭐ $milestone stars reached!',
        body: '${repoRef.owner}/${repoRef.name}',
        watcherKey: key,
        channels: const {
          AlertChannel.inAppToast,
          AlertChannel.systemNotification,
        },
        priority: AlertPriority.normal,
        groupKey: 'social:${repoRef.owner}/${repoRef.name}',
        metadata: {
          'milestone': milestone.toString(),
          'star_count': starCount.toString(),
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
        'interval': interval.inSeconds,
        'enabled': enabled,
      };

  static StarCountWatcher fromJson(Map<String, dynamic> json) =>
      StarCountWatcher(
        repoRef: RepoRef(
          owner: json['repoOwner'] as String,
          name: json['repoName'] as String,
        ),
        interval: Duration(seconds: json['interval'] as int? ?? 43200),
        enabled: json['enabled'] as bool? ?? true,
      );
}
