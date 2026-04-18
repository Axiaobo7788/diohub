import 'package:diohub/app/env_config.dart';
import 'package:diohub/app/sentry/sentry_event_scrubber.dart';
import 'package:diohub/app/settings/error_tracking.dart';
import 'package:diohub/flavors.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Initialize Sentry with privacy-first configuration based on user settings.
///
/// Features are controlled by [tracking] toggles:
/// - crashReports: master switch (empty DSN disables Sentry entirely)
/// - httpMetadata: HTTP breadcrumbs via dio.addSentry()
/// - navigationTracking: SentryNavigatorObserver
/// - performanceTracing: tracing and profiling sample rates
/// - sessionReplay: visual recording with masking
Future<void> initSentry({
  required void Function() appRunner,
  required ErrorTrackingSettings tracking,
}) async {
  await SentryFlutter.init(
    (options) {
      // Master switch: if crash reports disabled, set empty DSN (Sentry no-ops)
      options.dsn = tracking.crashReports ? EnvConfig.sentryDsn : '';

      // Environment tagging based on flavor (dev vs rel)
      options.environment = F.appFlavor.name; // "dev" or "rel"

      // Always-on privacy safeguards
      options.sendDefaultPii = false; // Never send IP, user agent, or PII
      options.maxRequestBodySize =
          MaxRequestBodySize.never; // Never send request bodies

      // Disabled: visual captures (too risky even with masking)
      options.attachScreenshot = false;
      options.attachViewHierarchy = false;

      // Performance tracing (user-controlled)
      if (tracking.performanceTracing) {
        // Lower sample rates for dev (noisier traffic), higher for rel
        final isDev = F.appFlavor == Flavor.dev;
        options.tracesSampleRate = isDev ? 0.1 : 0.2; // 10% dev, 20% rel
        options.profilesSampleRate = isDev ? 0.2 : 0.5; // 20% dev, 50% rel
      } else {
        options.tracesSampleRate = 0;
        options.profilesSampleRate = 0;
      }

      // Session replay (user-controlled, off by default)
      if (tracking.sessionReplay) {
        // Lower sample rates for dev, slightly higher for rel
        final isDev = F.appFlavor == Flavor.dev;
        options.replay.sessionSampleRate =
            isDev ? 0.02 : 0.05; // 2% dev, 5% rel
        options.replay.onErrorSampleRate = 1.0; // Always record error sessions
        options.privacy.maskAllText = true;
        options.privacy.maskAllImages = true;
      }

      // Defense-in-depth data scrubbing using SentryEventScrubber
      // All three hooks (beforeSend, beforeSendTransaction, beforeBreadcrumb)
      // are wrapped with fail-closed semantics: if scrubbing throws, drop the
      // event/transaction/breadcrumb rather than send unscrubbed data.

      options
        ..beforeSend = (event, hint) {
          try {
            return SentryEventScrubber.scrubEvent(event, hint: hint);
          } catch (e, stackTrace) {
            if (kDebugMode) {
              print('Sentry event scrubbing failed: $e');
              print('Stack trace: $stackTrace');
            }
            // Fail-closed: drop the event if scrubbing fails
            return null;
          }
        }
        ..beforeSendTransaction = (txn, hint) {
          try {
            return SentryEventScrubber.scrubTransaction(txn, hint: hint);
          } catch (e, stackTrace) {
            if (kDebugMode) {
              print('Sentry transaction scrubbing failed: $e');
              print('Stack trace: $stackTrace');
            }
            // Fail-closed: drop the transaction if scrubbing fails
            return null;
          }
        }
        ..beforeBreadcrumb = (breadcrumb, hint) {
          try {
            return SentryEventScrubber.scrubBreadcrumb(breadcrumb, hint: hint);
          } catch (e, stackTrace) {
            if (kDebugMode) {
              print('Sentry breadcrumb scrubbing failed: $e');
              print('Stack trace: $stackTrace');
            }
            // Fail-closed: drop the breadcrumb if scrubbing fails
            return null;
          }
        }

        // Debug logging (disable in rel flavor)
        ..debug = F.appFlavor == Flavor.dev;
    },
    appRunner: appRunner,
  );
}
