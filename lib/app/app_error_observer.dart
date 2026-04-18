import 'package:diohub/app/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global error observer for all Riverpod providers.
/// Logs any provider failure via AppLogger, acting as a safety net
/// to ensure no error goes completely unnoticed.
///
/// AppLogger.error() automatically forwards to Sentry via SentryTalkerObserver,
/// so we don't need explicit Sentry.captureException() here.
base class AppErrorObserver extends ProviderObserver {
  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    AppLogger.error(
      'Provider ${context.provider.name ?? context.provider.runtimeType} failed',
      error: error,
      stackTrace: stackTrace,
      tag: 'Riverpod',
    );
  }
}
