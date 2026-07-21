/// Background execution and OS notifications for watchers.
///
/// Initializes [FlutterLocalNotificationsPlugin] and [Workmanager], runs
/// serialised watchers in the background isolate, and shows system notifications.
library;

import 'dart:developer' as dev;
import 'dart:ui';

import 'package:diohub_database/database/database.dart';
import 'package:diohub/services/authentication/scope_gate.dart';
import 'package:diohub/services/authentication/token_store.dart';
import 'package:diohub/services/base/base_service.dart' show WatcherApiClient;
import 'package:diohub/services/watchers/background_api_client.dart';
import 'package:diohub/services/watchers/serializable_watcher.dart';
import 'package:diohub/services/watchers/watcher_registration.dart';
import 'package:diohub/services/watchers/watcher_context_impl.dart';
import 'package:diohub/services/watchers/watcher_types.dart';
import 'package:diohub/utils/json_decode_safe.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

/// Background task name passed to the callback.
const String _taskName = 'watcherPoll';

/// Unique name for the periodic task (iOS uses this as BGTaskScheduler identifier).
const String _uniqueName = 'watcher_poll';

/// Cloud sync periodic task. Handler is no-op until API is available in isolate.
const String _cloudSyncTaskName = 'cloudSync';
const String _cloudSyncUniqueName = 'diohub_cloud_sync';

class BackgroundWatcherService {
  BackgroundWatcherService._();

  static final BackgroundWatcherService instance = BackgroundWatcherService._();

  static FlutterLocalNotificationsPlugin? _notifPlugin;
  static void Function(Uri)? _setPendingDeepLink;

