/// The watcher engine: schedules, runs, and delivers alerts from
/// [WatcherDefinition] instances.
///
/// ## Lifecycle
///
/// ```
/// engine.register(myWatcher);   // adds to registry
/// engine.start();               // kicks off all timers
/// // ... app is running ...
/// engine.stop();                // cancels all timers (e.g. on logout)
/// engine.unregister(myWatcher); // removes from registry + cleans up state
/// ```
///
/// The engine does **not** own the delivery mechanism — it delegates to an
/// [AlertDispatcher] callback so the caller can route to in-app toasts,
/// system notifications, or both.
library;

import 'dart:async';

import 'package:diohub_database/database/database.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:diohub/services/watchers/serializable_watcher.dart';
import 'package:diohub/services/watchers/watcher_context_impl.dart';
import 'package:diohub/services/watchers/watcher_definition.dart';
import 'package:diohub/utils/fire_and_forget.dart';
import 'package:diohub/services/watchers/watcher_types.dart';

/// Creates a [WatcherContext] for a watcher. When null, engine uses [AppMetaWatcherContext].
typedef WatcherContextFactory = WatcherContext Function(
    WatcherDefinition watcher);

/// Callback invoked by the engine when a watcher fires.
///
/// The dispatcher is responsible for routing [alerts] to the appropriate
/// channels (toast, system notification, silent badge update, etc.).
typedef AlertDispatcher = Future<void> Function(List<AlertPayload> alerts);

/// Callback invoked when a watcher check encounters an error.
typedef WatcherErrorHandler = void Function(
  WatcherDefinition watcher,
  Object error,
  StackTrace? stackTrace,
);

/// Engine state change events for UI and persistence.
enum WatcherEvent {
  registered,
  unregistered,
  checkCompleted,
  alertFired,
  error,
}

/// Foreground watcher scheduler.
///
/// Runs [WatcherDefinition.check] on a [Timer.periodic] for each registered
/// watcher.  Call [start] / [stop] to control the global run state.
///
/// For background execution (app not in foreground), see the planned
/// `BackgroundWatcherTask` which serialises registered watchers to
/// [SharedPreferences] and runs them via `workmanager`.
class WatcherEngine {
  WatcherEngine({
    required AlertDispatcher dispatcher,
    WatcherErrorHandler? onError,
    WatcherContextFactory? contextFactory,
    WatcherDao? watcherDao,
    String? accountKey,
    AppMetaDao? appMetaDao,
    WatcherApiClient? apiClient,
    Set<String> Function()? grantedScopesFn,
  })  : _dispatcher = dispatcher,
        _onError = onError,
        _contextFactory = contextFactory,
        _watcherDao = watcherDao,
        _accountKey = accountKey,
        _appMetaDao = appMetaDao,
        _apiClient = apiClient,
        _grantedScopesFn = grantedScopesFn;

  final AlertDispatcher _dispatcher;
  final WatcherErrorHandler? _onError;
  final WatcherContextFactory? _contextFactory;
  final WatcherDao? _watcherDao;
  final String? _accountKey;
  final AppMetaDao? _appMetaDao;
  final WatcherApiClient? _apiClient;
  final Set<String> Function()? _grantedScopesFn;

  // ── Registry ──────────────────────────────────────────────────────────────

  final Map<String, WatcherDefinition> _watchers = {};
  final Map<String, Timer> _timers = {};
  final Map<String, WatcherContext> _contexts = {};

  /// Per-watcher metadata for management UI.
  final Map<String, DateTime> _lastCheckTimes = {};
  final Map<String, CheckResult> _lastResults = {};

  /// Fired on every engine state change (register, unregister, check, alert).
  final StreamController<WatcherEvent> _eventController =
      StreamController<WatcherEvent>.broadcast();
  Stream<WatcherEvent> get events => _eventController.stream;

  /// Deduplication: alert ids fired recently (cleared after cooldown).
  final Map<String, DateTime> _recentAlertIds = {};

  /// Cooldown window for deduplication.
  static const Duration _deduplicationCooldown = Duration(minutes: 5);

  bool _running = false;

  /// Whether the engine is actively scheduling checks.
  bool get isRunning => _running;

  /// All registered watchers (read-only snapshot).
  List<WatcherDefinition> get watchers =>
      List<WatcherDefinition>.unmodifiable(_watchers.values);

  /// Look up a watcher by its [WatcherDefinition.watcherId].
  WatcherDefinition? getWatcher(String watcherId) => _watchers[watcherId];

  /// Last time this watcher was checked (for management UI).
  DateTime? lastCheckTime(String watcherId) => _lastCheckTimes[watcherId];

  /// Last check result for this watcher (for management UI).
  CheckResult? lastResult(String watcherId) => _lastResults[watcherId];

  // ── Registration ──────────────────────────────────────────────────────────

  /// Register a watcher.  If the engine is already running and the watcher
  /// is [WatcherDefinition.enabled], a timer is started immediately.
  void register(WatcherDefinition watcher) {
    _watchers[watcher.watcherId] = watcher;
    _eventController.add(WatcherEvent.registered);
    if (_running && watcher.enabled) {
      _startTimer(watcher);
    }
    fireAndForget(() => _persistWatcherList(), label: 'Watcher persist');
  }

  /// Register multiple watchers at once.
  void registerAll(Iterable<WatcherDefinition> watchers) {
    for (final w in watchers) {
      register(w);
    }
  }

  /// Unregister a watcher, cancel its timer, and clean up stored context.
  Future<void> unregister(WatcherDefinition watcher) async {
    _cancelTimer(watcher.watcherId);
    _watchers.remove(watcher.watcherId);
    _lastCheckTimes.remove(watcher.watcherId);
    _lastResults.remove(watcher.watcherId);
    final ctx = _contexts.remove(watcher.watcherId);
    await ctx?.clear();
    _eventController.add(WatcherEvent.unregistered);
    await _persistWatcherList();
  }

