import 'dart:async';

import 'package:diohub/app/app_logger.dart';
import 'package:diohub/app/settings/notifications.dart';
import 'package:diohub/app/settings/settings_descriptor.dart';
import 'package:diohub/common/riverpod/persisted_notifier.dart';
import 'package:diohub/providers/watchers/watcher_manager_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final NotifierProvider<NotificationsNotifier, NotificationsSettings>
    notificationsProvider =
    NotifierProvider<NotificationsNotifier, NotificationsSettings>(
  NotificationsNotifier.new,
);

class NotificationsNotifier extends Notifier<NotificationsSettings>
    with PersistedNotifier<NotificationsSettings> {
  @override
  SettingsDescriptor<NotificationsSettings> get descriptor =>
      notificationsDescriptor;

  Future<void> _syncWatcherManager() async {
    try {
      final service = ref.read(watcherServiceProvider);
      await service.syncSettings(state);
    } catch (e, st) {
      AppLogger.warning(
        'WatcherService sync failed (may not be built yet)',
        error: e,
        stackTrace: st,
        tag: 'NotificationsNotifier',
      );
    }
  }

  Future<void> updateInboxPollingEnabled(final bool value) async {
    await update((final NotificationsSettings s) =>
        s.copyWith(inboxPollingEnabled: value));
    unawaited(_syncWatcherManager());
  }

  Future<void> updateInboxPollingInterval(final int minutes) async {
    await update((final NotificationsSettings s) =>
        s.copyWith(inboxPollingIntervalMinutes: minutes));
    unawaited(_syncWatcherManager());
  }
}
