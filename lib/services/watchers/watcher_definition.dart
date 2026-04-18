import 'package:diohub/app/app_logger.dart';

/// Abstract base class for custom notification watchers.
///
/// A *watcher* encapsulates:
///  1. **What** to monitor (encoded in the subclass fields).
///  2. **How often** to check ([interval]).
///  3. **How to check** ([check] — the single method subclasses implement).
///  4. **How to identify** this watcher type ([key]) and this specific
///     instance ([instanceId]).
///
/// The [WatcherEngine] calls [check] on a timer (foreground) or background
/// task and routes the resulting [AlertPayload]s to the appropriate channels.
///
/// ## Implementing a watcher
///
/// ```dart
/// class ReleaseWatcher extends WatcherDefinition {
///   ReleaseWatcher({required this.owner, required this.repoName})
///       : super(interval: const Duration(hours: 2));
///
///   final String owner;
///   final String repoName;
///
///   @override String get key => 'release';
///   @override String get instanceId => '$owner/$repoName';
///   @override String get displayName => 'New releases for $owner/$repoName';
///
///   @override
///   Future<CheckResult> check(WatcherContext ctx) async {
///     final latest = await _fetchLatestRelease(owner, repoName);
///     final lastSeen = ctx.read<String?>('lastTag');
///     if (latest.tag == lastSeen) return const CheckIdle();
///     await ctx.write('lastTag', latest.tag);
///     return CheckFired([
///       AlertPayload(
///         id: 'release:$owner/$repoName:${latest.tag}',
///         title: '${latest.tag} released in $owner/$repoName',
///         watcherKey: key,
///       ),
///     ]);
///   }
/// }
/// ```
import 'package:diohub/services/base/base_service.dart';
import 'package:diohub/services/watchers/watcher_context_keys.dart';
import 'package:diohub/services/watchers/watcher_types.dart';
import 'package:flutter/foundation.dart';

/// Context passed to [WatcherDefinition.check] giving access to
/// per-instance persistent storage (surviving app restarts).
abstract interface class WatcherContext {
  /// API client for making network requests.
  /// Available in both foreground (via ref) and background (direct injection) contexts.
  WatcherApiClient get apiClient;
  
  /// Read a previously stored value for this watcher instance.
  Future<T?> read<T>(String key);

  /// Persist a value for this watcher instance.  Values must be JSON-
  /// serialisable primitives (String, int, double, bool, List, Map).
  Future<void> write<T>(String key, T value);

  /// Remove a previously stored key.
  Future<void> remove(String key);

  /// Remove all stored keys for this watcher instance (e.g. on unregister).
  Future<void> clear();
}

/// Base class for all watchers.
@immutable
abstract class WatcherDefinition {
  const WatcherDefinition({
    required this.interval,
    this.enabled = true,
  });

  // ── Identity ──────────────────────────────────────────────────────────────

  /// Stable key identifying the *type* of watcher (e.g. `'release'`,
  /// `'inbox_poll'`, `'run_status'`).  Used for settings toggles and
  /// system-notification channel grouping.
  String get key;

  /// Identifies *this specific instance* within its [key] group.
  ///
  /// For singletons (e.g. inbox poll) return a constant like `'default'`.
  /// For per-resource watchers return a unique slug (e.g. `'owner/repo'`).
  String get instanceId;

  /// A combined unique id: `key:instanceId`.
  String get watcherId => '$key:$instanceId';

  /// Human-readable label for settings / debug UI.
  String get displayName;

  // ── Scheduling ────────────────────────────────────────────────────────────

  /// How often the engine should invoke [check].
  ///
  /// The engine guarantees *at least* this interval between checks,
  /// but actual cadence depends on app lifecycle and OS background limits.
  final Duration interval;

  /// Whether the watcher is active.  Disabled watchers are skipped by the
  /// engine but remain registered (settings toggle).
  final bool enabled;

  // ── Scope gating ──────────────────────────────────────────────────────────

  /// OAuth scopes required for this watcher to function.
  /// Empty set = no scope restrictions. Engine skips checks if scopes missing.
  Set<String> get requiredScopes => const <String>{};

  // ── Core contract ─────────────────────────────────────────────────────────

  /// Perform one check cycle.
  ///
  /// Must not throw — return [CheckError] instead so the engine can apply
  /// retry / back-off policy.  Use [ctx] for per-instance persistent
  /// storage (e.g. "last seen tag").
  Future<CheckResult> check(WatcherContext ctx);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatcherDefinition &&
          runtimeType == other.runtimeType &&
          watcherId == other.watcherId;

  @override
  int get hashCode => watcherId.hashCode;

  @override
  String toString() => '$runtimeType($watcherId)';
}

// ── Polling watcher (recurring, compare now vs lastChecked) ───────────────────

/// Base for recurring watchers that compare "now" to "last time I checked".
///
/// Concrete subclasses implement only [fetchUpdates]. Timestamp management,
/// [CheckResult] wrapping, and error handling are inherited.
abstract class PollingWatcher extends WatcherDefinition {
  const PollingWatcher({required super.interval, super.enabled});

  /// Return alerts for anything new since [lastChecked].
  /// [lastChecked] is null on first run.
  Future<List<AlertPayload>> fetchUpdates(
    WatcherContext ctx,
    DateTime? lastChecked,
  );

  @override
  Future<CheckResult> check(WatcherContext ctx) async {
    try {
      final lastRaw = await ctx.read<String?>(WatcherContextKeys.lastChecked);
      final lastChecked = lastRaw != null ? DateTime.tryParse(lastRaw) : null;

      final alerts = await fetchUpdates(ctx, lastChecked);
      await ctx.write(
        WatcherContextKeys.lastChecked,
        DateTime.now().toUtc().toIso8601String(),
      );

      return alerts.isEmpty ? const CheckIdle() : CheckFired(alerts);
    } catch (e, s) {
      AppLogger.warning(
        'Watcher check failed',
        error: e,
        stackTrace: s,
        tag: 'WatcherDefinition',
      );
      return CheckError(e, s);
    }
  }
}

// ── One-off watcher (auto-unregister on completion) ──────────────────────────

/// Base for one-shot watchers that auto-unregister on completion.
///
/// Concrete subclasses implement only [evaluate].
abstract class OneOffWatcher extends WatcherDefinition {
  const OneOffWatcher({required super.interval, super.enabled});

  /// Check if the condition is met. Return [OneOffResult.pending] to keep
  /// polling, or [OneOffResult.completed] to fire the alert and unregister.
  Future<OneOffResult> evaluate(WatcherContext ctx);

  @override
  Future<CheckResult> check(WatcherContext ctx) async {
    try {
      final result = await evaluate(ctx);
      return switch (result) {
        OneOffPending() => const CheckIdle(),
        OneOffCompleted(:final alert) => CheckDone([alert]),
      };
    } catch (e, s) {
      AppLogger.warning(
        'One-off watcher evaluate failed',
        error: e,
        stackTrace: s,
        tag: 'WatcherDefinition',
      );
      return CheckError(e, s);
    }
  }
}
