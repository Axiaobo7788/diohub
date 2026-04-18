/// Template Method base class for repository security alert watchers.
///
/// Subclasses must provide:
/// - [alertEndpoint]: REST API endpoint relative to the repo
/// - [storageKey]: Key for storing last-seen alert IDs
/// - [mapAlert]: Transform raw alert JSON into an AlertPayload
library;

import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/server_config.dart';
import 'package:diohub/services/base/rest_pagination_helper.dart';
import 'package:diohub/services/watchers/serializable_watcher.dart';
import 'package:diohub/services/watchers/watcher_definition.dart';
import 'package:diohub/services/watchers/watcher_types.dart';

/// Base class for repo-scoped alert watchers (vulnerability, code scanning, secret scanning).
///
/// Implements Template Method pattern: subclasses fill in the slots for endpoint,
/// storage key, and alert mapping logic.
abstract class RepoAlertWatcher extends PollingWatcher with SerializableWatcher {
  RepoAlertWatcher({
    required this.repoRef,
    super.interval = const Duration(hours: 6),
    super.enabled = true,
  });

  final RepoRef repoRef;

  @override
  String get instanceId => '${repoRef.owner}/${repoRef.name}';

  @override
  Set<String> get requiredScopes => const {GitHubScope.securityEvents};

  /// REST API endpoint path relative to the repo (e.g., 'dependabot/alerts').
  String get alertEndpoint;

  /// Storage key for last-seen alert IDs (e.g., '_last_alert_ids').
  String get storageKey;

  /// Transform raw alert JSON into an AlertPayload.
  AlertPayload mapAlert(Map<String, dynamic> alertJson, int alertId);

  @override
  Future<List<AlertPayload>> fetchUpdates(
    WatcherContext ctx,
    DateTime? lastChecked,
  ) async {
    final response = await ctx.apiClient.get(
      '/repos/${repoRef.owner}/${repoRef.name}/$alertEndpoint',
      queryParameters: {
        'state': 'open',
        'per_page': 20,
      },
    );

    final alerts = extractListFromResponse<Object?>(response);
    if (alerts.isEmpty) return [];

    final lastSeenIds = await ctx.read<List<dynamic>?>(storageKey) ?? [];
    final lastSeenIdSet = lastSeenIds.cast<int>().toSet();

    final newAlerts = alerts.where((alert) {
      final alertMap = alert as Map<String, dynamic>;
      final id = alertMap['number'] as int;
      return !lastSeenIdSet.contains(id);
    }).toList();

    if (newAlerts.isEmpty) return [];

    final currentIds = alerts
        .map((a) => (a as Map<String, dynamic>)['number'] as int)
        .toList();
    await ctx.write(storageKey, currentIds);

    return newAlerts.map((alert) {
      final alertMap = alert as Map<String, dynamic>;
      final alertId = alertMap['number'] as int;
      return mapAlert(alertMap, alertId);
    }).toList();
  }

  @override
  Map<String, dynamic> toJson() =>
      SerializableWatcher.serializeRepoBase(
        key: key,
        repoRef: repoRef,
        interval: interval,
        enabled: enabled,
      );
}
