import 'package:diohub/common/riverpod/async_value_builder.dart';
import 'package:diohub/providers/notifications/notification_subject_provider.dart';
import 'package:diohub/providers/notifications/notifications_service_provider.dart';
import 'package:diohub_models/models/events/check_suite_notification_dto.dart';
import 'package:diohub_models/models/events/notifications_model.dart';
import 'package:diohub/providers/notifications/thread_subscription_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/providers/settings/card_display_provider.dart';
import 'package:diohub/view/notifications/widgets/notification_cards/notification_card_shared.dart';
import 'package:diohub/view/notifications/widgets/notification_cards/notification_priority_stripe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// CheckSuite-type notification: deferred fetch of check suite by [Thread.subject.url],
/// then conclusion badge, status text, and app name.
///
/// Uses [buildNotificationCardShell] and [buildDeferredNotificationLoadingShell].
class CheckSuiteNotificationCard extends ConsumerWidget {
  const CheckSuiteNotificationCard({
    required this.thread,
    this.onTap,
    super.key,
  });

  final Thread thread;
  final VoidCallback? onTap;

  static Color _conclusionColor(
      final BuildContext context, final String? conclusion) {
    switch (conclusion?.toLowerCase()) {
      case 'success':
        return const Color(0xFF2DA44E);
      case 'failure':
        return const Color(0xFFCF222E);
      case 'cancelled':
        return Theme.of(context).colorScheme.onSurfaceVariant;
      case 'neutral':
      case 'skipped':
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

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
    // : 'chezzckSuiteNotif',
      skeleton: (_) => wrapWithStripe(buildDeferredNotificationLoadingShell(
        context: context,
        thread: thread,
        icon: Octicons.check_circle,
      )),
      data: (final Map<String, dynamic> data) {
        final CheckSuiteNotificationDto dto =
            CheckSuiteNotificationDto.fromJson(
          Map<String, dynamic>.from(data),
        );
        final AppSpacing spacing = context.spacing;
        final String? conclusion = dto.conclusion;
        final String label = conclusion ?? dto.status ?? 'Check';
        final Color color = _conclusionColor(context, conclusion);
        final Column contentColumn = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: context.spacing.badgePadding,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: color.withValues(alpha: 0.5),
                    ),
                    borderRadius: context.radius(
                      RadiusSize.small,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        conclusion == 'success'
                            ? Octicons.check_circle_fill
                            : conclusion == 'failure'
                                ? Octicons.x_circle_fill
                                : Octicons.check_circle,
                        size: 12,
                        color: color,
                      ),
                      SizedBox(width: context.spacing.badgePadding.left),
                      Text(
                        label.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                if (dto.appName != null && dto.appName!.isNotEmpty) ...<Widget>[
                  SizedBox(width: spacing.itemSpacing),
                  Expanded(
                    child: Text(
                      dto.appName!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        );

        return wrapWithStripe(buildNotificationCardShell(
          context: context,
          thread: thread,
          onTap: onTap,
          onMarkRead: () async => onMarkRead(),
          onSwipeMute: () => ref
              .read(threadSubscriptionProvider(thread.id).notifier)
              .toggleMute(),
          borderColor: color,
          child: contentColumn,
        ));
      },
    );
  }
}
