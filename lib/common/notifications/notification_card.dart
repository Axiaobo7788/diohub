/// Custom toast widget rendered by [NotificationService] via toastification.
///
/// Uses the app's surface/glass design system (`context.radius()`,
/// `context.colorScheme`) and pattern matches on [AppNotification] subtypes
/// to render type-specific action buttons.
library;

import 'package:diohub/common/notifications/app_notification.dart';
import 'package:diohub/common/notifications/notification_service.dart'
    show NotificationService;
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    required this.notification,
    required this.item,
    super.key,
  });

  final AppNotification notification;
  final ToastificationItem item;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppSpacing spacing = context.spacing;
    final (Color bgColor, Color accentColor) = _colorsFor(colorScheme);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        spacing.screenPadding.left,
        spacing.cardContentPadding.top,
        spacing.screenPadding.right,
        spacing.cardContentPadding.bottom,
      ),
      child: Material(
        color: bgColor,
        borderRadius: context.radius(RadiusSize.large),
        elevation: 6,
        shadowColor: Colors.black26,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            spacing.screenPadding.left,
            spacing.contentPadding.top,
            spacing.screenPadding.right,
            spacing.contentPadding.bottom,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Icon
              if (notification.icon != null) ...<Widget>[
                _buildIcon(accentColor),
                context.spacing.contentGap,
              ],
              // Message
              Flexible(
                child: Text(
                  notification.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Action button (type-specific)
              ..._buildActions(context, accentColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(final Color accentColor) => switch (notification) {
        ProgressNotification(:final double? progress) => progress != null
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2,
                  color: accentColor,
                ),
              )
            : SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accentColor,
                ),
              ),
        _ => Icon(
            notification.icon,
            size: 20,
            color: accentColor,
          ),
      };

  List<Widget> _buildActions(
          final BuildContext context, final Color accentColor) =>
      switch (notification) {
        SuccessNotification(:final VoidCallback? onTap) when onTap != null =>
          <Widget>[
            context.spacing.itemGap,
            _ActionButton(
              label: 'Open',
              color: accentColor,
              onTap: () {
                toastification.dismiss(item);
                onTap();
              },
            ),
          ],
        ErrorNotification(:final VoidCallback? retryAction)
            when retryAction != null =>
          <Widget>[
            context.spacing.itemGap,
            _ActionButton(
              label: 'Retry',
              color: accentColor,
              onTap: () {
                toastification.dismiss(item);
                retryAction();
              },
            ),
          ],
        UndoNotification(:final VoidCallback onUndo) => <Widget>[
            context.spacing.itemGap,
            _ActionButton(
              label: 'Undo',
              color: accentColor,
              onTap: () {
                toastification.dismiss(item);
                onUndo();
              },
            ),
          ],
        _ => const <Widget>[],
      };

  (Color bg, Color accent) _colorsFor(final ColorScheme scheme) =>
      switch (notification) {
        SuccessNotification() => (
            scheme.surfaceContainerHigh,
            Colors.green.shade400,
          ),
        ErrorNotification() => (
            scheme.errorContainer,
            scheme.error,
          ),
        UndoNotification() => (
            scheme.surfaceContainerHigh,
            scheme.primary,
          ),
        ProgressNotification() => (
            scheme.surfaceContainerHigh,
            scheme.primary,
          ),
      };
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) => TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        child: Text(label),
      );
}
