/// Context-free notification service, callable from Riverpod notifiers
/// via `ref.read(notificationServiceProvider)`.
///
/// Uses `toastification.showCustom()` for full design control over the
/// toast widget (rendered by [NotificationCard]).
library;

import 'package:diohub/common/notifications/app_notification.dart';
import 'package:diohub/common/notifications/notification_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';

final Provider<NotificationService> notificationServiceProvider =
    Provider<NotificationService>((final Ref ref) => NotificationService());

class NotificationService {
  /// Show an arbitrary [AppNotification].
  ToastificationItem show(final AppNotification notification) =>
      toastification.showCustom(
        autoCloseDuration: notification.duration,
        alignment: Alignment.bottomCenter,
        animationDuration: const Duration(milliseconds: 300),
        builder: (final BuildContext context, final ToastificationItem item) =>
            NotificationCard(
          notification: notification,
          item: item,
        ),
      );

  /// Convenience: show a brief success toast.
  ToastificationItem success(
    final String message, {
    final IconData? icon,
    final VoidCallback? onTap,
  }) =>
      show(
        SuccessNotification(
          message: message,
          icon: icon ?? Icons.check_circle_outline_rounded,
          onTap: onTap,
        ),
      );

  /// Convenience: show an error toast with optional retry.
  ToastificationItem error(
    final String message, {
    final VoidCallback? retryAction,
  }) =>
      show(
        ErrorNotification(
          message: message,
          retryAction: retryAction,
        ),
      );

  /// Convenience: show a destructive-action undo toast.
  ToastificationItem undo(
    final String message, {
    required final VoidCallback onUndo,
  }) =>
      show(
        UndoNotification(
          message: message,
          onUndo: onUndo,
        ),
      );

  /// Convenience: show a long-running progress toast.
  ToastificationItem progress(
    final String message, {
    final double? progress,
  }) =>
      show(
        ProgressNotification(
          message: message,
          progress: progress,
        ),
      );

  /// Dismiss a specific toast.
  void dismiss(final ToastificationItem item) {
    toastification.dismiss(item);
  }

  /// Dismiss all active toasts.
  void dismissAll() {
    toastification.dismissAll();
  }
}
