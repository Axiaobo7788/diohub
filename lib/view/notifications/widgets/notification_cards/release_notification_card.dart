import 'package:diohub/common/cards/release_card.dart';
import 'package:diohub/common/riverpod/async_value_builder.dart';
import 'package:diohub/providers/notifications/notification_subject_provider.dart';
import 'package:diohub/providers/notifications/notifications_service_provider.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/events/event_release.dart';
import 'package:diohub_models/models/events/notifications_model.dart';
import 'package:diohub/providers/notifications/thread_subscription_provider.dart';
import 'package:diohub/providers/settings/card_display_provider.dart';
import 'package:diohub/view/notifications/widgets/notification_cards/notification_card_shared.dart';
import 'package:diohub/view/notifications/widgets/notification_cards/notification_priority_stripe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Release-type notification: deferred fetch of release by [Thread.subject.url],
/// then renders the full [ReleaseCard] (like events feed).
///
/// First fetches REST data to get the tag name, then uses [ReleaseCardLoading]
/// to fetch the full GraphQL release data and display the rich card.
class ReleaseNotificationCard extends ConsumerWidget {
  const ReleaseNotificationCard({
    required this.thread,
    this.onTap,
    super.key,
  });

  final Thread thread;
  final VoidCallback? onTap;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final String? subjectUrl = thread.subject.url;
    if (subjectUrl == null || subjectUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    Future<void> onMarkRead() async =>
        ref.read(notificationsServiceProvider).markThreadAsRead(thread.id);
    final subjectAsync = ref.watch(notificationSubjectProvider(subjectUrl));
    final bool showPriorityStripe =
        ref.watch(cardDisplayProvider).showNotificationPriority;
    Widget wrapWithStripe(Widget card) => showPriorityStripe
        ? NotificationPriorityStripe(reason: thread.reason, child: card)
        : card;
    return AsyncValueBuilder<Map<String, dynamic>>(
      value: subjectAsync,
      skeleton: (_) => wrapWithStripe(buildDeferredNotificationLoadingShell(
        context: context,
        thread: thread,
      )),
      data: (final Map<String, dynamic> data) {
        final EventRelease release =
            EventRelease.fromJson(Map<String, dynamic>.from(data));
        final String? tagName = release.tagName ?? release.name;
        if (tagName == null) {
          return const SizedBox.shrink();
        }
        final RepoRef repoRef = RepoRef.fromFullName(thread.repository.fullName);
        return wrapWithStripe(buildNotificationCardShell(
          context: context,
          thread: thread,
          onTap: onTap,
          onMarkRead: () async => onMarkRead(),
          onSwipeMute: () => ref
              .read(threadSubscriptionProvider(thread.id).notifier)
              .toggleMute(),
          child: ReleaseCardLoading(
            repoRef: repoRef,
            tagName: tagName,
          ),
        ));
      },
    );
  }
}
