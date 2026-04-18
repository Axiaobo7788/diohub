/// Recurring watcher that notifies when new releases are published in a repository.
library;

import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/base/rest_pagination_helper.dart';
import 'package:diohub/services/watchers/serializable_watcher.dart';
import 'package:diohub/services/watchers/watcher_definition.dart';
import 'package:diohub/services/watchers/watcher_types.dart';

class ReleaseWatcher extends PollingWatcher with SerializableWatcher {
  ReleaseWatcher({
    required this.repoRef,
    super.interval = const Duration(hours: 2),
    super.enabled = true,
  });

  final RepoRef repoRef;

  @override
  String get key => 'release';
  @override
  String get instanceId => '${repoRef.owner}/${repoRef.name}';
  @override
  String get displayName =>
      'New releases in ${repoRef.owner}/${repoRef.name}';

  @override
  Future<List<AlertPayload>> fetchUpdates(
    WatcherContext ctx,
    DateTime? lastChecked,
  ) async {
    final response = await ctx.apiClient.get(
      '/repos/${repoRef.owner}/${repoRef.name}/releases',
      queryParameters: {'per_page': 10},
    );

    final releases = extractListFromResponse<Object?>(response);
    if (releases.isEmpty) return [];

    final lastSeenTag = await ctx.read<String?>('_last_release_tag');

    if (lastSeenTag == null) {
      final latestRelease = releases.first as Map<String, dynamic>;
      final latestTag = latestRelease['tag_name'] as String;
      await ctx.write('_last_release_tag', latestTag);
      return [];
    }

    final newReleases = <Map<String, dynamic>>[];
    for (final release in releases) {
      final releaseMap = release as Map<String, dynamic>;
      if (releaseMap['tag_name'] == lastSeenTag) break;
      newReleases.add(releaseMap);
    }

    if (newReleases.isEmpty) return [];

    await ctx.write('_last_release_tag', newReleases.first['tag_name']);

    return newReleases.map((release) {
      final isPrerelease = release['prerelease'] == true;
      final isDraft = release['draft'] == true;
      final icon = isPrerelease ? '🔖' : isDraft ? '📝' : '🎉';
      final tagName = release['tag_name'] as String? ?? '';
      final name = release['name'] as String?;

      return AlertPayload(
        id: 'release:${repoRef.owner}/${repoRef.name}:$tagName',
        title: '$icon ${tagName.isNotEmpty ? tagName : name ?? 'New release'}',
        body: '${repoRef.owner}/${repoRef.name}${isPrerelease ? ' (pre-release)' : ''}',
        watcherKey: key,
        channels: const {
          AlertChannel.inAppToast,
          AlertChannel.systemNotification,
        },
        priority: AlertPriority.normal,
        groupKey: 'releases:${repoRef.owner}/${repoRef.name}',
        metadata: {
          'tag': tagName,
          'prerelease': isPrerelease.toString(),
        },
        entityRef: ReleaseRef(
          repo: repoRef,
          tagName: tagName,
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

  static ReleaseWatcher fromJson(Map<String, dynamic> json) => ReleaseWatcher(
        repoRef: RepoRef(
          owner: json['repoOwner'] as String,
          name: json['repoName'] as String,
        ),
        interval: Duration(seconds: json['interval'] as int? ?? 7200),
        enabled: json['enabled'] as bool? ?? true,
      );
}
