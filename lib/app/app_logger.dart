import 'package:diohub/app/scoped_talker_log.dart';
import 'package:diohub/app/talker.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Centralized logging utility for the app.
///
/// Forwards to the global [appTalker] instance for unified logging.
class AppLogger {
  AppLogger._();

  /// Log an error with optional [error] object and [stackTrace].
  static void error(
    final String message, {
    final Object? error,
    final StackTrace? stackTrace,
    final String? tag,
  }) {
    final String label = tag ?? 'AppError';
    final String msg = tag != null ? '[$label] $message' : message;
    if (error != null || stackTrace != null) {
      appTalker.handle(error ?? message, stackTrace, msg);
    } else {
      appTalker.error(msg);
    }
  }

  /// Log a warning with optional [error] object and [stackTrace].
  static void warning(
    final String message, {
    final Object? error,
    final StackTrace? stackTrace,
    final String? tag,
  }) {
    final String label = tag ?? 'AppWarning';
    final String msg = tag != null ? '[$label] $message' : message;
    appTalker.warning(msg, error, stackTrace);
  }

  /// Log an informational message (debug mode only).
  static void info(
    final String message, {
    final String? tag,
  }) {
    final String label = tag ?? 'AppInfo';
    final String msg = tag != null ? '[$label] $message' : message;
    appTalker.info(msg);
  }

  /// Log a scoped error (appears in entity-scoped log viewer).
  static void scopedError(
    final String message,
    final EntityRef entityRef, {
    final Object? error,
    final StackTrace? stackTrace,
    final String? tag,
  }) {
    final String msg = tag != null ? '[$tag] $message' : message;
    appTalker.logCustom(ScopedTalkerLog(
      message: msg,
      entityRef: entityRef,
      logLevel: LogLevel.error,
      exception: error,
      error: error is Error ? error : null,
      stackTrace: stackTrace,
    ));
  }

  /// Log a scoped warning.
  static void scopedWarning(
    final String message,
    final EntityRef entityRef, {
    final Object? error,
    final StackTrace? stackTrace,
    final String? tag,
  }) {
    final String msg = tag != null ? '[$tag] $message' : message;
    appTalker.logCustom(ScopedTalkerLog(
      message: msg,
      entityRef: entityRef,
      logLevel: LogLevel.warning,
      exception: error,
      error: error is Error ? error : null,
      stackTrace: stackTrace,
    ));
  }

  /// Log a scoped info message.
  static void scopedInfo(
    final String message,
    final EntityRef entityRef, {
    final String? tag,
  }) {
    final String msg = tag != null ? '[$tag] $message' : message;
    appTalker.logCustom(ScopedTalkerLog(
      message: msg,
      entityRef: entityRef,
      logLevel: LogLevel.info,
    ));
  }
}
