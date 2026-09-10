import 'package:diohub/common/pagination/runtime_forward_page_source.dart';
import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/models/global_repository_browse_query.dart';
import 'package:diohub/models/global_project_browse_query.dart';
import 'package:diohub/services/search/search_service.dart';
import 'package:diohub/services/users/user_info_service.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub_models/models/search/issue_or_pull.dart';
import 'package:flutter/foundation.dart';

typedef GlobalIssuePullPageSpecFactory =
    ResourceSpec<PaginatedResourcePage<IssueOrPull, GlobalSearchPageKey>>
    Function({
      required ResourceScope scope,
      required String query,
      required GlobalSearchPageKey pageKey,
      required int pageSize,
    });

typedef GlobalRepositoryPageSpecFactory =
    ResourceSpec<PaginatedResourcePage<UserRepoEdge, GlobalSearchPageKey>>
    Function({
      required ResourceScope scope,
      required GlobalRepositoryBrowseQuery query,
      required GlobalSearchPageKey pageKey,
      required int pageSize,
    });

typedef GlobalProjectPageSpecFactory =
    ResourceSpec<PaginatedResourcePage<UserProjectV2Edge, GlobalSearchPageKey>>
    Function({
      required ResourceScope scope,
      required GlobalProjectBrowseQuery query,
      required GlobalSearchPageKey pageKey,
      required int pageSize,
    });

typedef GlobalDiscussionPageSpecFactory =
    ResourceSpec<PaginatedResourcePage<DiscussionCardData, GlobalSearchPageKey>>
    Function({
      required ResourceScope scope,
      required String query,
      required GlobalSearchPageKey pageKey,
      required int pageSize,
    });

@immutable
final class GlobalSearchPageKey {
  const GlobalSearchPageKey.first() : cursor = null;
  const GlobalSearchPageKey.after(this.cursor)
    : assert(
        cursor != null && cursor != '',
        'A continuation page requires a non-empty cursor.',
      );

  final String? cursor;

  String get identity => cursor == null ? 'first' : 'after:$cursor';

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is GlobalSearchPageKey && other.cursor == cursor;

  @override
  int get hashCode => cursor.hashCode;
}

const ResourcePolicy globalSearchPagePolicy = ResourcePolicy(
  freshFor: Duration(seconds: 30),
  retainFor: Duration(minutes: 5),
  estimatedWeight: 24,
);

ResourceTag globalSearchQueryTag({
  required final String kind,
  required final String query,
}) => ResourceTag('global-search-$kind', query);

ResourceSelector globalSearchQuerySelector({
  required final ResourceScope scope,
  required final String kind,
  required final String query,
}) => ResourceSelector.forTags(<ResourceTag>{
  globalSearchQueryTag(kind: kind, query: query),
}, scope: scope);

ResourceTag globalRepositoryQueryTag(final GlobalRepositoryBrowseQuery query) =>
    ResourceTag('global-repository-dashboard', query.remoteIdentity);

ResourceSelector globalRepositoryQuerySelector({
  required final ResourceScope scope,
  required final GlobalRepositoryBrowseQuery query,
}) => ResourceSelector.forTags(<ResourceTag>{
  globalRepositoryQueryTag(query),
}, scope: scope);

ResourceTag globalProjectQueryTag(final GlobalProjectBrowseQuery query) =>
    ResourceTag('global-project-dashboard', query.identity);

ResourceSelector globalProjectQuerySelector({
  required final ResourceScope scope,
  required final GlobalProjectBrowseQuery query,
}) => ResourceSelector.forTags(<ResourceTag>{
  globalProjectQueryTag(query),
}, scope: scope);

