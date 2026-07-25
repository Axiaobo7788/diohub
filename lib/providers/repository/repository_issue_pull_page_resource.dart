import 'package:diohub/common/pagination/runtime_forward_page_source.dart';
import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/models/repositories/public_repository.dart';
import 'package:diohub/models/repositories/repository_issue_pull_summary.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/providers/repository/public_repository_providers.dart';
import 'package:diohub/services/repositories/public_repository_service.dart';
import 'package:diohub/services/search/search_service.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RepositoryIssuePullPageTransport { authenticatedGraphql, publicRest }

/// Explicit continuation identity for one Repository Issues/PR result page.
final class RepositoryIssuePullPageKey {
  const RepositoryIssuePullPageKey.graphql([this.cursor]) : page = null;

  const RepositoryIssuePullPageKey.rest(this.page)
    : assert(page != null && page > 0),
      cursor = null;

  final String? cursor;
  final int? page;

  String get identity => page == null
      ? 'cursor:${Uri.encodeComponent(cursor ?? 'start')}'
      : 'page:$page';

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is RepositoryIssuePullPageKey &&
          cursor == other.cursor &&
          page == other.page;

  @override
  int get hashCode => Object.hash(cursor, page);
}

typedef RepositoryIssuePullPageResourceSpecFactory =
    ResourceSpec<PaginatedResourcePage<Object, RepositoryIssuePullPageKey>>
    Function({
      required RepoRef repo,
      required String query,
      required RepositoryIssuePullPageTransport transport,
      required RepositoryIssuePullPageKey pageKey,
      required int pageSize,
      required ResourceScope scope,
    });

const ResourcePolicy repositoryIssuePullPageResourcePolicy = ResourcePolicy(
  freshFor: Duration(minutes: 1),
  retainFor: Duration(minutes: 5),
  estimatedWeight: 40,
);

ResourceSpec<PaginatedResourcePage<Object, RepositoryIssuePullPageKey>>
repositoryIssuePullPageResourceSpec({
  required final RepoRef repo,
  required final String query,
  required final RepositoryIssuePullPageTransport transport,
  required final RepositoryIssuePullPageKey pageKey,
  required final int pageSize,
  required final ResourceScope scope,
  required final SearchService? searchService,
  required final PublicRepositoryService? publicRepositoryService,
}) {
  final String repository = repo.fullName;
  final String queryIdentity = repositoryIssuePullQueryIdentity(
    repo: repo,
    query: query,
    transport: transport,
  );
  final String identity = <String>[
    Uri.encodeComponent(repo.owner),
    Uri.encodeComponent(repo.name),
    transport.name,
    Uri.encodeComponent(query),
    pageKey.identity,
    '$pageSize',
  ].join('/');
  return ResourceSpec<
    PaginatedResourcePage<Object, RepositoryIssuePullPageKey>
  >(
    id: ResourceId<PaginatedResourcePage<Object, RepositoryIssuePullPageKey>>(
      kind: 'repository-issue-pull-search-page',
      version: 2,
      scope: scope,
      key: identity,
    ),
    policy: repositoryIssuePullPageResourcePolicy,
    tags: <ResourceTag>{
      ResourceTag('repository', repository),
      ResourceTag('repository-issue-pull-query', queryIdentity),
    },
    contract: 'repository-issue-pull-${transport.name}-page-v2',
    load: (final ResourceLoadContext _) async {
      return switch (transport) {
        RepositoryIssuePullPageTransport.authenticatedGraphql =>
          _loadAuthenticatedPage(
            searchService:
                searchService ??
                (throw StateError(
                  'Authenticated issue/PR pagination requires SearchService.',
                )),
            repo: repo,
            query: query,
            pageKey: pageKey,
            pageSize: pageSize,
          ),
        RepositoryIssuePullPageTransport.publicRest => _loadPublicPage(
          publicRepositoryService:
              publicRepositoryService ??
              (throw StateError(
                'Public issue/PR pagination requires '
                'PublicRepositoryService.',
              )),
          repo: repo,
          query: query,
          pageKey: pageKey,
          pageSize: pageSize,
        ),
      };
    },
  );
}

final repositoryIssuePullPageResourceSpecFactoryProvider =
    Provider<RepositoryIssuePullPageResourceSpecFactory>((final Ref ref) {
      return ({
        required final RepoRef repo,
        required final String query,
        required final RepositoryIssuePullPageTransport transport,
        required final RepositoryIssuePullPageKey pageKey,
        required final int pageSize,
        required final ResourceScope scope,
      }) {
        // The public path must not construct the authenticated ApiClient, and
        // the authenticated path must not depend on the anonymous REST
        // service. Resolve only the transport selected for this query session.
        final SearchService? searchService =
            transport == RepositoryIssuePullPageTransport.authenticatedGraphql
            ? SearchService(ref.read(apiClientProvider))
            : null;
        final PublicRepositoryService? publicRepositoryService =
            transport == RepositoryIssuePullPageTransport.publicRest
            ? ref.read(publicRepositoryServiceProvider)
            : null;
        return repositoryIssuePullPageResourceSpec(
          repo: repo,
          query: query,
          transport: transport,
          pageKey: pageKey,
          pageSize: pageSize,
          scope: scope,
          searchService: searchService,
          publicRepositoryService: publicRepositoryService,
        );
      };
    });

