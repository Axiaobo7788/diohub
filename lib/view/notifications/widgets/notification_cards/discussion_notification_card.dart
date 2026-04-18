import 'package:diohub/common/cards/discussion_card.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/common/riverpod/async_value_builder.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/events/notifications_model.dart';
import 'package:diohub/models/events/thread_entity_ref_extension.dart';
import 'package:diohub/providers/repository/release_discussion_providers.dart';
import 'package:diohub/providers/notifications/notifications_service_provider.dart';
import 'package:diohub/providers/notifications/thread_subscription_provider.dart';
import 'package:diohub/providers/settings/card_display_provider.dart';
import 'package:diohub/view/notifications/widgets/notification_cards/notification_card_shared.dart';
import 'package:diohub/view/notifications/widgets/notification_cards/notification_priority_stripe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Discussion-type notification: shows loading skeleton then full discussion card after fetch.
///
/// Uses [discussionByNumberProvider] to fetch discussion details via GraphQL.
/// Fallback: if subject URL doesn't parse to a DiscussionRef, shows nothing.
class DiscussionNotificationCard extends ConsumerWidget {
  const DiscussionNotificationCard({
    required this.thread,
    this.onTap,
    super.key,
  });

  final Thread thread;
  final VoidCallback? onTap;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final DiscussionRef? discussionRef = thread.entityRef as DiscussionRef?;
    if (discussionRef == null) {
      return const SizedBox.shrink();
    }

    Future<void> onMarkRead() async =>
        ref.read(notificationsServiceProvider).markThreadAsRead(thread.id);
    final AsyncValue<DiscussionCardData?> asyncDiscussion =
        ref.watch(discussionByNumberProvider(discussionRef));
    final bool showPriorityStripe =
        ref.watch(cardDisplayProvider).showNotificationPriority;
    Widget wrapWithStripe(Widget card) => showPriorityStripe
        ? NotificationPriorityStripe(reason: thread.reason, child: card)
        : card;
    return AsyncValueBuilder<DiscussionCardData?>(
      value: asyncDiscussion,
      skeleton: (final _) => wrapWithStripe(buildNotificationCardShell(
        context: context,
        thread: thread,
        child: const ShimmerScope(
          child: DiscussionCardSkeleton(),
        ),
      )),
      data: (final DiscussionCardData? data) {
        if (data == null) {
          return const SizedBox.shrink();
        }
        final ColorScheme colorScheme = Theme.of(context).colorScheme;
        final Color borderColor = data.closed 
            ? colorScheme.onSurfaceVariant 
            : colorScheme.primary;
        return wrapWithStripe(buildNotificationCardShell(
          context: context,
          thread: thread,
          onTap: onTap,
          onMarkRead: onMarkRead,
          onSwipeMute: () => ref
              .read(threadSubscriptionProvider(thread.id).notifier)
              .toggleMute(),
          borderColor: borderColor,
          child: DiscussionCard(data, compact: true),
        ));
      },
    );
  }
}
