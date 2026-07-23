import 'package:dio/dio.dart';
import 'package:diohub/app/app_logger.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub_graphql/schema.graphql.dart';
import 'package:diohub_graphql/queries/repositories/security_mutations.graphql.dart';
import 'package:diohub_graphql/queries/repositories/vulnerability_alerts.graphql.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub_models/models/repositories/code_frequency_entry.dart';
import 'package:diohub_models/models/repositories/code_scanning_alert_item.dart';
import 'package:diohub_models/models/repositories/commit_activity_entry.dart';
import 'package:diohub_models/models/repositories/contributor_stat.dart';
import 'package:diohub_models/models/repositories/participation_response.dart';
import 'package:diohub_models/models/repositories/punch_card_entry.dart';
import 'package:diohub_models/models/repositories/traffic_clones.dart';
import 'package:diohub_models/models/repositories/traffic_path.dart';
import 'package:diohub_models/models/repositories/traffic_period.dart';
import 'package:diohub_models/models/repositories/traffic_referrer.dart';
import 'package:diohub_models/models/repositories/traffic_views.dart';
import 'package:diohub_models/models/repositories/vulnerability_alert_item.dart';
import 'package:diohub_models/models/repositories/vulnerability_alerts_result.dart';
import 'package:diohub_models/models/repositories/vulnerability_alert_dismiss_result.dart';
import 'package:diohub/app/api_handler/dio.dart' show GQLResponse;
import 'package:diohub/services/base/base_service.dart';
import 'package:diohub/services/base/rest_pagination_helper.dart';
import 'package:lens_annotations/lens_annotations.dart';

/// Traffic, stats, and security insights for a repository.
@LensService(scope: Scope.repo, group: 'repo')
class RepoStatsService extends EntityService<RepoRef> {
  RepoStatsService(super.apiClient, super.ref);

  /// REST GET /repos/{o}/{r}/traffic/views.
  /// [per] — time frame for last 14 days (default [TrafficPeriod.day]).
  @Lens(
    'get_traffic_views',
    'Get repository traffic views for the last 14 days.',
    category: ToolCategory.stats,
    access: ToolAccess.read,
  )
  Future<TrafficViewsResponse> getTrafficViews({
    @Skip() final bool refresh = false,
    @Desc('Time period: day or week')
    final TrafficPeriod per = TrafficPeriod.day,
  }) async {
    final Response<Map<String, dynamic>> res = await rest
        .get<Map<String, dynamic>>(
          '${ref.apiPath}/traffic/views',
          queryParameters: <String, dynamic>{'per': per.apiValue},
          refreshCache: refresh,
        );
    return TrafficViewsResponse.fromJson(res.data ?? <String, dynamic>{});
  }

  /// REST GET /repos/{o}/{r}/traffic/clones.
  /// [per] — time frame for last 14 days (default [TrafficPeriod.day]).
  @Lens(
    'get_traffic_clones',
    'Get repository clone statistics for the last 14 days.',
    category: ToolCategory.stats,
    access: ToolAccess.read,
  )
  Future<TrafficClonesResponse> getTrafficClones({
    @Skip() final bool refresh = false,
    @Desc('Time period: day or week')
    final TrafficPeriod per = TrafficPeriod.day,
  }) async {
    final Response<Map<String, dynamic>> res = await rest
        .get<Map<String, dynamic>>(
          '${ref.apiPath}/traffic/clones',
          queryParameters: <String, dynamic>{'per': per.apiValue},
          refreshCache: refresh,
        );
    return TrafficClonesResponse.fromJson(res.data ?? <String, dynamic>{});
  }