  /// Call once in main() before runApp (after AppDatabase.initialize).
  /// [setPendingDeepLink] is invoked when a notification is tapped; app layer sets pending deep link state.
  Future<void> initialize(void Function(Uri) setPendingDeepLink) async {
    _setPendingDeepLink = setPendingDeepLink;
    _notifPlugin = FlutterLocalNotificationsPlugin();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    await _notifPlugin!.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _createChannels();

    try {
      await Workmanager().initialize(_backgroundEntry, isInDebugMode: false);
      await Workmanager().registerPeriodicTask(
        _uniqueName,
        _taskName,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(networkType: NetworkType.connected),
      );
      await Workmanager().registerPeriodicTask(
        _cloudSyncUniqueName,
        _cloudSyncTaskName,
        frequency: const Duration(hours: 6),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      );
    } on Exception catch (e, st) {
      // Workmanager may not be available on all platforms (e.g. iOS simulator).
      // Log and continue so the app still launches.
      dev.log(
        'Workmanager init failed (non-fatal): $e',
        name: 'BackgroundWatcherService',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Show a system notification from an [AlertPayload].
  Future<void> showSystemNotification(AlertPayload alert) async {
    if (_notifPlugin == null) return;

    final androidDetails = AndroidNotificationDetails(
      alert.groupKey ?? alert.watcherKey,
      _channelName(alert.watcherKey),
      channelDescription: alert.watcherKey,
      importance: _importance(alert.priority),
      priority: _androidPriority(alert.priority),
      groupKey: alert.groupKey,
    );
    final iosDetails = DarwinNotificationDetails(
      threadIdentifier: alert.groupKey ?? alert.watcherKey,
      interruptionLevel: _interruptionLevel(alert.priority),
    );
    await _notifPlugin!.show(
      id: alert.id.hashCode & 0x7FFFFFFF,
      title: alert.title,
      body: alert.body,
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: alert.entityRef?.webUrl.toString(),
    );
  }

  @pragma('vm:entry-point')
  static void _backgroundEntry() {
    Workmanager().executeTask((taskName, inputData) async {
      if (taskName == _cloudSyncTaskName) {
        // Run cloud sync in background when API/token available in isolate.
        return true;
      }
      if (taskName != _taskName) return true;

      // CRITICAL: Register Flutter plugins before accessing secure storage
      try {
        // ignore: depend_on_referenced_packages
        DartPluginRegistrant.ensureInitialized();
      } catch (e) {
        dev.log(
          'Plugin registration failed (DartPluginRegistrant not available)',
          name: 'BackgroundWatcherService',
          error: e,
        );
        // Continue anyway - may work on some platforms
      }

      final db = await AppDatabase.openForBackground();
      final dao = db.watcherDao;
      final settingsDao = db.settingsDao;
      final appMetaDao = db.appMetaDao;

      final raw = await settingsDao.getValue('app_notifications');
      bool systemNotifs = true;
      if (raw != null) {
        final envelope = tryDecodeMap(raw, tag: 'BackgroundWatcherService');
        if (envelope != null) {
          final dataStr = envelope['data'] as String?;
          final data = tryDecodeMap(dataStr, tag: 'BackgroundWatcherService');
          systemNotifs = data?['systemNotificationsEnabled'] as bool? ?? true;
        }
      }

      // The watcher registry and active account key are written by the
      // foreground WatcherManager. If it has never been built, these will
      // be empty and the background task exits early.
      final accountKey = await appMetaDao.getActiveAccountKey();
      if (accountKey == null || accountKey.isEmpty) return true;

      // Read account scope for watcher gating
      final scopeString = await appMetaDao.getValue('_active_account_scope');
      final grantedScopes = ScopeGate.parseScopes(scopeString);

      // Read storage key and server config for background API access
      final storageKey = await appMetaDao.getValue('_active_storage_key');
      final restBaseUrl = await appMetaDao.getValue(
        '_active_server_rest_base_url',
      );

      WatcherApiClient? apiClient;
      if (storageKey != null && restBaseUrl != null) {
        try {
          // Access token from secure storage (now accessible via first_unlock)
          final tokenStore = TokenStore();
          final token = await tokenStore.read('accessToken_$storageKey');

          if (token != null && token.isNotEmpty) {
            // Create background API client
            final BackgroundApiClient bgClient = BackgroundApiClient(
              token: token,
              baseUrl: restBaseUrl,
            );
            apiClient = bgClient;
          } else {
            dev.log(
              'No token found for storage key $storageKey',
              name: 'BackgroundWatcherService',
            );
          }
        } catch (e, s) {
          dev.log(
            'Failed to access token in background: $e',
            name: 'BackgroundWatcherService',
            error: e,
            stackTrace: s,
          );
        }
      }

      _registerFactories();
      final list = await dao.readAllSerialised();
      if (list.isEmpty) return true;

      final watcherDao = WatcherDao(db, accountKey);

      for (final entry in list) {
        try {
          final map = entry;
          final watcher = WatcherFactory.fromJson(map);
          if (watcher == null || !watcher.enabled) continue;

          // Scope gate: skip if required scopes aren't granted
          if (watcher.requiredScopes.isNotEmpty &&
              !watcher.requiredScopes.every(grantedScopes.contains))
            continue;

          if (apiClient == null) continue;

          final ctx = DriftWatcherContext(
            watcherDao,
            watcher.watcherId,
            watcher.key,
            apiClient,
          );
          final result = await watcher.check(ctx);

          switch (result) {
            case CheckFired(:final alerts):
            case CheckDone(finalAlerts: final alerts):
              for (final alert in alerts) {
                if (systemNotifs &&
                    alert.channels.contains(AlertChannel.systemNotification)) {
                  await BackgroundWatcherService.instance
                      .showSystemNotification(alert);
                }
              }
            default:
              break;
          }
        } catch (e, s) {
          dev.log(
            'Background watcher error: $e',
            name: 'BackgroundWatcherService',
            error: e,
            stackTrace: s,
          );
        }
      }
      return true;
    });
  }

  static void _registerFactories() {
    registerAllWatcherFactories();
  }

  static Future<void> _createChannels() async {
    if (_notifPlugin == null) return;
    final androidPlugin = _notifPlugin!
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return;

    // Core channels
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'inbox_poll',
        'GitHub Inbox',
        description: 'New notification alerts from your GitHub inbox',
        importance: Importance.defaultImportance,
      ),
    );
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'run_status',
        'Workflow Runs',
        description: 'Workflow run completion status',
        importance: Importance.defaultImportance,
      ),
    );

