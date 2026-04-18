/// Recurring watcher that monitors for new Personal Access Token (PAT) requests in an organization.
library;

import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/server_config.dart';
import 'package:diohub/services/base/rest_pagination_helper.dart';
import 'package:diohub/services/watchers/serializable_watcher.dart';
import 'package:diohub/services/watchers/watcher_definition.dart';
import 'package:diohub/services/watchers/watcher_types.dart';

class OrgPatRequestWatcher extends PollingWatcher with SerializableWatcher {
  OrgPatRequestWatcher({
    required this.orgLogin,
    super.interval = const Duration(hours: 1),
    super.enabled = true,
  });

  final String orgLogin;

  @override
  String get key => 'org_pat_request';
  @override
  String get instanceId => orgLogin;
  @override
  String get displayName => 'PAT requests for $orgLogin';

  @override
  Set<String> get requiredScopes => const {GitHubScope.adminOrg};

  @override
  Future<List<AlertPayload>> fetchUpdates(
    WatcherContext ctx,
    DateTime? lastChecked,
  ) async {
    final response = await ctx.apiClient.get(
      '/orgs/$orgLogin/personal-access-token-requests',
      queryParameters: {
        'state': 'pending',
        'per_page': 30,
      },
    );

    final requests = extractListFromResponse<Object?>(response);
    if (requests.isEmpty) return [];

    final lastSeenIds = await ctx.read<List<dynamic>?>('_last_pat_request_ids') ?? [];
    final lastSeenSet = lastSeenIds.cast<int>().toSet();

    // Seed run: store current request IDs and don't alert
    if (lastSeenIds.isEmpty) {
      final currentIds = requests
          .take(30)
          .map((r) => (r as Map<String, dynamic>)['id'] as int)
          .toList();
      await ctx.write('_last_pat_request_ids', currentIds);
      return [];
    }

    final newRequests = requests.where((request) {
      final requestMap = request as Map<String, dynamic>;
      final id = requestMap['id'] as int;
      return !lastSeenSet.contains(id);
    }).take(5).toList(); // Limit to 5 most recent

    if (newRequests.isEmpty) return [];

    final currentIds = requests
        .take(30)
        .map((r) => (r as Map<String, dynamic>)['id'] as int)
        .toList();
    await ctx.write('_last_pat_request_ids', currentIds);

    return newRequests.map((request) {
      final requestMap = request as Map<String, dynamic>;
      final id = requestMap['id'] as int;
      final owner = (requestMap['owner'] as Map<String, dynamic>?)?['login'] as String?;
      final repositoriesCount = requestMap['repositories_count'] as int? ?? 0;

      return AlertPayload(
        id: 'org_pat_request:$orgLogin:$id',
        title: '🔑 New PAT request from @${owner ?? 'unknown'}',
        body: 'Requesting access to $repositoriesCount repositories in $orgLogin',
        watcherKey: key,
        channels: const {
          AlertChannel.inAppToast,
          AlertChannel.systemNotification,
        },
        priority: AlertPriority.normal,
        groupKey: 'org:pat_requests:$orgLogin',
        metadata: {
          'request_id': id.toString(),
          'owner': owner ?? '',
          'org': orgLogin,
        },
        entityRef: UserRef(login: orgLogin),
      );
    }).toList();
  }

  @override
  Map<String, dynamic> toJson() => {
        'key': key,
        'orgLogin': orgLogin,
        'interval': interval.inSeconds,
        'enabled': enabled,
      };

  static OrgPatRequestWatcher fromJson(Map<String, dynamic> json) =>
      OrgPatRequestWatcher(
        orgLogin: json['orgLogin'] as String,
        interval: Duration(seconds: json['interval'] as int? ?? 3600),
        enabled: json['enabled'] as bool? ?? true,
      );
}
