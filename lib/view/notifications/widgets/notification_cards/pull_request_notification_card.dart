import 'package:diohub/common/cards/issue_pull_card.dart';
import 'package:diohub/common/cards/card_data_state_color_extension.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/common/riverpod/async_value_builder.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';

import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/events/notifications_model.dart';
import 'package:diohub/models/events/thread_entity_ref_extension.dart';
import 'package:diohub/providers/issue_pulls/issue_providers.dart';
import 'package:diohub/providers/notifications/notifications_service_provider.dart';
import 'package:diohub/providers/notifications/thread_subscription_provider.dart';
import 'package:diohub/providers/settings/card_display_provider.dart';
import 'package:diohub/view/notifications/widgets/notification_cards/notification_card_shared.dart';
import 'package:diohub/view/notifications/widgets/notification_cards/notification_priority_stripe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// PR-type notification: shows loading skeleton then full PR card after fetch.
///
/// Uses [pullDetailProvider] so the same cache as the PR screen is used
/// and optimistic updates are visible. Fallback: if subject URL doesn't parse,
/// shows nothing.
class PullRequestNotificationCard extends ConsumerWidget {
  const PullRequestNotificationCard({
    required this.thread,
    this.onTap,
    super.key,
  });

  final Thread thread;
  final VoidCallback? onTap;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final PullRequestRef? prRef = thread.entityRef as PullRequestRef?;
    if (prRef == null) {
      return const SizedBox.shrink();
    }

    Future<void> onMarkRead() async =>
        ref.read(notificationsServiceProvider).markThreadAsRead(thread.id);
    final AsyncValue<PullInfo> asyncPr = ref.watch(pullDetailProvider(prRef));
    final bool showPriorityStripe =
        ref.watch(cardDisplayProvider).showNotificationPriority;
    Widget wrapWithStripe(Widget card) => showPriorityStripe
        ? NotificationPriorityStripe(reason: thread.reason, child: card)
        : card;
    return AsyncValueBuilder<PullInfo>(
      value: asyncPr,
      skeleton: (final _) => wrapWithStripe(buildNotificationCardShell(
        context: context,
        thread: thread,
        child: const ShimmerScope(
          child: IssuePullLoadingCard(),
        ),
      )),
      data: (final PullInfo data) {
        final PullCardData cardFields = data;
        return wrapWithStripe(buildNotificationCardShell(
          context: context,
          thread: thread,
          onTap: onTap,
          onMarkRead: () async => onMarkRead(),
          onSwipeMute: () => ref
              .read(threadSubscriptionProvider(thread.id).notifier)
              .toggleMute(),
          borderColor: cardFields.computeStateColor(),
          child: IssuePullCard.fromPullRequest(cardFields, compact: true),
        ));
      },
      error: (final _, final __) => wrapWithStripe(buildNotificationCardShell(
        context: context,
        thread: thread,
        onTap: onTap,
        onMarkRead: () async => onMarkRead(),
        onSwipeMute: () => ref
            .read(threadSubscriptionProvider(thread.id).notifier)
            .toggleMute(),
        child: Text(
          thread.subject.title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      )),
    );
  }
}
