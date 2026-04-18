/// Concrete [AlertSink] implementation that bridges the service layer to UI.
library;

import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/services/watchers/background_watcher_service.dart';
import 'package:diohub/services/watchers/watcher_types.dart';
import 'package:flutter/material.dart';

/// Concrete implementation of [AlertSink] that delivers alerts to in-app
/// toasts and system notifications.
class AlertSinkImpl implements AlertSink {
  AlertSinkImpl({
    required this.notificationService,
    required this.getNavigationContext,
  });

  final NotificationService notificationService;
  final BuildContext? Function() getNavigationContext;

  @override
  Future<void> deliverInAppToast(AlertPayload alert) async {
    final IconData icon = switch (alert.priority) {
      AlertPriority.high => Icons.priority_high_rounded,
      AlertPriority.normal => Icons.notifications_outlined,
      AlertPriority.low => Icons.info_outline_rounded,
    };

    notificationService.success(
      alert.title,
      icon: icon,
      onTap: alert.entityRef != null
          ? () {
              final context = getNavigationContext();
              if (context != null && context.mounted) {
                deepLinkNavigate(alert.entityRef!.webUrl, context);
              }
            }
          : null,
    );
  }

  @override
  Future<void> deliverSystemNotification(AlertPayload alert) async {
    await BackgroundWatcherService.instance.showSystemNotification(alert);
  }
}
