import 'package:dio/dio.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/services/base/rest_pagination_helper.dart';
import 'package:diohub_graphql/schema.graphql.dart';
import 'package:diohub_graphql/queries/repositories/discussions_list.graphql.dart';
import 'package:diohub_graphql/queries/repositories/projects_list.graphql.dart';
import 'package:diohub_graphql/queries/repositories/repo_lists.graphql.dart';
import 'package:diohub_graphql/queries/repositories/stargazers.graphql.dart';
import 'package:diohub_graphql/queries/repositories/stargazers_history.graphql.dart';
import 'package:diohub_graphql/queries/repositories/forks.graphql.dart';
import 'package:diohub_graphql/queries/repositories/watchers.graphql.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/secret_scanning_alert.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub/models/repository_contributor_preview.dart';
import 'package:diohub/services/base/base_service.dart';

/// Service for repository paginated list operations:
/// - Discussions (with filters and ordering)
/// - Projects V2 (with ordering)
/// - Stargazers
/// - Forks (with ordering)
/// - Watchers
/// - Secret scanning alerts (REST pagination)
class RepoListService extends EntityService<RepoRef> {
  RepoListService(super.apiClient, super.ref);

  /// Lightweight contributor preview for the Repository Code sidebar.
  ///
  /// This intentionally uses `/contributors`, not `/stats/contributors`:
  /// the latter returns weekly statistics and is substantially heavier.
  Future<List<RepositoryContributorPreview>> fetchContributorPreview({
    final int limit = 12,
    final bool refresh = false,
  }) async {
    final Response<dynamic> response = await rest.get<dynamic>(
      '${ref.apiPath}/contributors',
      queryParameters: <String, dynamic>{'per_page': limit, 'page': 1},
      refreshCache: refresh,
    );
    final List<Object?> raw = extractListFromResponse<Object?>(response);
    return <RepositoryContributorPreview>[
      for (final Object? value in raw)
        if (value case final Map<String, dynamic> json)
          if (json['login'] case final String login)
            RepositoryContributorPreview(
              login: login,
              avatarUrl: json['avatar_url']?.toString(),
              contributions: switch (json['contributions']) {
                final int count => count,
                final num count => count.toInt(),
                _ => 0,
              },
            ),
    ];
  }

  // ============================================================================
  // Discussions
  // ============================================================================

  /// Paginated discussions list for [SliverListBody].
  Future<PaginatedResult<Query$discussionsList$repository$discussions$edges>>
  fetchDiscussionsPaginated({
    required final int first,
    final String? after,
    final Input$DiscussionOrder? orderBy,
    final List<Enum$DiscussionState>? states,
    final bool refresh = false,
  }) async {
    final Input$DiscussionOrder defaultOrder = Input$DiscussionOrder(
      direction: Enum$OrderDirection.DESC,
      field: Enum$DiscussionOrderField.UPDATED_AT,
    );
    final GQLResponse response = await gql.query(
      documentNodeQuerydiscussionsList,
      Variables$Query$discussionsList(
        owner: ref.owner,
        repo: ref.name,
        first: first,
        after: after,
        orderBy: orderBy ?? defaultOrder,
        states: states,
      ).toJson(),
      refreshCache: refresh,
    );
    final data = Query$discussionsList.fromJson(response.data!).repository!;
    final List<Query$discussionsList$repository$discussions$edges?> edges =
        data.discussions.edges?.toList() ??
        <Query$discussionsList$repository$discussions$edges?>[];
    final items = edges
        .whereType<Query$discussionsList$repository$discussions$edges>()
        .toList();
    final pageInfo = data.discussions.pageInfo;
    return PaginatedResult(
      items: items,
      hasNextPage: pageInfo.hasNextPage,
      endCursor: pageInfo.endCursor,
    );
  }

  // ============================================================================
  // Projects V2
  // ============================================================================

  /// Paginated projects list for [SliverListBody] (ProjectV2).
  Future<PaginatedResult<Query$projectsList$repository$projectsV2$edges>>
  fetchProjectsPaginated({
    required final int first,
    final String? after,
    final Input$ProjectV2Order? orderBy,
    final bool refresh = false,
  }) async {
    final Input$ProjectV2Order defaultOrder = Input$ProjectV2Order(
      direction: Enum$OrderDirection.DESC,
      field: Enum$ProjectV2OrderField.UPDATED_AT,
    );
    final GQLResponse response = await gql.query(
      documentNodeQueryprojectsList,
      Variables$Query$projectsList(
        owner: ref.owner,
        repo: ref.name,
        first: first,
        after: after,
        orderBy: orderBy ?? defaultOrder,
      ).toJson(),
      refreshCache: refresh,
    );
    final data = Query$projectsList.fromJson(response.data!).repository!;
    final List<Query$projectsList$repository$projectsV2$edges?> edges =
        data.projectsV2.edges?.toList() ??
        <Query$projectsList$repository$projectsV2$edges?>[];
    final items = edges
        .whereType<Query$projectsList$repository$projectsV2$edges>()
        .toList();
    final pageInfo = data.projectsV2.pageInfo;
    return PaginatedResult(
      items: items,
      hasNextPage: pageInfo.hasNextPage,
      endCursor: pageInfo.endCursor,
    );
  }

