import 'package:diohub/app/settings/settings_descriptor.dart';

/// Notifications settings: auto-mark read, group by repo, watcher options.
class NotificationsSettings {
  const NotificationsSettings({
    this.autoMarkRead = false,
    this.groupByRepo = false,
    this.cleanupPromptDismissed = false,
    this.inboxPollingEnabled = true,
    this.inboxPollingIntervalMinutes = 10,
    this.runCompletionAlerts = true,
    this.systemNotificationsEnabled = true,
    // Quiet hours
    this.quietHoursStart = -1,
    this.quietHoursEnd = -1,
    this.quietDays = const [],
  });

  factory NotificationsSettings.fromJson(
    final Map<String, dynamic> json,
  ) => NotificationsSettings(
    autoMarkRead: json['autoMarkRead'] as bool? ?? false,
    groupByRepo: json['groupByRepo'] as bool? ?? false,
    cleanupPromptDismissed: json['cleanupPromptDismissed'] as bool? ?? false,
    inboxPollingEnabled: json['inboxPollingEnabled'] as bool? ?? true,
    inboxPollingIntervalMinutes:
        json['inboxPollingIntervalMinutes'] as int? ?? 10,
    runCompletionAlerts: json['runCompletionAlerts'] as bool? ?? true,
    systemNotificationsEnabled:
        json['systemNotificationsEnabled'] as bool? ?? true,
    quietHoursStart: json['quietHoursStart'] as int? ?? -1,
    quietHoursEnd: json['quietHoursEnd'] as int? ?? -1,
    quietDays:
        (json['quietDays'] as List<dynamic>?)?.map((e) => e as int).toList() ??
        const [],
  );

  final bool autoMarkRead;
  final bool groupByRepo;
  final bool cleanupPromptDismissed;
  final bool inboxPollingEnabled;
  final int inboxPollingIntervalMinutes;
  final bool runCompletionAlerts;
  final bool systemNotificationsEnabled;

  // Quiet hours: -1 = disabled, 0-23 = hour of day
  final int quietHoursStart;
  final int quietHoursEnd;
  // Quiet days: 0=Monday, 6=Sunday, empty list = no quiet days
  final List<int> quietDays;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'autoMarkRead': autoMarkRead,
    'groupByRepo': groupByRepo,
    'cleanupPromptDismissed': cleanupPromptDismissed,
    'inboxPollingEnabled': inboxPollingEnabled,
    'inboxPollingIntervalMinutes': inboxPollingIntervalMinutes,
    'runCompletionAlerts': runCompletionAlerts,
    'systemNotificationsEnabled': systemNotificationsEnabled,
    'quietHoursStart': quietHoursStart,
    'quietHoursEnd': quietHoursEnd,
    'quietDays': quietDays,
  };

  NotificationsSettings copyWith({
    final bool? autoMarkRead,
    final bool? groupByRepo,
    final bool? cleanupPromptDismissed,
    final bool? inboxPollingEnabled,
    final int? inboxPollingIntervalMinutes,
    final bool? runCompletionAlerts,
    final bool? systemNotificationsEnabled,
    final int? quietHoursStart,
    final int? quietHoursEnd,
    final List<int>? quietDays,
  }) => NotificationsSettings(
    autoMarkRead: autoMarkRead ?? this.autoMarkRead,
    groupByRepo: groupByRepo ?? this.groupByRepo,
    cleanupPromptDismissed:
        cleanupPromptDismissed ?? this.cleanupPromptDismissed,
    inboxPollingEnabled: inboxPollingEnabled ?? this.inboxPollingEnabled,
    inboxPollingIntervalMinutes:
        inboxPollingIntervalMinutes ?? this.inboxPollingIntervalMinutes,
    runCompletionAlerts: runCompletionAlerts ?? this.runCompletionAlerts,
    systemNotificationsEnabled:
        systemNotificationsEnabled ?? this.systemNotificationsEnabled,
    quietHoursStart: quietHoursStart ?? this.quietHoursStart,
    quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    quietDays: quietDays ?? this.quietDays,
  );
}

Map<String, dynamic> _notificationsToJson(final NotificationsSettings v) =>
    v.toJson();

const SettingsDescriptor<NotificationsSettings> notificationsDescriptor =
    SettingsDescriptor<NotificationsSettings>(
      key: 'app_notifications',
      defaultValue: NotificationsSettings(),
      fromJson: NotificationsSettings.fromJson,
      toJson: _notificationsToJson,
    );