  /// Replace a watcher definition (e.g. when settings change the interval).
  /// Restarts the timer if the engine is running.
  void update(WatcherDefinition watcher) {
    _cancelTimer(watcher.watcherId);
    _watchers[watcher.watcherId] = watcher;
    if (_running && watcher.enabled) {
      _startTimer(watcher);
    }
    fireAndForget(() => _persistWatcherList(), label: 'Watcher persist');
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Start the engine — begins periodic checks for all enabled watchers.
  void start() {
    if (_running) return;
    _running = true;
    for (final w in _watchers.values) {
      if (w.enabled) _startTimer(w);
    }
  }

  /// Stop the engine — cancels all timers.  Watchers remain registered.
  void stop() {
    _running = false;
    for (final id in _timers.keys.toList()) {
      _cancelTimer(id);
    }
  }

  /// Manually trigger a check for a specific watcher (ignoring the timer).
  /// Useful for "check now" buttons in UI.
  Future<void> checkNow(String watcherId) async {
    final watcher = _watchers[watcherId];
    if (watcher == null) return;
    await _runCheck(watcher);
  }

  /// Dispose the engine entirely.  Call on logout / app teardown.
  Future<void> dispose() async {
    stop();
    _watchers.clear();
    _contexts.clear();
    _lastCheckTimes.clear();
    _lastResults.clear();
    _recentAlertIds.clear();
    await _eventController.close();
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _startTimer(WatcherDefinition watcher) {
    _cancelTimer(watcher.watcherId);

    // Run once immediately, then periodically.
    fireAndForget(() => _runCheck(watcher), label: 'Watcher check');

    _timers[watcher.watcherId] = Timer.periodic(
      watcher.interval,
      (_) => fireAndForget(() => _runCheck(watcher), label: 'Watcher check'),
    );
  }

  void _cancelTimer(String watcherId) {
    _timers.remove(watcherId)?.cancel();
  }

  WatcherContext _contextFor(WatcherDefinition watcher) {
    final factory = _contextFactory;
    return _contexts.putIfAbsent(
      watcher.watcherId,
      () => factory != null
          ? factory(watcher)
          : AppMetaWatcherContext(
              watcher.watcherId,
              _appMetaDao!,
              _apiClient!,
            ),
    );
  }

  Future<void> _runCheck(WatcherDefinition watcher) async {
    final watcherId = watcher.watcherId;
    
    // Scope gate: skip if required scopes aren't granted
    if (watcher.requiredScopes.isNotEmpty && _grantedScopesFn != null) {
      final granted = _grantedScopesFn();
      if (!watcher.requiredScopes.every(granted.contains)) {
        _lastCheckTimes[watcherId] = DateTime.now();
        _lastResults[watcherId] = const CheckIdle();
        return;
      }
    }
    
    try {
      final result = await watcher.check(_contextFor(watcher));

      _lastCheckTimes[watcherId] = DateTime.now();
      _lastResults[watcherId] = result;
      _eventController.add(WatcherEvent.checkCompleted);

      switch (result) {
        case CheckIdle():
          break;

        case CheckFired(:final alerts):
          final deduplicated = _deduplicate(alerts);
          if (deduplicated.isNotEmpty) {
            _eventController.add(WatcherEvent.alertFired);
            await _dispatcher(deduplicated);
          }

        case CheckDone(:final finalAlerts):
          final deduplicated = _deduplicate(finalAlerts);
          if (deduplicated.isNotEmpty) {
            _eventController.add(WatcherEvent.alertFired);
            await _dispatcher(deduplicated);
          }
          // Auto-unregister — watcher's purpose is fulfilled.
          _cancelTimer(watcherId);
          _watchers.remove(watcherId);
          _lastCheckTimes.remove(watcherId);
          _lastResults.remove(watcherId);
          unawaited(_persistWatcherList());

        case CheckError(:final error, :final stackTrace):
          _eventController.add(WatcherEvent.error);
          _onError?.call(watcher, error, stackTrace);
      }
    } catch (e, s) {
      _lastCheckTimes[watcherId] = DateTime.now();
      _lastResults[watcherId] = CheckError(e, s);
      _eventController.add(WatcherEvent.error);
      // Watcher violated the "don't throw" contract — handle gracefully.
      _onError?.call(watcher, e, s);
    }
  }

  List<AlertPayload> _deduplicate(List<AlertPayload> alerts) {
    _pruneOldAlertIds();

    final List<AlertPayload> result = [];
    for (final alert in alerts) {
      if (!_recentAlertIds.containsKey(alert.id)) {
        _recentAlertIds[alert.id] = DateTime.now();
        result.add(alert);
      }
    }
    return result;
  }

  void _pruneOldAlertIds() {
    final cutoff = DateTime.now().subtract(_deduplicationCooldown);
    _recentAlertIds.removeWhere((_, time) => time.isBefore(cutoff));
  }

  Future<void> _persistWatcherList() async {
    final dao = _watcherDao;
    final accountKey = _accountKey;
    if (dao == null || accountKey == null || accountKey.isEmpty) return;
    final entries = _watchers.values
        .whereType<SerializableWatcher>()
        .map((w) => (
              nodeId: w.watcherId,
              watcherType: w.key,
              config: w.toJson(),
            ))
        .toList();
    await dao.writeSerialised(entries);
    await _appMetaDao?.setActiveAccountKey(accountKey);
  }

  @override
  String toString() =>
      'WatcherEngine(running: $_running, watchers: ${_watchers.length})';
}
