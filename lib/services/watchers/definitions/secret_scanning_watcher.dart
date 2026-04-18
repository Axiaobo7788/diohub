/// Recurring watcher that monitors for secret scanning alerts.
library;

import 'package:diohub/services/watchers/definitions/repo_alert_watcher.dart';
import 'package:diohub/services/watchers/serializable_watcher.dart';
import 'package:diohub/services/watchers/watcher_types.dart';

class SecretScanningWatcher extends RepoAlertWatcher {
  SecretScanningWatcher({
    required super.repoRef,
    super.interval = const Duration(hours: 6),
    super.enabled = true,
  });

  @override
  String get key => 'secret_scanning';

  @override
  String get displayName =>
      'Secret scanning in ${repoRef.owner}/${repoRef.name}';

  @override
  String get alertEndpoint => 'secret-scanning/alerts';

  @override
  String get storageKey => '_last_secret_ids';

  @override
  AlertPayload mapAlert(Map<String, dynamic> alertMap, int alertId) {
    final secretType = alertMap['secret_type_display_name'] as String? ?? 'Secret';
    final location = alertMap['html_url'] as String?;

    return AlertPayload(
      id: 'secret_scan:${repoRef.owner}/${repoRef.name}:$alertId',
      title: '🔐 $secretType detected',
      body: '${repoRef.owner}/${repoRef.name}',
      watcherKey: key,
      channels: const {
        AlertChannel.inAppToast,
        AlertChannel.systemNotification,
      },
      priority: AlertPriority.high,
      groupKey: 'security:${repoRef.owner}/${repoRef.name}',
      metadata: {
        'secret_type': secretType,
        'alert_id': alertId.toString(),
        'location': location ?? '',
      },
      entityRef: repoRef,
    );
  }

  static SecretScanningWatcher fromJson(Map<String, dynamic> json) =>
      SecretScanningWatcher(
        repoRef: SerializableWatcher.deserializeRepoRef(json),
        interval: Duration(seconds: json['interval'] as int? ?? 21600),
        enabled: json['enabled'] as bool? ?? true,
      );
}
