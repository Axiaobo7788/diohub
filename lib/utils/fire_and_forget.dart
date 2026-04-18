import 'dart:async';

import 'package:diohub/app/app_logger.dart';

/// Launches a fire-and-forget async operation with automatic error logging.
///
/// Use for background tasks that don't need awaiting (e.g. sync, persistence).
/// Any exceptions are caught and logged via [AppLogger] to prevent silent failures.
///
/// [label] should describe the operation for debugging (e.g. "Background sync").
void fireAndForget(Future<void> Function() fn, {required String label}) {
  unawaited(fn().catchError((Object e, StackTrace st) {
    AppLogger.error('$label failed', error: e, stackTrace: st, tag: 'Background');
  }));
}
