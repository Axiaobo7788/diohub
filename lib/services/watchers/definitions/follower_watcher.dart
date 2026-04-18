/// Recurring watcher that monitors for new followers.
library;

import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/base/rest_pagination_helper.dart';
import 'package:diohub/services/watchers/serializable_watcher.dart';
import 'package:diohub/services/watchers/watcher_definition.dart';
import 'package:diohub/services/watchers/watcher_types.dart';

class FollowerWatcher extends PollingWatcher with SerializableWatcher {
  FollowerWatcher({
    required this.username,
    super.interval = const Duration(hours: 6),
    super.enabled = true,
  });

  final String username;

  @override
  String get key => 'follower';
  @override
  String get instanceId => username;
  @override
  String get displayName => 'New followers for @$username';

  @override
  Future<List<AlertPayload>> fetchUpdates(
    WatcherContext ctx,
    DateTime? lastChecked,
  ) async {
    final response = await ctx.apiClient.get(
      '/users/$username/followers',
      queryParameters: {
        'per_page': 30,
      },
    );

    final followers = extractListFromResponse<Object?>(response);
    if (followers.isEmpty) return [];

    final lastSeenLogins = await ctx.read<List<dynamic>?>('_last_follower_logins') ?? [];
    final lastSeenSet = lastSeenLogins.cast<String>().toSet();

    // Seed run: store current followers and don't alert
    if (lastSeenLogins.isEmpty) {
      final currentLogins = followers
          .take(30)
          .map((f) => (f as Map<String, dynamic>)['login'] as String)
          .toList();
      await ctx.write('_last_follower_logins', currentLogins);
      return [];
    }

    final newFollowers = followers.where((follower) {
      final followerMap = follower as Map<String, dynamic>;
      final login = followerMap['login'] as String;
      return !lastSeenSet.contains(login);
    }).take(5).toList(); // Limit to 5 most recent

    if (newFollowers.isEmpty) return [];

    final currentLogins = followers
        .take(30)
        .map((f) => (f as Map<String, dynamic>)['login'] as String)
        .toList();
    await ctx.write('_last_follower_logins', currentLogins);

    return newFollowers.map((follower) {
      final followerMap = follower as Map<String, dynamic>;
      final login = followerMap['login'] as String;
      final avatarUrl = followerMap['avatar_url'] as String?;

      return AlertPayload(
        id: 'follower:$username:$login',
        title: '👤 @$login started following you',
        body: '',
        watcherKey: key,
        channels: const {
          AlertChannel.inAppToast,
          AlertChannel.systemNotification,
        },
        priority: AlertPriority.low,
        groupKey: 'social:followers',
        metadata: {
          'follower': login,
          'avatar': avatarUrl ?? '',
        },
        entityRef: UserRef(login: login),
      );
    }).toList();
  }

  @override
  Map<String, dynamic> toJson() => {
        'key': key,
        'username': username,
        'interval': interval.inSeconds,
        'enabled': enabled,
      };

  static FollowerWatcher fromJson(Map<String, dynamic> json) =>
      FollowerWatcher(
        username: json['username'] as String,
        interval: Duration(seconds: json['interval'] as int? ?? 21600),
        enabled: json['enabled'] as bool? ?? true,
      );
}