ResourceSpec<PaginatedResourcePage<IssueOrPull, GlobalSearchPageKey>>
globalIssuePullPageSpec({
  required final SearchService service,
  required final ResourceScope scope,
  required final String query,
  required final GlobalSearchPageKey pageKey,
  required final int pageSize,
}) => ResourceSpec<PaginatedResourcePage<IssueOrPull, GlobalSearchPageKey>>(
  id: ResourceId<PaginatedResourcePage<IssueOrPull, GlobalSearchPageKey>>(
    kind: 'global-issue-pull-search-page',
    version: 1,
    scope: scope,
    key: 'query:$query/${pageKey.identity}/size:$pageSize',
  ),
  policy: globalSearchPagePolicy,
  tags: <ResourceTag>{globalSearchQueryTag(kind: 'issue-pull', query: query)},
  contract: 'github-graphql-global-issue-pull-search-v1',
  load: (final ResourceLoadContext _) async {
    final PaginatedResult<IssueOrPull> page = await service.searchIssuesPulls(
      query,
      first: pageSize,
      after: pageKey.cursor,
    );
    final List<IssueOrPull> items = List<IssueOrPull>.unmodifiable(page.items);
    final String? nextCursor = page.endCursor;
    final bool hasNextPage =
        page.hasNextPage && nextCursor != null && nextCursor.isNotEmpty;
    return ResourceLoadResult<
      PaginatedResourcePage<IssueOrPull, GlobalSearchPageKey>
    >(
      data: PaginatedResourcePage<IssueOrPull, GlobalSearchPageKey>(
        items: items,
        hasNextPage: hasNextPage,
        nextPageKey: hasNextPage ? GlobalSearchPageKey.after(nextCursor) : null,
        totalCount: page.totalCount,
      ),
      estimatedWeight: items.isEmpty ? 1 : items.length * 3,
    );
  },
);

ResourceSpec<PaginatedResourcePage<UserRepoEdge, GlobalSearchPageKey>>
globalRepositoryPageSpec({
  required final UserInfoService service,
  required final ResourceScope scope,
  required final GlobalRepositoryBrowseQuery query,
  required final GlobalSearchPageKey pageKey,
  required final int pageSize,
}) => ResourceSpec<PaginatedResourcePage<UserRepoEdge, GlobalSearchPageKey>>(
  id: ResourceId<PaginatedResourcePage<UserRepoEdge, GlobalSearchPageKey>>(
    kind: 'global-repository-dashboard-page',
    version: 2,
    scope: scope,
    key: '${query.remoteIdentity}/${pageKey.identity}/size:$pageSize',
  ),
  policy: globalSearchPagePolicy,
  tags: <ResourceTag>{globalRepositoryQueryTag(query)},
  contract: 'github-graphql-affiliated-repository-dashboard-v1',
  load: (final ResourceLoadContext _) async {
    final UserRepositories result = await service.getUserRepositories(
      query.login,
      pageSize,
      after: pageKey.cursor,
      orderField: _repositoryOrderField(query.sort),
      orderDirection: query.sort == GlobalRepositorySort.name
          ? OrderDirection.ASC
          : OrderDirection.DESC,
      visibility: switch (query.visibility) {
        GlobalRepositoryVisibility.all => null,
        GlobalRepositoryVisibility.public => RepositoryVisibility.PUBLIC,
        GlobalRepositoryVisibility.private => RepositoryVisibility.PRIVATE,
      },
    );
    final List<UserRepoEdge> items = List<UserRepoEdge>.unmodifiable(
      result.edges?.whereType<UserRepoEdge>() ?? const <UserRepoEdge>[],
    );
    final String? nextCursor = result.pageInfo.endCursor;
    final bool hasNextPage =
        result.pageInfo.hasNextPage &&
        nextCursor != null &&
        nextCursor.isNotEmpty;
    return ResourceLoadResult<
      PaginatedResourcePage<UserRepoEdge, GlobalSearchPageKey>
    >(
      data: PaginatedResourcePage<UserRepoEdge, GlobalSearchPageKey>(
        items: items,
        hasNextPage: hasNextPage,
        nextPageKey: hasNextPage ? GlobalSearchPageKey.after(nextCursor) : null,
      ),
      estimatedWeight: items.isEmpty ? 1 : items.length * 3,
    );
  },
);

