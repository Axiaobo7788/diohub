import 'package:diohub/common/cards/commit_card.dart';
import 'package:diohub/common/riverpod/async_value_builder.dart';
import 'package:diohub/providers/notifications/notification_subject_provider.dart';
import 'package:diohub/providers/notifications/notifications_service_provider.dart';
import 'package:diohub/models/commits/commit_list_item_model.dart';
import 'package:diohub_models/models/commits/commit_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/events/notifications_model.dart';
import 'package:diohub/models/events/thread_entity_ref_extension.dart';
import 'package:diohub/providers/notifications/thread_subscription_provider.dart';
import 'package:diohub/providers/settings/card_display_provider.dart';
import 'package:diohub/view/notifications/widgets/notification_cards/notification_card_shared.dart';
import 'package:diohub/view/notifications/widgets/notification_cards/notification_priority_stripe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Commit-type notification: deferred fetch of commit by [Thread.subject.url],
/// then type-specific content with repo and [CommitCard] layout.
///
/// Uses [buildNotificationCardShell] and [buildDeferredNotificationLoadingShell].
/// Tap is handled by the shell (mark read + notification onTap); commit navigation
/// is handled by the shared notification navigation boundary.
class CommitNotificationCard extends ConsumerWidget {
  const CommitNotificationCard({required this.thread, this.onTap, super.key});

  final Thread thread;
  final VoidCallback? onTap;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final CommitRef? commitRef = thread.entityRef as CommitRef?;
    final String? subjectUrl = thread.subject.url;
    if (commitRef == null || subjectUrl == null || subjectUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    Future<void> onMarkRead() async =>
        ref.read(notificationsServiceProvider).markThreadAsRead(thread.id);
    final subjectAsync = ref.watch(notificationSubjectProvider(subjectUrl));
    final bool showPriorityStripe = ref
        .watch(cardDisplayProvider)
        .showNotificationPriority;
    Widget wrapWithStripe(Widget card) => showPriorityStripe
        ? NotificationPriorityStripe(reason: thread.reason, child: card)
        : card;
    return AsyncValueBuilder<Map<String, dynamic>>(
      value: subjectAsync,
      skeleton: (_) => wrapWithStripe(
        buildDeferredNotificationLoadingShell(
          context: context,
          thread: thread,
          icon: Octicons.git_commit,
        ),
      ),
      data: (final Map<String, dynamic> data) {
        final Commit commit = Commit.fromJson(Map<String, dynamic>.from(data));
        final RepoRef repo = RepoRef.fromFullName(thread.repository.fullName);
        final CommitListItemModel model = CommitListItemModel.fromCommit(
          commit,
          repo,
        );
        return wrapWithStripe(
          buildNotificationCardShell(
            context: context,
            thread: thread,
            onTap: onTap,
            onMarkRead: onMarkRead,
            onSwipeMute: () => ref
                .read(threadSubscriptionProvider(thread.id).notifier)
                .toggleMute(),
            child: CommitCard(data: model, compact: true),
          ),
        );
      },
    );
  }
}