  /// REST GET /repos/{o}/{r}/stats/contributors.
  @Lens(
    'get_contributors_stats',
    'Get contributor statistics for the repository.',
    category: ToolCategory.stats,
    access: ToolAccess.read,
  )
  Future<List<ContributorStat>> getStatsContributors({
    @Skip() final bool refresh = false,
  }) async {
    final Response<dynamic> res = await rest.get<dynamic>(
      '${ref.apiPath}/stats/contributors',
      refreshCache: refresh,
    );
    final List<Object?> raw = extractListFromResponse<Object?>(res);
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ContributorStat.fromJson)
        .toList();
  }

  /// REST GET /repos/{o}/{r}/stats/commit_activity (52 weeks).
  @Lens(
    'get_commit_activity',
    'Get 52 weeks of commit activity stats.',
    category: ToolCategory.stats,
    access: ToolAccess.read,
  )
  Future<List<CommitActivityEntry>> getCommitActivity({
    @Skip() final bool refresh = false,
  }) async {
    final Response<dynamic> res = await rest.get<dynamic>(
      '${ref.apiPath}/stats/commit_activity',
      refreshCache: refresh,
    );
    final List<Object?> raw = extractListFromResponse<Object?>(res);
    return raw
        .whereType<Map<String, dynamic>>()
        .map(CommitActivityEntry.fromJson)
        .toList();
  }

  /// REST GET /repos/{o}/{r}/stats/code_frequency.
  @Lens(
    'get_code_frequency',
    'Get weekly additions and deletions stats.',
    category: ToolCategory.stats,
    access: ToolAccess.read,
  )
  Future<List<CodeFrequencyEntry>> getCodeFrequency({
    @Skip() final bool refresh = false,
  }) async {
    final Response<dynamic> res = await rest.get<dynamic>(
      '${ref.apiPath}/stats/code_frequency',
      refreshCache: refresh,
    );
    final List<Object?> raw = extractListFromResponse<Object?>(res);
    return raw
        .whereType<List<dynamic>>()
        .map(CodeFrequencyEntry.fromList)
        .toList();
  }

  /// Vulnerability alerts (GQL). Returns edges for cursor-based pagination.
  @Lens(
    'list_vulnerability_alerts',
    'List repository Dependabot vulnerability alerts.',
    category: ToolCategory.security,
    access: ToolAccess.read,
  )
  Future<VulnerabilityAlertsResult> fetchVulnerabilityAlerts({
    @Desc('Number of results') required final int first,
    @Desc('Pagination cursor') final String? after,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerygetVulnerabilityAlerts,
      Variables$Query$getVulnerabilityAlerts(
        owner: ref.owner,
        repo: ref.name,
        first: first,
        after: after,
      ).toJson(),
    );
    final data = res.data == null
        ? null
        : Query$getVulnerabilityAlerts.fromJson(
            Map<String, dynamic>.from(res.data as Map),
          );
    if (data == null) {
      return const VulnerabilityAlertsResult(
        items: <VulnerabilityAlertEdge>[],
        hasNextPage: false,
        endCursor: null,
      );
    }
    final connection = data.repository?.vulnerabilityAlerts;
    final rawEdges =
        connection?.edges?.toList() ??
        const <
          Query$getVulnerabilityAlerts$repository$vulnerabilityAlerts$edges?
        >[];
    final List<VulnerabilityAlertEdge> edges = rawEdges
        .where((final e) => e?.node != null)
        .map((final e) {
          final n = e!.node!;
          final sv = n.securityVulnerability;
          final dismisserInfo = n.dismisser != null
              ? (n.dismisser!.login, n.dismisser!.avatarUrl.toString())
              : null;
          return VulnerabilityAlertEdge(
            cursor: e.cursor,
            node: VulnerabilityAlertItem(
              id: n.id,
              packageName: sv?.package.name ?? '',
              ecosystem: sv?.package.ecosystem.name ?? '',
              severity: sv?.severity.name ?? 'unknown',
              summary: sv?.advisory.summary,
              vulnerableVersionRange: sv?.vulnerableVersionRange,
              firstPatchedVersion: sv?.firstPatchedVersion?.identifier,
              permalink: sv?.advisory.permalink?.toString(),
              advisoryId: sv?.advisory.ghsaId,
              cvssScore: sv?.advisory.cvss.score,
              state: n.state.name,
              dismissedAt: n.dismissedAt,
              dismissReason: n.dismissReason,
              dismisserLogin: dismisserInfo?.$1,
              dismisserAvatarUrl: dismisserInfo?.$2,
            ),
          );
        })
        .toList();
    return VulnerabilityAlertsResult(
      items: edges,
      hasNextPage: connection?.pageInfo.hasNextPage ?? false,
      endCursor: connection?.pageInfo.endCursor,
    );
  }

  /// Dismiss a vulnerability alert. [reason] must be a [DismissReason] enum name
  /// (e.g. FIX_STARTED, NO_BANDWIDTH). Returns the updated alert payload for local patching, or null on error.
  @Skip()
  Future<VulnerabilityAlertDismissResult?> dismissVulnerabilityAlert({
    @Desc('Vulnerability alert ID') required final String alertId,
    @Desc('Dismiss reason (e.g. FIX_STARTED, NO_BANDWIDTH)')
    required final String reason,
  }) async {
    final Enum$DismissReason reasonEnum;
    try {
      reasonEnum = Enum$DismissReason.fromJson(reason);
    } on Object catch (e, st) {
      AppLogger.warning(
        'Invalid dismiss reason for vulnerability alert',
        error: e,
        stackTrace: st,
        tag: 'RepoStatsService',
      );
      return null;
    }
    final GQLResponse res = await gql.mutation(
      documentNodeMutationdismissVulnerabilityAlert,
      Variables$Mutation$dismissVulnerabilityAlert(
        alertId: alertId,
        reason: reasonEnum,
      ).toJson(),
    );
    final data = Mutation$dismissVulnerabilityAlert.fromJson(res.data!);
    final alert =
        data.dismissRepositoryVulnerabilityAlert?.repositoryVulnerabilityAlert;
    if (alert == null) return null;
    final dismisser = alert.dismisser;
    final dismisserLogin = dismisser?.login;
    final dismisserAvatarUrl = dismisser?.avatarUrl.toString();
    return VulnerabilityAlertDismissResult(
      id: alert.id,
      state: alert.state.name,
      dismissedAt: alert.dismissedAt,
      dismissReason: alert.dismissReason,
      dismisserLogin: dismisserLogin,
      dismisserAvatarUrl: dismisserAvatarUrl,
    );
  }

  /// Lists code scanning alerts. GET /repos/{o}/{r}/code-scanning/alerts.
  @Lens(
    'list_code_scanning_alerts',
    'List code scanning alerts with optional filters.',
    category: ToolCategory.security,
    access: ToolAccess.read,
  )
  Future<PaginatedResult<CodeScanningAlertItem>> listCodeScanningAlerts({
    @Desc('Filter by state: open, dismissed, fixed') String? state,
    @Desc('Filter by severity: critical, high, medium, low') String? severity,
    @Desc('Filter by branch/tag ref') String? refName,
    @Desc('Results per page') int perPage = 30,
    @Desc('Page number') int page = 1,
  }) async {
    final queryParams = <String, dynamic>{
      'per_page': perPage,
      'page': page,
      if (state != null) 'state': state,
      if (severity != null) 'severity': severity,
      if (refName != null) 'ref': refName,
    };
    final Response<dynamic> response = await rest.get<dynamic>(
      '${ref.apiPath}/code-scanning/alerts',
      queryParameters: queryParams,
      options: Options(
        // GitHub uses 404 for the ordinary "no analysis configured" state.
        // Accept it here so the global HTTP interceptor does not surface that
        // expected state as an application error notification.
        validateStatus: (final int? status) =>
            status != null &&
            (status >= 200 && status < 300 || status == 304 || status == 404),
      ),
    );
    if (response.statusCode == 404) {
      final Object? data = response.data;
      final String? message = data is Map<dynamic, dynamic>
          ? data['message']?.toString()
          : null;
      // GitHub reports an unconfigured code-scanning repository as 404 rather
      // than an empty collection. Preserve other 404 responses because GitHub
      // also uses them to conceal resources the current token cannot access.
      if (message?.toLowerCase() == 'no analysis found') {
        return const PaginatedResult<CodeScanningAlertItem>(
          items: <CodeScanningAlertItem>[],
          hasNextPage: false,
        );
      }
      throw DioException.badResponse(
        statusCode: response.statusCode!,
        requestOptions: response.requestOptions,
        response: response,
      );
    }
    final List<Object?> list = extractListFromResponse<Object?>(response);
    final items = list
        .map(
          (e) => CodeScanningAlertItem.fromJson(
            Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
          ),
        )
        .toList();
    return parsePaginatedRestResponse<CodeScanningAlertItem>(
      response: response,
      items: items,
      currentPage: page,
    );
  }

  /// Gets a single code scanning alert. GET .../code-scanning/alerts/{number}.
  @Lens(
    'get_code_scanning_alert',
    'Get details of a specific code scanning alert.',
    category: ToolCategory.security,
    access: ToolAccess.read,
  )
  Future<CodeScanningAlertItem> getCodeScanningAlert(
    @Desc('Alert number') int alertNumber,
  ) async {
    final response = await rest.get<Map<String, dynamic>>(
      '${ref.apiPath}/code-scanning/alerts/$alertNumber',
    );
    return CodeScanningAlertItem.fromJson(response.data!);
  }

  /// Updates a code scanning alert (dismiss or reopen). PATCH .../code-scanning/alerts/{number}.
  @Skip()
  Future<void> updateCodeScanningAlert(
    @Desc('Alert number') int alertNumber, {
    @Desc('State: open or dismissed') required String state,
    @Desc('Reason for dismissal') String? dismissedReason,
    @Desc('Optional comment') String? dismissedComment,
  }) async {
    await rest.patch<void>(
      '${ref.apiPath}/code-scanning/alerts/$alertNumber',
      data: <String, dynamic>{
        'state': state,
        if (dismissedReason != null) 'dismissed_reason': dismissedReason,
        if (dismissedComment != null) 'dismissed_comment': dismissedComment,
      },
    );
  }

  /// REST GET /repos/{o}/{r}/stats/punch_card.
  @Lens(
    'get_punch_card',
    'Get commit hourly distribution (punch card).',
    category: ToolCategory.stats,
    access: ToolAccess.read,
  )
  Future<List<PunchCardEntry>> getPunchCard({
    @Skip() final bool refresh = false,
  }) async {
    final Response<dynamic> res = await rest.get<dynamic>(
      '${ref.apiPath}/stats/punch_card',
      refreshCache: refresh,
    );
    final List<Object?> raw = extractListFromResponse<Object?>(res);
    return raw.whereType<List<dynamic>>().map(PunchCardEntry.fromList).toList();
  }

  /// Top 10 referral sources for the last 14 days.
  @Lens(
    'get_top_referrers',
    'Get top 10 referral sources for the last 14 days.',
    category: ToolCategory.stats,
    access: ToolAccess.read,
  )
  Future<List<TrafficReferrer>> getTopReferrers({
    @Skip() final bool refresh = false,
  }) async {
    final Response<dynamic> res = await rest.get<dynamic>(
      '${ref.apiPath}/traffic/popular/referrers',
      refreshCache: refresh,
    );
    final List<Object?> raw = extractListFromResponse<Object?>(res);
    return raw
        .whereType<Map<String, dynamic>>()
        .map(TrafficReferrer.fromJson)
        .toList();
  }

  /// Top 10 popular content paths for the last 14 days.
  @Lens(
    'get_top_paths',
    'Get top 10 popular content paths for the last 14 days.',
    category: ToolCategory.stats,
    access: ToolAccess.read,
  )
  Future<List<TrafficPath>> getTopPaths({
    @Skip() final bool refresh = false,
  }) async {
    final Response<dynamic> res = await rest.get<dynamic>(
      '${ref.apiPath}/traffic/popular/paths',
      refreshCache: refresh,
    );
    final List<Object?> raw = extractListFromResponse<Object?>(res);
    return raw
        .whereType<Map<String, dynamic>>()
        .map(TrafficPath.fromJson)
        .toList();
  }

  /// Weekly commit counts: owner vs all contributors (52 weeks).
  @Lens(
    'get_participation',
    'Get weekly commit counts: owner vs all contributors (52 weeks).',
    category: ToolCategory.stats,
    access: ToolAccess.read,
  )
  Future<ParticipationResponse> getParticipation({
    @Skip() final bool refresh = false,
  }) async {
    final Response<Map<String, dynamic>> res = await rest
        .get<Map<String, dynamic>>(
          '${ref.apiPath}/stats/participation',
          refreshCache: refresh,
        );
    final Map<String, dynamic>? data = res.data;
    if (data == null) return const ParticipationResponse();
    return ParticipationResponse.fromJson(data);
  }
}
