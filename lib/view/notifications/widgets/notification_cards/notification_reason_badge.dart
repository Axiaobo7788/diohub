import 'package:diohub_models/models/events/notifications_model.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/notifications/widgets/notification_cards/basic_notification_card.dart'
    show BasicNotificationCard;
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Shared colored badge showing the notification reason with context-aware icon and label.
/// Used by issue/PR notification cards and [BasicNotificationCard].
class NotificationReasonBadge extends StatelessWidget {
  const NotificationReasonBadge({required this.reason, super.key});

  final String reason;

  static String label(final String reason) => switch (reason) {
        'assign' => 'Assigned',
        'author' => 'Author',
        'comment' => 'Comment',
        'ci_activity' => 'CI',
        'invitation' => 'Invitation',
        'manual' => 'Subscribed',
        'mention' => '@mention',
        'review_requested' => 'Review requested',
        'security_alert' => 'Security',
        'state_change' => 'State change',
        'subscribed' => 'Subscribed',
        'team_mention' => '@team',
        _ => reason,
      };

  /// Context-aware icon for the reason (null = no icon).
  static IconData? icon(final String reason) => switch (reason) {
        'mention' || 'team_mention' => Icons.alternate_email,
        'review_requested' => Octicons.person,
        'assign' => Octicons.person_add,
        'subscribed' || 'manual' => Octicons.bell,
        'comment' => Octicons.comment,
        'state_change' => Octicons.git_merge,
        'ci_activity' => Octicons.check_circle,
        'security_alert' => Octicons.alert,
        'invitation' => Octicons.mail,
        'author' => Octicons.pencil,
        _ => null,
      };

  static Color color(final String reason, final BuildContext context) =>
      switch (reason) {
        'mention' || 'team_mention' => Colors.blue,
        'review_requested' => Colors.orange,
        'assign' => Colors.teal,
        'security_alert' => Colors.red,
        'state_change' => Colors.purple,
        'ci_activity' => Colors.amber,
        _ => Theme.of(context).colorScheme.onSurfaceVariant,
      };

  @override
  Widget build(final BuildContext context) {
    final String badgeLabel = label(reason);
    final Color badgeColor = color(reason, context);
    final IconData? reasonIcon = icon(reason);
    final double iconSize = 12;

    return Container(
      padding: context.spacing.badgePadding,
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (reasonIcon != null) ...[
            Icon(
              reasonIcon,
              size: iconSize,
              color: badgeColor,
            ),
            SizedBox(width: context.spacing.tightSpacing),
          ],
          Text(
            badgeLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

/// Row with reason badge and thread.updatedAt for issue/PR notification cards.
Widget buildNotificationReasonAndTimeRow(
    final BuildContext context, final Thread thread) {
  final ThemeData theme = Theme.of(context);
  final ColorScheme colorScheme = context.colorScheme;
  final String timeText =
      thread.updatedAt != null ? thread.updatedAt!.toRelativeDate() : '';
  return Row(
    children: <Widget>[
      NotificationReasonBadge(reason: thread.reason),
      context.spacing.itemGap,
      if (timeText.isNotEmpty)
        Text(
          timeText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
    ],
  );
}
