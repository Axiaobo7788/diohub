import 'package:diohub/app/sentry/sentry_scrubber.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// SDK-aware wrappers for Sentry's beforeSend, beforeSendTransaction, and
/// beforeBreadcrumb hooks.
///
/// These methods delegate to SentryScrubber for actual scrubbing logic and
/// implement fail-closed semantics: if scrubbing throws an exception, the
/// event/transaction/breadcrumb is dropped (returns null) rather than sent
/// with potentially unscrubbed data.
abstract final class SentryEventScrubber {
  SentryEventScrubber._();

  /// Scrub a SentryEvent before sending.
  ///
  /// This is the beforeSend callback. It scrubs:
  /// - Request URL
  /// - Request headers (removes sensitive ones)
  /// - Request data (nulls it out for defense-in-depth)
  /// - Error message
  /// - Exception values
  /// - All breadcrumbs attached to the event (these bypass beforeBreadcrumb)
  /// - User context (nulls it out for defense-in-depth)
  ///
  /// Returns null if scrubbing fails (fail-closed).
  static SentryEvent? scrubEvent(SentryEvent event, {Hint? hint}) {
    try {
      // Scrub request URL
      if (event.request?.url != null) {
        final scrubbedUrl = SentryScrubber.scrubString(event.request!.url!);
        event = event.copyWith(
          request: event.request!.copyWith(url: scrubbedUrl),
        );
      }

      // Null out request body (defense in depth)
      if (event.request?.data != null) {
        event = event.copyWith(
          request: event.request!.copyWith(data: null),
        );
      }

      // Scrub request headers
      if (event.request?.headers != null) {
        final scrubbedHeaders = SentryScrubber.scrubHeaders(
          event.request!.headers.cast<String, String>(),
        );
        event = event.copyWith(
          request: event.request!.copyWith(headers: scrubbedHeaders),
        );
      }

      // Scrub error message
      if (event.message?.formatted != null) {
        final scrubbedMessage =
            SentryScrubber.scrubString(event.message!.formatted);
        event = event.copyWith(
          message: event.message!.copyWith(formatted: scrubbedMessage),
        );
      }

      // Scrub exception values
      if (event.exceptions != null && event.exceptions!.isNotEmpty) {
        final scrubbedExceptions = event.exceptions!.map((exception) {
          if (exception.value != null) {
            final scrubbedValue = SentryScrubber.scrubString(exception.value!);
            return exception.copyWith(value: scrubbedValue);
          }
          return exception;
        }).toList();
        event = event.copyWith(exceptions: scrubbedExceptions);
      }

      // Scrub all breadcrumbs attached to the event (these bypass beforeBreadcrumb)
      if (event.breadcrumbs != null && event.breadcrumbs!.isNotEmpty) {
        final scrubbedBreadcrumbs = event.breadcrumbs!
            .map((b) => _scrubBreadcrumbInPlace(b))
            .where((b) => b != null)
            .cast<Breadcrumb>()
            .toList();
        event = event.copyWith(breadcrumbs: scrubbedBreadcrumbs);
      }

      // Null out user context (defense in depth - we set sendDefaultPii=false but be explicit)
      event = event.copyWith(user: null);

      return event;
    } catch (e) {
      if (kDebugMode) {
        print('Sentry event scrubbing failed: $e');
      }
      // Fail-closed: drop the event if scrubbing fails
      return null;
    }
  }

  /// Scrub a SentryTransaction before sending.
  ///
  /// This is the beforeSendTransaction callback. It scrubs:
  /// - Transaction name (route name, may contain sensitive params)
  /// - Request URL (if attached)
  /// - All spans' data maps (recursively)
  /// - User context
  ///
  /// Note: Spans are immutable serialized objects at this point (from toJson),
  /// so we can only scrub the data maps, not the description/operation fields.
  ///
  /// Returns null if scrubbing fails (fail-closed).
  static SentryTransaction? scrubTransaction(
    SentryTransaction txn, {
    Hint? hint,
  }) {
    try {
      // Scrub transaction name (route name or HTTP URL)
      if (txn.transaction != null) {
        final scrubbedName = SentryScrubber.scrubString(txn.transaction!);
        txn = txn.copyWith(transaction: scrubbedName);
      }

      // Scrub all spans' data maps (spans themselves are immutable)
      // We can only scrub the data field, not description/operation
      if (txn.spans.isNotEmpty) {
        // Spans are read-only, but we can scrub their data maps which are mutable
        for (final span in txn.spans) {
          if (span.data.isNotEmpty) {
            // Scrub the span's data map in place
            final scrubbedData = SentryScrubber.scrubMapDeep(span.data);
            span.data.clear();
            span.data.addAll(scrubbedData);
          }
        }
      }

      // Scrub request URL if attached
      if (txn.request?.url != null) {
        final scrubbedUrl = SentryScrubber.scrubString(txn.request!.url!);
        txn = txn.copyWith(
          request: txn.request!.copyWith(url: scrubbedUrl),
        );
      }

      // Null out user context
      txn = txn.copyWith(user: null);

      return txn;
    } catch (e) {
      if (kDebugMode) {
        print('Sentry transaction scrubbing failed: $e');
      }
      // Fail-closed: drop the transaction if scrubbing fails
      return null;
    }
  }

  /// Scrub a Breadcrumb before adding it to the event.
  ///
  /// This is the beforeBreadcrumb callback. It scrubs:
  /// - Breadcrumb message
  /// - Breadcrumb data (recursively)
  /// - HTTP breadcrumb headers
  ///
  /// Returns null if scrubbing fails (fail-closed).
  static Breadcrumb? scrubBreadcrumb(Breadcrumb? breadcrumb, {Hint? hint}) {
    if (breadcrumb == null) return null;
    try {
      return _scrubBreadcrumbInPlace(breadcrumb);
    } catch (e) {
      if (kDebugMode) {
        print('Sentry breadcrumb scrubbing failed: $e');
      }
      // Fail-closed: drop the breadcrumb if scrubbing fails
      return null;
    }
  }

  /// Internal helper to scrub a breadcrumb in place.
  static Breadcrumb? _scrubBreadcrumbInPlace(Breadcrumb breadcrumb) {
    // Scrub breadcrumb message
    if (breadcrumb.message != null) {
      final scrubbedMessage = SentryScrubber.scrubString(breadcrumb.message!);
      breadcrumb = breadcrumb.copyWith(message: scrubbedMessage);
    }

    // Scrub breadcrumb data (recursively)
    final data = breadcrumb.data;
    if (data != null && data.isNotEmpty) {
      final scrubbedData = SentryScrubber.scrubMapDeep(data);

      // Strip Authorization header specifically from HTTP breadcrumbs (defense in depth)
      if (breadcrumb.type == 'http' && scrubbedData['headers'] is Map) {
        final headers = Map<String, dynamic>.from(
          scrubbedData['headers'] as Map<dynamic, dynamic>,
        );
        final scrubbedHeaders = SentryScrubber.scrubHeaders(
          headers.map((k, v) => MapEntry(k.toString(), v.toString())),
        );
        scrubbedData['headers'] = scrubbedHeaders;
      }

      breadcrumb = breadcrumb.copyWith(data: scrubbedData);
    }

    return breadcrumb;
  }
}
