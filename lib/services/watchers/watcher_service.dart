/// Singleton service that manages the watcher engine lifecycle.
///
/// This is a plain Dart class (not a Riverpod Notifier) that wraps [WatcherEngine]
/// and provides an imperative API. It survives reactive rebuilds and is created once
/// in main(). Settings and API client changes are pushed in imperatively, not via
/// reactive dependencies.
library;

import 'dart:async';
import 'dart:developer' as dev;

import 'package:diohub/app/settings/notifications.dart';
import 'package:diohub_database/database/database.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:diohub/services/watchers/alert_dispatcher.dart';
import 'package:diohub/services/watchers/definitions/inbox_poll_watcher.dart';
import 'package:diohub/services/watchers/definitions/run_status_watcher.dart';
import 'package:diohub/services/watchers/watcher_context_impl.dart';
import 'package:diohub/services/watchers/watcher_definition.dart';
import 'package:diohub/services/watchers/watcher_engine.dart';
import 'package:diohub/services/watchers/watcher_registration.dart';
import 'package:diohub/services/watchers/watcher_types.dart';
import 'package:flutter/foundation.dart';

/// State snapshot for the watcher UI.
@immutable
class WatcherStatus {
  const WatcherStatus({
    required this.watcher,
    required this.lastCheckTime,
    required this.lastResult,
    this.entityRef,
  });

  final WatcherDefinition watcher;
  final DateTime? lastCheckTime;
  final CheckResult? lastResult;
  final EntityRef? entityRef;

  /// True if this watcher is a run-status (workflow run) watcher; used by UI for Remove vs Pause.
  bool get isRunWatcher => watcher is RunStatusWatcher;
}

/// State snapshot for the watcher management UI.
@immutable
class WatcherManagerState {
  const WatcherManagerState({
    this.watchers = const [],
    this.recentAlerts = const [],
    this.isRunning = false,
  });

  final List<WatcherStatus> watchers;
  final List<AlertPayload> recentAlerts;
  final bool isRunning;

  WatcherManagerState copyWith({
    List<WatcherStatus>? watchers,
    List<AlertPayload>? recentAlerts,
    bool? isRunning,
  }) =>
      WatcherManagerState(
        watchers: watchers ?? this.watchers,
        recentAlerts: recentAlerts ?? this.recentAlerts,
        isRunning: isRunning ?? this.isRunning,
      );
}

/// Singleton service that owns the watcher engine lifecycle.
///
/// Created once in a Riverpod Provider. Never torn down except on logout.
/// All state changes are pushed imperatively (not via reactive dependencies).
class WatcherService {
  WatcherService({
    required WatcherDao watcherDao,
    required AppMetaDao appMetaDao,
    required String accountKey,
    required ApiClient apiClient,
    required AlertSink alertSink,
    required bool Function() isSystemNotificationsEnabled,
    required Set<String> Function() grantedScopesFn,
    AccountModel? activeAccount,
  })  : _watcherDao = watcherDao,
        _appMetaDao = appMetaDao,
        _accountKey = accountKey,
        _apiClient = apiClient,
        _recentAlerts = [] {
    final delegateDispatcher = createAlertDispatcher(
      sink: alertSink,
      isSystemNotificationsEnabled: isSystemNotificationsEnabled,
    );

    _engine = WatcherEngine(
      dispatcher: (alerts) async {
        for (final a in alerts) _addRecentAlert(a);
        await delegateDispatcher(alerts);
      },
      onError: (w, e, s) => dev.log('Watcher error: $w $e', name: 'WatcherService'),
      watcherDao: _watcherDao,
      accountKey: _accountKey,
      appMetaDao: _appMetaDao,
      apiClient: _apiClient,
      grantedScopesFn: grantedScopesFn,
      contextFactory: (watcher) => DriftWatcherContext(
        _watcherDao,
        watcher.watcherId,
        watcher.key,
        _apiClient,
      ),
    );

    // Persist storage key and server config for background isolate
    if (activeAccount != null) {
      _persistBackgroundCredentials(activeAccount);
    }

    // Register watcher factories once
    registerAllWatcherFactories();

    // Listen to engine events and emit state changes
    _engineSubscription = _engine.events.listen((_) => _emitState());
  }

  void _persistBackgroundCredentials(AccountModel account) {
    // Fire and forget - background access metadata
    Future(() async {
      await _appMetaDao.setValue('_active_storage_key', account.storageKey);
      await _appMetaDao.setValue('_active_server_config_id', account.serverConfig.id);
      await _appMetaDao.setValue('_active_server_rest_base_url', account.serverConfig.restBaseUrl);
      await _appMetaDao.setValue('_active_account_scope', account.scope ?? '');
    });
  }

  final WatcherDao _watcherDao;
  final AppMetaDao _appMetaDao;
  final String _accountKey;
  ApiClient _apiClient;

