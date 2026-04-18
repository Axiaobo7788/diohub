/// Core types for the custom notification / watcher system.
library;

import 'package:diohub_models/models/entity_ref.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'watcher_types.freezed.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Alert delivery
// ──────────────────────────────────────────────────────────────────────────────

enum AlertChannel {
  inAppToast,
  systemNotification,
  silent,
}

enum AlertPriority {
  low,
  normal,
  high,
}

@freezed
abstract class AlertPayload with _$AlertPayload {
  const AlertPayload._();

  const factory AlertPayload({
    required String id,
    required String title,
    required String watcherKey,
    String? body,
    EntityRef? entityRef,
    @Default({AlertChannel.inAppToast}) Set<AlertChannel> channels,
    @Default(AlertPriority.normal) AlertPriority priority,
    String? groupKey,
    @Default({}) Map<String, String> metadata,
  }) = _AlertPayload;

  @override
  String toString() => 'AlertPayload($id, "$title")';
}

/// Interface for delivering alerts to UI channels.
///
/// The [AlertDispatcher] (service layer) routes alerts to an [AlertSink]
/// implementation (provider/UI layer) which then shows toasts, system
/// notifications, or other UI.
abstract interface class AlertSink {
  /// Deliver an in-app toast alert.
  Future<void> deliverInAppToast(AlertPayload alert);

  /// Deliver a system (OS) notification.
  Future<void> deliverSystemNotification(AlertPayload alert);
}

// ──────────────────────────────────────────────────────────────────────────────
// Watcher lifecycle
// ──────────────────────────────────────────────────────────────────────────────

@freezed
sealed class CheckResult with _$CheckResult {
  const CheckResult._();

  const factory CheckResult.idle() = CheckIdle;
  const factory CheckResult.fired(List<AlertPayload> alerts) = CheckFired;
  const factory CheckResult.done(
      [@Default([]) List<AlertPayload> finalAlerts]) = CheckDone;
  const factory CheckResult.error(Object error, [StackTrace? stackTrace]) =
      CheckError;
}

// ──────────────────────────────────────────────────────────────────────────────
// One-off watcher result
// ──────────────────────────────────────────────────────────────────────────────

@freezed
sealed class OneOffResult with _$OneOffResult {
  const OneOffResult._();

  const factory OneOffResult.pending() = OneOffPending;
  const factory OneOffResult.completed(AlertPayload alert) = OneOffCompleted;
}
