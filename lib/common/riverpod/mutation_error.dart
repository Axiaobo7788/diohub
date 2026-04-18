/// Shared helpers for mutation error handling so providers don't duplicate
/// haptic + toast logic.
library;

import 'dart:async';

import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/providers/haptic_service_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows haptic feedback and an error toast. Use in mutation onError callbacks
/// and catch blocks so all mutation failures behave the same.
///
/// Note: This function does NOT log -- the caller (mixin or provider) should
/// log via AppLogger before calling this. This purely handles UI side effects.
Future<void> showMutationError(
  final Ref ref,
  final String message, {
  final Object? error,
  final StackTrace? stackTrace,
}) async {
  await ref.read(hapticServiceProvider).heavyImpact();
  ref.read(notificationServiceProvider).error(message);
}
