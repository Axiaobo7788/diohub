import 'package:diohub/common/cards/issue_pull_card.dart'
    show IssuePullLoadingCard;
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub_models/models/events/notifications_model.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/view/notifications/widgets/notification_cards/notification_reason_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Flattened shell for notification cards: single [BorderedContainer] surface with reason row inside.
///
/// [onTap] may be null for loading state; when non-null, tap calls [onMarkRead] then [onTap].
/// [onMarkRead] is provided by the caller (e.g. from [markThreadAsReadProvider] or [notificationsServiceProvider]).
/// When [onSwipeMute] is non-null, swipe right reveals a mute action (card stays in list).
/// [borderColor] is passed to [BorderedContainer] to indicate entity state (e.g. issue/PR color).
Widget buildNotificationCardShell({
  required final BuildContext context,
  required final Thread thread,
  required final Widget child,
  final VoidCallback? onTap,
  final Future<void> Function()? onMarkRead,
  final VoidCallback? onSwipeMute,
  final Color? borderColor,
}) {
  final AppSpacing spacing = context.spacing;
  final ColorScheme colorScheme = Theme.of(context).colorScheme;
  final Widget content = BorderedContainer(
    borderColor: borderColor,
    onTap: onTap == null
        ? null
        : () async {
            if (onMarkRead != null) await onMarkRead();
            if (context.mounted) {
              onTap();
            }
          },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        buildNotificationReasonAndTimeRow(context, thread),
        SizedBox(height: spacing.compactSpacing),
        child,
      ],
    ),
  );
  if (onSwipeMute == null) {
    return content;
  }
  return Dismissible(
    key: ValueKey<String>('notif-${thread.id}'),
    direction: DismissDirection.startToEnd,
    confirmDismiss: (final DismissDirection _) async {
      onSwipeMute();
      return false;
    },
    background: Container(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(
        left: context.spacing.spaciousPadding.left,
        right: context.spacing.spaciousPadding.right,
        top: 0,
        bottom: 0,
      ),
      child: Icon(
        Icons.notifications_off_rounded,
        color: colorScheme.onSurfaceVariant,
      ),
    ),
    child: content,
  );
}

/// Default loading placeholder for notification cards that don't use [IssuePullLoadingCard].
///
/// Uses [context.spacing.cardContentPadding] via [BorderedContainer] default.
/// Show inside [ShimmerScope] + [BorderedContainer] when using as loading child.
class NotificationCardLoadingPlaceholder extends StatelessWidget {
  const NotificationCardLoadingPlaceholder({
    this.icon = Octicons.tag,
    super.key,
  });

  final IconData icon;

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    final Color color = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: color),
        SizedBox(width: spacing.itemSpacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                height: 14,
                width: 80,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: spacing.itemSpacing / 2),
              Container(
                height: 12,
                width: 160,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Builds the standard loading state for a deferred notification card:
/// [buildNotificationCardShell] with [ShimmerScope] + [BorderedContainer] + [NotificationCardLoadingPlaceholder].
Widget buildDeferredNotificationLoadingShell({
  required final BuildContext context,
  required final Thread thread,
  final IconData icon = Octicons.tag,
}) =>
    buildNotificationCardShell(
      context: context,
      thread: thread,
      child: ShimmerScope(
        child: NotificationCardLoadingPlaceholder(icon: icon),
      ),
    );