  late final WatcherEngine _engine;
  late final StreamSubscription<WatcherEvent> _engineSubscription;

  final List<AlertPayload> _recentAlerts;
  static const int _maxRecentAlerts = 20;

  bool _started = false;

  final StreamController<WatcherManagerState> _stateController =
      StreamController<WatcherManagerState>.broadcast();

  /// Stream of state changes for the UI to watch.
  Stream<WatcherManagerState> get stateStream => _stateController.stream;

  /// Current state snapshot.
  WatcherManagerState get state => _buildState();

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Start the watcher engine. Idempotent.
  void start() {
    if (_started) return;
    _started = true;
    _engine.start();
    _emitState();
  }

  /// Stop the watcher engine but keep watchers registered.
  void stop() {
    if (!_started) return;
    _engine.stop();
    _emitState();
  }

  /// Pause the engine (called on app backgrounding).
  void pause() {
    if (!_started) return;
    _engine.stop();
    _emitState();
  }

  /// Resume the engine (called on app foregrounding).
  void resume() {
    if (!_started) return;
    _engine.start();
    _emitState();
  }

  /// Dispose the service. Call on logout.
  Future<void> dispose() async {
    await _engineSubscription.cancel();
    await _engine.dispose();
    await _stateController.close();
  }

  // ── Watcher Management ─────────────────────────────────────────────────────

  /// Register a run status watcher.
  void registerRunWatcher({
    required String owner,
    required String repoName,
    required int runId,
    String? runName,
  }) {
    final runRef = WorkflowRunRef(
      repo: RepoRef(owner: owner, name: repoName),
      runId: runId,
    );
    _engine.register(RunStatusWatcher(
      runRef: runRef,
      runName: runName,
    ));
    _emitState();
  }

  /// Register any watcher definition.
  void registerWatcher(WatcherDefinition watcher) {
    _engine.register(watcher);
    _emitState();
  }

  /// Remove a watcher by ID.
  Future<void> removeWatcher(String watcherId) async {
    final w = _engine.getWatcher(watcherId);
    if (w != null) await _engine.unregister(w);
    _emitState();
  }

  /// Toggle a watcher's enabled state.
  void toggleWatcher(String watcherId, {required bool enabled}) {
    final w = _engine.getWatcher(watcherId);
    if (w == null) return;
    final updated = _rebuildWithEnabled(w, enabled);
    if (updated != null) _engine.update(updated);
    _emitState();
  }

  /// Manually trigger a watcher check.
  Future<void> checkNow(String watcherId) async {
    await _engine.checkNow(watcherId);
    _emitState();
  }

  // ── Settings Sync ──────────────────────────────────────────────────────────

  /// Sync the engine with notification settings.
  ///
  /// Call this when notification settings change. It updates the inbox poll
  /// watcher without rebuilding the entire engine.
  Future<void> syncSettings(NotificationsSettings settings) async {
    const inboxWatcherId = 'inbox_poll:default';
    final existing = _engine.getWatcher(inboxWatcherId);

    if (settings.inboxPollingEnabled) {
      final watcher = InboxPollWatcher(
        interval: Duration(minutes: settings.inboxPollingIntervalMinutes),
      );
      if (existing != null) {
        await _engine.unregister(existing);
      }
      _engine.register(watcher);
    } else if (existing != null) {
      await _engine.unregister(existing);
    }
    _emitState();
  }

  /// Update the API client (e.g., after token refresh or account switch).
  void updateApiClient(ApiClient apiClient) {
    _apiClient = apiClient;
    // Contexts are created lazily and will use the new client on next check
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  WatcherManagerState _buildState() {
    final statuses = _engine.watchers.map((w) {
      EntityRef? entityRef;
      if (w is RunStatusWatcher) {
        entityRef = w.runRef;
      }
      return WatcherStatus(
        watcher: w,
        lastCheckTime: _engine.lastCheckTime(w.watcherId),
        lastResult: _engine.lastResult(w.watcherId),
        entityRef: entityRef,
      );
    }).toList();

    return WatcherManagerState(
      watchers: statuses,
      recentAlerts: List<AlertPayload>.from(_recentAlerts),
      isRunning: _engine.isRunning,
    );
  }

  void _emitState() {
    _stateController.add(_buildState());
  }

  void _addRecentAlert(AlertPayload alert) {
    _recentAlerts.insert(0, alert);
    if (_recentAlerts.length > _maxRecentAlerts) {
      _recentAlerts.removeLast();
    }
  }

  WatcherDefinition? _rebuildWithEnabled(WatcherDefinition w, bool enabled) {
    if (w is InboxPollWatcher) {
      return InboxPollWatcher(
        interval: w.interval,
        enabled: enabled,
      );
    }
    if (w is RunStatusWatcher) {
      return RunStatusWatcher(
        runRef: w.runRef,
        runName: w.runName,
        interval: w.interval,
        enabled: enabled,
      );
    }
    return null;
  }
}