RepositoryIssuePullPageKey repositoryIssuePullFirstPageKey(
  final RepositoryIssuePullPageTransport transport,
) => switch (transport) {
  RepositoryIssuePullPageTransport.authenticatedGraphql =>
    const RepositoryIssuePullPageKey.graphql(),
  RepositoryIssuePullPageTransport.publicRest =>
    const RepositoryIssuePullPageKey.rest(1),
};

String repositoryIssuePullQueryIdentity({
  required final RepoRef repo,
  required final String query,
  required final RepositoryIssuePullPageTransport transport,
}) => '${repo.fullName}\u0000${transport.name}\u0000$query';

ResourceSelector repositoryIssuePullQuerySelector({
  required final RepoRef repo,
  required final String query,
  required final RepositoryIssuePullPageTransport transport,
  required final ResourceScope scope,
}) => ResourceSelector.forTags(<ResourceTag>{
  ResourceTag(
    'repository-issue-pull-query',
    repositoryIssuePullQueryIdentity(
      repo: repo,
      query: query,
      transport: transport,
    ),
  ),
}, scope: scope);

Future<
  ResourceLoadResult<PaginatedResourcePage<Object, RepositoryIssuePullPageKey>>
>
_loadAuthenticatedPage({
  required final SearchService searchService,
  required final RepoRef repo,
  required final String query,
  required final RepositoryIssuePullPageKey pageKey,
  required final int pageSize,
}) async {
  if (pageKey.page != null) {
    throw ArgumentError.value(pageKey, 'pageKey', 'Expected GraphQL cursor');
  }
  final PaginatedResult<RepositoryIssuePullSummary> page = await searchService
      .searchRepositoryIssuePulls(
        repo,
        query,
        first: pageSize,
        after: pageKey.cursor,
      );
  final RepositoryIssuePullPageKey? nextPageKey = page.hasNextPage
      ? RepositoryIssuePullPageKey.graphql(_requiredNextCursor(page.endCursor))
      : null;
  final List<Object> items = List<Object>.unmodifiable(page.items);
  return ResourceLoadResult<
    PaginatedResourcePage<Object, RepositoryIssuePullPageKey>
  >(
    data: PaginatedResourcePage<Object, RepositoryIssuePullPageKey>(
      items: items,
      hasNextPage: page.hasNextPage,
      nextPageKey: nextPageKey,
      totalCount: page.totalCount,
    ),
    estimatedWeight: _estimatedIssuePullPageWeight(items.length),
  );
}

Future<
  ResourceLoadResult<PaginatedResourcePage<Object, RepositoryIssuePullPageKey>>
>
_loadPublicPage({
  required final PublicRepositoryService publicRepositoryService,
  required final RepoRef repo,
  required final String query,
  required final RepositoryIssuePullPageKey pageKey,
  required final int pageSize,
}) async {
  final int? pageNumber = pageKey.page;
  if (pageNumber == null) {
    throw ArgumentError.value(pageKey, 'pageKey', 'Expected REST page number');
  }
  final PageSlice<PublicRepositoryIssuePullSummary> page =
      await publicRepositoryService.searchIssuesPulls(
        repo: repo,
        query: query,
        page: pageNumber,
        perPage: pageSize,
      );
  final List<Object> items = List<Object>.unmodifiable(page.items);
  return ResourceLoadResult<
    PaginatedResourcePage<Object, RepositoryIssuePullPageKey>
  >(
    data: PaginatedResourcePage<Object, RepositoryIssuePullPageKey>(
      items: items,
      hasNextPage: page.hasNextPage,
      nextPageKey: page.hasNextPage
          ? RepositoryIssuePullPageKey.rest(pageNumber + 1)
          : null,
      totalCount: page.totalCount,
    ),
    estimatedWeight: _estimatedIssuePullPageWeight(items.length),
  );
}

String _requiredNextCursor(final String? cursor) {
  if (cursor == null || cursor.isEmpty) {
    throw const FormatException(
      'GitHub reported another search page without an end cursor.',
    );
  }
  return cursor;
}

int _estimatedIssuePullPageWeight(final int itemCount) =>
    itemCount == 0 ? 1 : itemCount * 2;
