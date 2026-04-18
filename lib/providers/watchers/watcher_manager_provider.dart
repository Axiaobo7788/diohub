/// Riverpod providers for the watcher service and its reactive state.
library;

import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/settings/notifications_provider.dart';
import 'package:diohub/providers/watchers/alert_sink_impl.dart';
import 'package:diohub/services/watchers/background_watcher_service.dart';
import 'package:diohub/services/watchers/watcher_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:diohub/providers/database_providers.dart';

export 'package:diohub/services/watchers/watcher_service.dart'
    show WatcherStatus, WatcherManagerState;

/// Provider for the singleton [WatcherService].
///
/// This service owns the watcher engine and survives reactive rebuilds.
/// Dependencies are read once (not watched), so changes to apiClient or
/// accountKey do not rebuild the service.
final watcherServiceProvider = Provider<WatcherService>((ref) {
  final dao = ref.read(watcherDaoProvider);
  final accountKey = ref.read(activeAccountKeyProvider);
  final apiClient = ref.read(apiClientProvider);
  final appMetaDao = ref.read(appMetaDaoProvider);
  final notificationService = ref.read(notificationServiceProvider);
  final activeAccount = ref.read(accountProvider).value?.activeAccountModel;

  final service = WatcherService(
    watcherDao: dao,
    appMetaDao: appMetaDao,
    accountKey: accountKey,
    apiClient: apiClient,
    alertSink: AlertSinkImpl(
      notificationService: notificationService,
      getNavigationContext: () => null, // TODO: Wire navigation context
    ),
    isSystemNotificationsEnabled: () =>
        ref.read(notificationsProvider).systemNotificationsEnabled,
    grantedScopesFn: () => ref.read(scopeGateProvider).grantedScopes,
    activeAccount: activeAccount,
  );

  // Sync initial settings
  final settings = ref.read(notificationsProvider);
  service.syncSettings(settings);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Stream provider that exposes the watcher service state for UI to watch.
///
/// This allows UI to reactively rebuild when the watcher state changes,
/// without tearing down the engine.
final watcherStateProvider = StreamProvider<WatcherManagerState>((ref) {
  final service = ref.watch(watcherServiceProvider);
  return service.stateStream;
});

/// Backwards-compatible provider that mimics the old notifier API.
///
/// Returns the current state synchronously. UI should prefer watching
/// [watcherStateProvider] for reactive updates.
final watcherManagerProvider = Provider<WatcherManagerState>((ref) {
  final asyncState = ref.watch(watcherStateProvider);
  return asyncState.when(
    data: (state) => state,
    loading: () => const WatcherManagerState(),
    error: (_, __) => const WatcherManagerState(),
  );
});

/// Provider for BackgroundWatcherService singleton.
/// 
/// Manages background watcher execution and OS notifications.
/// Must be initialized in main() before using.
final backgroundWatcherServiceProvider = Provider<BackgroundWatcherService>((ref) {
  return BackgroundWatcherService.instance;
});