    // PR & Issue Status channels
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'pr_merge_status',
        'Pull Request Merge Status',
        description: 'Pull request mergeable state changes',
        importance: Importance.defaultImportance,
      ),
    );
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'pr_review_decision',
        'Pull Request Reviews',
        description: 'Pull request review decision changes',
        importance: Importance.defaultImportance,
      ),
    );
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'issue_state',
        'Issue State',
        description: 'Issue open/close status changes',
        importance: Importance.defaultImportance,
      ),
    );

    // Release & Deployment channels
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'release',
        'Releases',
        description: 'New releases published in watched repositories',
        importance: Importance.defaultImportance,
      ),
    );
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'deployment_status',
        'Deployment Status',
        description: 'Deployment status updates',
        importance: Importance.high,
      ),
    );
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'pending_deployment',
        'Deployment Approvals',
        description: 'Pending deployment approval requests',
        importance: Importance.high,
      ),
    );

    // Security channels
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'vulnerability_alert',
        'Security Vulnerabilities',
        description: 'Dependabot vulnerability alerts',
        importance: Importance.high,
      ),
    );
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'secret_scanning',
        'Secret Scanning',
        description: 'Exposed secrets detected in code',
        importance: Importance.high,
      ),
    );
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'code_scanning',
        'Code Scanning',
        description: 'Static analysis security alerts',
        importance: Importance.defaultImportance,
      ),
    );

    // Social channels
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'star_count',
        'Star Milestones',
        description: 'Repository star count milestones',
        importance: Importance.low,
      ),
    );
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'follower',
        'New Followers',
        description: 'New followers on your account',
        importance: Importance.low,
      ),
    );
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'milestone_progress',
        'Milestone Progress',
        description: 'Milestone completion progress',
        importance: Importance.defaultImportance,
      ),
    );

    // CI/CD channels
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'branch_run',
        'Branch CI',
        description: 'CI status for watched branches',
        importance: Importance.defaultImportance,
      ),
    );
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'scheduled_workflow',
        'Scheduled Workflows',
        description: 'Scheduled workflow run results',
        importance: Importance.low,
      ),
    );

    // Discussion channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'discussion_answer',
        'Discussion Answers',
        description: 'Answers to your discussions',
        importance: Importance.high,
      ),
    );
  }

  static String _channelName(String watcherKey) => switch (watcherKey) {
    'inbox_poll' => 'GitHub Inbox',
    'run_status' => 'Workflow Runs',
    'pr_merge_status' => 'Pull Request Merge Status',
    'pr_review_decision' => 'Pull Request Reviews',
    'issue_state' => 'Issue State',
    'release' => 'Releases',
    'deployment_status' => 'Deployment Status',
    'pending_deployment' => 'Deployment Approvals',
    'vulnerability_alert' => 'Security Vulnerabilities',
    'secret_scanning' => 'Secret Scanning',
    'code_scanning' => 'Code Scanning',
    'star_count' => 'Star Milestones',
    'follower' => 'New Followers',
    'milestone_progress' => 'Milestone Progress',
    'branch_run' => 'Branch CI',
    'scheduled_workflow' => 'Scheduled Workflows',
    'discussion_answer' => 'Discussion Answers',
    _ => 'Watchers',
  };

  static Importance _importance(AlertPriority p) => switch (p) {
    AlertPriority.high => Importance.high,
    AlertPriority.low => Importance.low,
    AlertPriority.normal => Importance.defaultImportance,
  };

  static Priority _androidPriority(AlertPriority p) => switch (p) {
    AlertPriority.high => Priority.high,
    AlertPriority.low => Priority.low,
    AlertPriority.normal => Priority.defaultPriority,
  };

  static InterruptionLevel _interruptionLevel(AlertPriority p) => switch (p) {
    AlertPriority.high => InterruptionLevel.timeSensitive,
    AlertPriority.low => InterruptionLevel.passive,
    AlertPriority.normal => InterruptionLevel.active,
  };

  static void _onNotificationTapped(NotificationResponse? response) {
    final payload = response?.payload;
    if (payload != null && payload.isNotEmpty) {
      _setPendingDeepLink?.call(Uri.parse(payload));
    }
  }
}
