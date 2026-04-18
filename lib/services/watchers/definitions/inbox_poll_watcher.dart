/// Watcher that polls the GitHub notification inbox and fires alerts for new items.
library;

import 'package:diohub_models/models/events/notifications_model.dart';
import 'package:diohub_models/models/server_config.dart';
import 'package:diohub/services/activity/notifications_service.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:diohub/services/watchers/definitions/thread_entity_ref.dart';
import 'package:diohub/services/watchers/serializable_watcher.dart';
import 'package:diohub/services/watchers/watcher_definition.dart';
import 'package:diohub/services/watchers/watcher_types.dart';

class InboxPollWatcher extends PollingWatcher with SerializableWatcher {
  InboxPollWatcher({
    super.interval = const Duration(minutes: 10),
    super.enabled = true,
  });

  @override
  String get key => 'inbox_poll';
  @override
  String get instanceId => 'default';
  @override
  String get displayName => 'GitHub notification inbox';

  @override
  Set<String> get requiredScopes => const {GitHubScope.notifications};

  @override
  Future<List<AlertPayload>> fetchUpdates(
    WatcherContext ctx,
    DateTime? lastChecked,
  ) async {
    // NotificationsService requires full ApiClient (gql + rest), so cast
    final notificationsService = NotificationsService(ctx.apiClient as ApiClient);
    
    final filters = <String, dynamic>{
      'all': false, // unread only
      if (lastChecked != null) 'since': lastChecked.toIso8601String(),
    };
    final threads = await notificationsService.getNotifications(
      perPage: 50,
      page: 1,
      filters: filters,
    );

    if (threads.isEmpty) return [];

    return threads.map((Thread thread) {
      final repoName = thread.repository.fullName;
      final subject = thread.subject;
      return AlertPayload(
        id: 'inbox:${thread.id}',
        title: subject.title,
        body: '${subject.type?.name ?? 'Activity'} in $repoName',
        watcherKey: key,
        channels: const {
          AlertChannel.inAppToast,
          AlertChannel.systemNotification,
        },
        priority: _priorityForReason(thread.reason),
        groupKey: 'inbox:$repoName',
        entityRef: entityRefFromThread(thread),
      );
    }).toList();
  }

  AlertPriority _priorityForReason(String? reason) => switch (reason) {
        'mention' || 'team_mention' || 'assign' => AlertPriority.high,
        'review_requested' => AlertPriority.high,
        'ci_activity' => AlertPriority.low,
        _ => AlertPriority.normal,
      };

  @override
  Map<String, dynamic> toJson() => {
        'key': key,
        'interval': interval.inSeconds,
        'enabled': enabled,
      };

  static InboxPollWatcher fromJson(Map<String, dynamic> json) =>
      InboxPollWatcher(
        interval: Duration(seconds: json['interval'] as int? ?? 600),
        enabled: json['enabled'] as bool? ?? true,
      );
}
