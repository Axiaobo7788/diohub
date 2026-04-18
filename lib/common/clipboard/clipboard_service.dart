import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/providers/haptic_service_provider.dart';
import 'package:flutter/cupertino.dart' show BuildContext;
import 'package:flutter/material.dart' show BuildContext;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single entry point for copying text to the clipboard.
///
/// Always writes to the system clipboard and shows a success toast.
/// Obtain via [clipboardServiceProvider]; callers with [WidgetRef] use
/// [ref.read(clipboardServiceProvider).copy], callers with only [BuildContext]
/// use [ProviderScope.containerOf(context).read(clipboardServiceProvider).copy].
class ClipboardService {
  ClipboardService(this._notifications, this._haptics);

  final NotificationService _notifications;
  final HapticService _haptics;

  /// Copies [text] to the system clipboard and shows a success toast.
  Future<void> copy(final String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    await _haptics.lightImpact();
    _notifications.success('Copied to clipboard.');
  }
}

final Provider<ClipboardService> clipboardServiceProvider =
    Provider<ClipboardService>(
  (final Ref ref) => ClipboardService(
    ref.read(notificationServiceProvider),
    ref.read(hapticServiceProvider),
  ),
);