ResourceSpec<PaginatedResourcePage<UserProjectV2Edge, GlobalSearchPageKey>>
globalProjectPageSpec({
  required final UserInfoService service,
  required final ResourceScope scope,
  required final GlobalProjectBrowseQuery query,
  required final GlobalSearchPageKey pageKey,
  required final int pageSize,
}) =>
    ResourceSpec<PaginatedResourcePage<UserProjectV2Edge, GlobalSearchPageKey>>(
      id:
          ResourceId<
            PaginatedResourcePage<UserProjectV2Edge, GlobalSearchPageKey>
          >(
            kind: 'global-project-dashboard-page',
            version: 1,
            scope: scope,
            key: '${query.identity}/${pageKey.identity}/size:$pageSize',
          ),
      policy: globalSearchPagePolicy,
      tags: <ResourceTag>{globalProjectQueryTag(query)},
      contract: 'github-graphql-user-project-v2-dashboard-v1',
      load: (final ResourceLoadContext _) async {
        final PaginatedResult<UserProjectV2Edge> page = await service
            .getUserProjectsV2Page(
              query.login,
              pageSize,
              after: pageKey.cursor,
              query: query.normalizedText.isEmpty ? null : query.normalizedText,
              orderBy: ProjectV2Order(
                direction: query.sort == GlobalProjectSort.name
                    ? OrderDirection.ASC
                    : OrderDirection.DESC,
                field: query.sort == GlobalProjectSort.name
                    ? ProjectV2OrderField.TITLE
                    : ProjectV2OrderField.UPDATED_AT,
              ),
            );
        final List<UserProjectV2Edge> items =
            List<UserProjectV2Edge>.unmodifiable(page.items);
        final String? nextCursor = page.endCursor;
        final bool hasNextPage =
            page.hasNextPage && nextCursor != null && nextCursor.isNotEmpty;
        return ResourceLoadResult<
          PaginatedResourcePage<UserProjectV2Edge, GlobalSearchPageKey>
        >(
          data: PaginatedResourcePage<UserProjectV2Edge, GlobalSearchPageKey>(
            items: items,
            hasNextPage: hasNextPage,
            nextPageKey: hasNextPage
                ? GlobalSearchPageKey.after(nextCursor)
                : null,
            totalCount: page.totalCount,
          ),
          estimatedWeight: items.isEmpty ? 1 : items.length * 2,
        );
      },
    );

ResourceSpec<PaginatedResourcePage<DiscussionCardData, GlobalSearchPageKey>>
globalDiscussionPageSpec({
  required final SearchService service,
  required final ResourceScope scope,
  required final String query,
  required final GlobalSearchPageKey pageKey,
  required final int pageSize,
}) =>
    ResourceSpec<
      PaginatedResourcePage<DiscussionCardData, GlobalSearchPageKey>
    >(
      id:
          ResourceId<
            PaginatedResourcePage<DiscussionCardData, GlobalSearchPageKey>
          >(
            kind: 'global-discussion-search-page',
            version: 1,
            scope: scope,
            key: 'query:$query/${pageKey.identity}/size:$pageSize',
          ),
      policy: globalSearchPagePolicy,
      tags: <ResourceTag>{
        globalSearchQueryTag(kind: 'discussion', query: query),
      },
      contract: 'github-graphql-global-discussion-search-v1',
      load: (final ResourceLoadContext _) async {
        final PaginatedResult<DiscussionCardData> page = await service
            .searchDiscussions(query, first: pageSize, after: pageKey.cursor);
        final List<DiscussionCardData> items =
            List<DiscussionCardData>.unmodifiable(page.items);
        final String? nextCursor = page.endCursor;
        final bool hasNextPage =
            page.hasNextPage && nextCursor != null && nextCursor.isNotEmpty;
        return ResourceLoadResult<
          PaginatedResourcePage<DiscussionCardData, GlobalSearchPageKey>
        >(
          data: PaginatedResourcePage<DiscussionCardData, GlobalSearchPageKey>(
            items: items,
            hasNextPage: hasNextPage,
            nextPageKey: hasNextPage
                ? GlobalSearchPageKey.after(nextCursor)
                : null,
            totalCount: page.totalCount,
          ),
          estimatedWeight: items.isEmpty ? 1 : items.length * 3,
        );
      },
    );

RepositoryOrderField _repositoryOrderField(final GlobalRepositorySort sort) =>
    switch (sort) {
      GlobalRepositorySort.recentlyPushed => RepositoryOrderField.PUSHED_AT,
      GlobalRepositorySort.recentlyUpdated => RepositoryOrderField.UPDATED_AT,
      GlobalRepositorySort.name => RepositoryOrderField.NAME,
      GlobalRepositorySort.stars => RepositoryOrderField.STARGAZERS,
    };
