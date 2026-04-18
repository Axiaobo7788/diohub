/// Recurring watcher that monitors for code scanning (SAST) alerts.
library;

import 'package:diohub/services/watchers/definitions/repo_alert_watcher.dart';
import 'package:diohub/services/watchers/serializable_watcher.dart';
import 'package:diohub/services/watchers/watcher_types.dart';

class CodeScanningWatcher extends RepoAlertWatcher {
  CodeScanningWatcher({
    required super.repoRef,
    super.interval = const Duration(hours: 6),
    super.enabled = true,
  });

  @override
  String get key => 'code_scanning';

  @override
  String get displayName =>
      'Code scanning in ${repoRef.owner}/${repoRef.name}';

  @override
  String get alertEndpoint => 'code-scanning/alerts';

  @override
  String get storageKey => '_last_code_alert_ids';

  @override
  AlertPayload mapAlert(Map<String, dynamic> alertMap, int alertId) {
    final severity = alertMap['rule']?['severity'] as String? ?? 'note';
    final ruleName = alertMap['rule']?['name'] as String? ?? 'Code issue';
    final description = alertMap['rule']?['description'] as String?;

    final icon = switch (severity) {
      'error' => '❗',
      'warning' => '⚠️',
      'note' => 'ℹ️',
      _ => '🔍',
    };

    final priority = switch (severity) {
      'error' => AlertPriority.high,
      'warning' => AlertPriority.normal,
      _ => AlertPriority.low,
    };

    return AlertPayload(
      id: 'code_scan:${repoRef.owner}/${repoRef.name}:$alertId',
      title: '$icon $ruleName',
      body: '${description ?? severity}\n${repoRef.owner}/${repoRef.name}',
      watcherKey: key,
      channels: const {
        AlertChannel.inAppToast,
        AlertChannel.systemNotification,
      },
      priority: priority,
      groupKey: 'security:${repoRef.owner}/${repoRef.name}',
      metadata: {
        'severity': severity,
        'alert_id': alertId.toString(),
        'rule': ruleName,
      },
      entityRef: repoRef,
    );
  }

  static CodeScanningWatcher fromJson(Map<String, dynamic> json) =>
      CodeScanningWatcher(
        repoRef: SerializableWatcher.deserializeRepoRef(json),
        interval: Duration(seconds: json['interval'] as int? ?? 21600),
        enabled: json['enabled'] as bool? ?? true,
      );
}
