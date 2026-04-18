import 'package:diohub/app/sentry/sentry_scrubber.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Safe Talker observer that scrubs exceptions before forwarding to Sentry.
///
/// CRITICAL: This observer scrubs exceptions BEFORE calling Sentry.captureException
/// to prevent DioEventProcessor from extracting full URLs and headers from
/// DioException.requestOptions. By replacing DioException with a sanitized
/// summary, we ensure sensitive data never reaches the Sentry SDK's internal
/// processors.
///
/// - Errors (AppLogger.error) -> scrub -> Sentry events via captureException
/// - Warnings (AppLogger.warning) -> scrub -> Sentry breadcrumbs
/// - Info (AppLogger.info) -> local only (no Sentry)
///
/// This observer bridges the AppLogger -> Talker -> Sentry pipeline,
/// ensuring every error logged via AppLogger.error() automatically
/// reaches Sentry in a safe, scrubbed form.
class SentryTalkerObserver extends TalkerObserver {
  @override
  void onError(TalkerError err) {
    // Scrub the exception before sending to Sentry
    // This is CRITICAL: DioException objects must be sanitized before
    // captureException to prevent DioEventProcessor from extracting sensitive
    // data from requestOptions.
    final errorObj = err.error ?? err.message;
    if (errorObj == null) return;
    
    final scrubbedException = SentryScrubber.scrubException(errorObj);

    Sentry.captureException(
      scrubbedException,
      stackTrace: err.stackTrace,
    );
  }

  @override
  void onException(TalkerException err) {
    // Scrub the exception before sending to Sentry
    final exception = err.exception;
    if (exception == null) return;
    
    final scrubbedException = SentryScrubber.scrubException(exception);

    Sentry.captureException(
      scrubbedException,
      stackTrace: err.stackTrace,
    );
  }

  @override
  void onLog(TalkerData data) {
    // Forward warnings as Sentry breadcrumbs (enriches next error's context)
    if (data.logLevel == LogLevel.warning) {
      // Scrub the breadcrumb message before sending
      // NOTE: Sentry.addBreadcrumb does NOT invoke beforeBreadcrumb callback,
      // so we must scrub here.
      final scrubbedMessage = SentryScrubber.scrubString(data.displayMessage);

      Sentry.addBreadcrumb(Breadcrumb(
        message: scrubbedMessage,
        level: SentryLevel.warning,
        category: 'app.warning',
        timestamp: data.time,
      ));
    }
  }
}
