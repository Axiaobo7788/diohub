/// Routes [AlertPayload]s to the appropriate delivery channels.
///
/// This is a pure data router — no Flutter imports, no direct UI calls.
/// It delegates actual delivery to an [AlertSink] implementation.
library;

import 'package:diohub/services/watchers/watcher_engine.dart';
import 'package:diohub/services/watchers/watcher_types.dart';

/// Creates an [AlertDispatcher] that routes alerts through the given [AlertSink].
///
/// [sink] handles the actual delivery of toasts and system notifications.
/// [isSystemNotificationsEnabled] is read at dispatch time to decide whether
/// to call [AlertSink.deliverSystemNotification].
///
/// Usage in the watcher engine provider:
/// ```dart
/// final engine = WatcherEngine(
///   dispatcher: createAlertDispatcher(
///     sink: AlertSinkImpl(...),
///     isSystemNotificationsEnabled: () => ref.read(notificationsProvider).systemNotificationsEnabled,
///   ),
/// );
/// ```
AlertDispatcher createAlertDispatcher({
  required AlertSink sink,
  required bool Function() isSystemNotificationsEnabled,
}) {
  return (List<AlertPayload> alerts) async {
    for (final alert in alerts) {
      for (final channel in alert.channels) {
        switch (channel) {
          case AlertChannel.inAppToast:
            await sink.deliverInAppToast(alert);

          case AlertChannel.systemNotification:
            if (isSystemNotificationsEnabled()) {
              await sink.deliverSystemNotification(alert);
            }

          case AlertChannel.silent:
            // No-op.  Watchers using this channel update state via their
            // own providers or WatcherContext — the engine just runs them.
            break;
        }
      }
    }
  };
}

// AlertDispatcher typedef is defined in watcher_engine.dart and re-exported
// via the barrel file.  This file uses it via the watcher_types import.