  /// List repository Projects V2 via GraphQL (for project picker).
  Future<
    PaginatedResult<Query$repositoryProjectsV2$repository$projectsV2$edges?>
  >
  listProjectsV2GQL({required final int first, final String? after}) async {
    final GQLResponse res = await gql.query(
      documentNodeQueryrepositoryProjectsV2,
      Variables$Query$repositoryProjectsV2(
        owner: ref.owner,
        name: ref.name,
        first: first,
        after: after,
      ).toJson(),
    );
    final data = Query$repositoryProjectsV2.fromJson(res.data!);
    final projectsV2 = data?.repository?.projectsV2;
    return PaginatedResult.fromEdges(
      projectsV2?.edges?.toList() ??
          <Query$repositoryProjectsV2$repository$projectsV2$edges>[],
      projectsV2?.pageInfo.hasNextPage ?? false,
      projectsV2?.pageInfo.endCursor,
    );
  }

  // ============================================================================
  // Stargazers, Forks, Watchers
  // ============================================================================

  /// Stargazers for [SliverListBody].
  Future<PaginatedResult<Query$getStargazers$repository$stargazers$edges>>
  fetchStargazersPaginated({
    required final int first,
    final String? after,
    final bool refresh = false,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerygetStargazers,
      Variables$Query$getStargazers(
        owner: ref.owner,
        name: ref.name,
        first: first,
        after: after,
      ).toJson(),
      refreshCache: refresh,
    );
    final data = Query$getStargazers.fromJson(res.data!);
    final stargazers = data?.repository?.stargazers;
    final edges =
        stargazers?.edges?.toList() ??
        <Query$getStargazers$repository$stargazers$edges?>[];
    return PaginatedResult(
      items: edges
          .whereType<Query$getStargazers$repository$stargazers$edges>()
          .toList(),
      hasNextPage: stargazers?.pageInfo.hasNextPage ?? false,
      endCursor: stargazers?.pageInfo.endCursor,
    );
  }

  /// Fetch stargazer timestamps for star history chart (capped at maxPages * 100).
  Future<List<DateTime>> fetchStargazerTimestamps({int maxPages = 5}) async {
    final List<DateTime> timestamps = [];
    String? cursor;
    int pagesFetched = 0;

    while (pagesFetched < maxPages) {
      final GQLResponse res = await gql.query(
        documentNodeQuerygetStargazerHistory,
        Variables$Query$getStargazerHistory(
          owner: ref.owner,
          name: ref.name,
          first: 100,
          after: cursor,
        ).toJson(),
      );

      final data = Query$getStargazerHistory.fromJson(res.data!);
      final stargazers = data?.repository?.stargazers;

      if (stargazers == null) break;

      final edges =
          stargazers.edges?.toList() ??
          <Query$getStargazerHistory$repository$stargazers$edges?>[];

      for (final edge in edges) {
        if (edge != null) {
          timestamps.add(edge.starredAt);
        }
      }

      pagesFetched++;
      if (stargazers.pageInfo.hasNextPage &&
          stargazers.pageInfo.endCursor != null) {
        cursor = stargazers.pageInfo.endCursor;
      } else {
        break;
      }
    }

    return timestamps;
  }

  /// Forks for [SliverListBody].
  Future<PaginatedResult<Query$getForks$repository$forks$edges>>
  fetchForksPaginated({
    required final int first,
    final String? after,
    final Input$RepositoryOrder? orderBy,
    final bool refresh = false,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerygetForks,
      Variables$Query$getForks(
        owner: ref.owner,
        name: ref.name,
        first: first,
        after: after,
        orderBy: orderBy,
      ).toJson(),
      refreshCache: refresh,
    );
    final data = Query$getForks.fromJson(res.data!);
    final forks = data?.repository?.forks;
    final edges =
        forks?.edges?.toList() ?? <Query$getForks$repository$forks$edges?>[];
    return PaginatedResult(
      items: edges.whereType<Query$getForks$repository$forks$edges>().toList(),
      hasNextPage: forks?.pageInfo.hasNextPage ?? false,
      endCursor: forks?.pageInfo.endCursor,
    );
  }

  /// Watchers for [SliverListBody].
  Future<PaginatedResult<Query$getWatchers$repository$watchers$edges>>
  fetchWatchersPaginated({
    required final int first,
    final String? after,
    final bool refresh = false,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerygetWatchers,
      Variables$Query$getWatchers(
        owner: ref.owner,
        name: ref.name,
        first: first,
        after: after,
      ).toJson(),
      refreshCache: refresh,
    );
    final data = Query$getWatchers.fromJson(res.data!);
    final watchers = data?.repository?.watchers;
    final edges =
        watchers?.edges?.toList() ??
        <Query$getWatchers$repository$watchers$edges?>[];
    return PaginatedResult(
      items: edges
          .whereType<Query$getWatchers$repository$watchers$edges>()
          .toList(),
      hasNextPage: watchers?.pageInfo.hasNextPage ?? false,
      endCursor: watchers?.pageInfo.endCursor,
    );
  }

  // ============================================================================
  // Secret Scanning (REST pagination)
  // ============================================================================

  /// List secret scanning alerts. Returns empty list on 404 (scanning disabled).
  Future<List<SecretScanningAlert>> listSecretScanningAlerts({
    final int page = 1,
    final int perPage = 30,
    final String? state,
  }) async {
    try {
      final Response<dynamic> res = await rest.get<dynamic>(
        '${ref.apiPath}/secret-scanning/alerts',
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          if (state != null && state.isNotEmpty) 'state': state,
        },
      );
      final List<Object?> raw = extractListFromResponse<Object?>(res);
      return raw
          .map(
            (final dynamic e) =>
                SecretScanningAlert.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return <SecretScanningAlert>[];
      rethrow;
    }
  }
}
