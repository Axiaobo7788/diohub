import 'package:dio/dio.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/app/app_logger.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_graphql/queries/search/search_discussions.graphql.dart';
import 'package:diohub_graphql/queries/search/search_issues_pulls.graphql.dart';
import 'package:diohub_graphql/queries/search/search_repositories.graphql.dart';
import 'package:diohub_graphql/queries/search/search_users.graphql.dart';
import 'package:diohub_graphql/queries/users/user_search_mention.graphql.dart';
import 'package:diohub/common/search_overlay/filters.dart';
import 'package:diohub/models/filters/custom_filter.dart';
import 'package:diohub/models/commits/commit_list_item_model.dart';
import 'package:diohub_models/models/search/code_search_result.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub_models/models/search/issue_or_pull.dart';
import 'package:diohub_models/models/search/package_search_result.dart';
import 'package:diohub_models/models/search/topic_search_result.dart';
import 'package:diohub_models/models/search/wiki_search_result.dart';
import 'package:diohub_models/models/users/profile_card_input.dart'
    show
        FragmentOrg,
        FragmentUser,
        ProfileCardInput,
        ProfileCardInputOrg,
        ProfileCardInputUser;
import 'package:diohub_models/models/pagination/paginated_result.dart'
    show PaginatedResult;
import 'package:diohub/services/base/base_service.dart';
import 'package:diohub/services/base/rest_search_helpers.dart';
import 'package:lens_annotations/lens_annotations.dart';

@LensService(scope: Scope.global, group: 'search')
final class SearchService extends BaseService {
  const SearchService._(ApiClient client) : super(client);

  factory SearchService(ApiClient client) => SearchService._(client);

  /// Search repositories via GraphQL. Sort qualifiers (e.g. sort:stars-desc) in [query].
  @Lens(
    'search_repositories',
    'Search for repositories on GitHub',
    category: ToolCategory.search,
    access: ToolAccess.read,
  )
  Future<PaginatedResult<RepoCardData>> searchRepos(
    @Desc('Search query') final String query, {
    @Desc('Number of results (max 100)') final int first = 20,
    @Desc('Pagination cursor') final String? after,
    final void Function(Map<String, dynamic>? rawData)? onRawResponse,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerysearchRepositories,
      Variables$Query$searchRepositories(
        query: query,
        first: first,
        after: after,
      ).toJson(),
    );

    if (res.errors != null && res.errors!.isNotEmpty) {
      AppLogger.warning(
        'SearchService.searchRepos: GraphQL errors: ${res.errors}',
        tag: 'SearchService',
      );
    }

    if (res.data != null && onRawResponse != null) {
      onRawResponse(res.data);
    }

    final Query$searchRepositories data = Query$searchRepositories.fromJson(
      res.data!,
    );
    final Query$searchRepositories$search search = data.search;

    final List<RepoCardData> items = <RepoCardData>[];
    if (search.nodes != null) {
      for (final Query$searchRepositories$search$nodes? node in search.nodes!) {
        if (node != null && node is RepoCardData) {
          items.add(node as RepoCardData);
        }
      }
    }

    AppLogger.info(
      'SearchService.searchRepos: '
      'repoCount=${search.repositoryCount} '
      'parsed=${items.length} '
      'hasNext=${search.pageInfo.hasNextPage}',
      tag: 'SearchService',
    );

    return PaginatedResult<RepoCardData>(
      items: items,
      hasNextPage: search.pageInfo.hasNextPage,
      endCursor: search.pageInfo.endCursor,
    );
  }

  /// Search issues and pull requests via GraphQL. Sort qualifiers in [query].
  @Lens(
    'search_issues_pulls',
    'Search for issues and pull requests on GitHub',
    category: ToolCategory.search,
    access: ToolAccess.read,
  )
  Future<PaginatedResult<IssueOrPull>> searchIssuesPulls(
    @Desc('Search query') final String query, {
    @Desc('Number of results (max 100)') final int first = 20,
    @Desc('Pagination cursor') final String? after,
    final void Function(Map<String, dynamic>? rawData)? onRawResponse,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerysearchIssuesPulls,
      Variables$Query$searchIssuesPulls(
        query: query,
        first: first,
        after: after,
      ).toJson(),
    );

    if (res.errors != null && res.errors!.isNotEmpty) {
      AppLogger.warning(
        'SearchService.searchIssuesPulls: GraphQL errors: ${res.errors}',
        tag: 'SearchService',
      );
    }

    if (res.data == null) {
      AppLogger.error(
        'SearchService.searchIssuesPulls: res.data is null! '
        'errors=${res.errors}',
        tag: 'SearchService',
      );
    }

    if (res.data != null && onRawResponse != null) {
      onRawResponse(res.data);
    }

    final Query$searchIssuesPulls data = Query$searchIssuesPulls.fromJson(
      res.data!,
    );
    final Query$searchIssuesPulls$search search = data.search;

    final List<IssueOrPull> items = <IssueOrPull>[];
    final int totalNodes = search.nodes?.length ?? 0;
    int nullNodes = 0;
    int unmatchedNodes = 0;

    if (search.nodes != null) {
      for (final Query$searchIssuesPulls$search$nodes? node in search.nodes!) {
        if (node == null) {
          nullNodes++;
          continue;
        }
        if (node is IssueCardData) {
          items.add(IssueResult(node as IssueCardData));
        } else if (node is PullCardData) {
          items.add(PullResult(node as PullCardData));
        } else {
          unmatchedNodes++;
          AppLogger.warning(
            'SearchService.searchIssuesPulls: unmatched node type '
            '${node.runtimeType} (__typename=${node.$__typename})',
            tag: 'SearchService',
          );
        }
      }
    }

    AppLogger.info(
      'SearchService.searchIssuesPulls: '
      'issueCount=${search.issueCount} '
      'totalNodes=$totalNodes null=$nullNodes unmatched=$unmatchedNodes '
      'parsed=${items.length} '
      'hasNext=${search.pageInfo.hasNextPage} '
      'cursor=${search.pageInfo.endCursor}',
      tag: 'SearchService',
    );

    return PaginatedResult<IssueOrPull>(
      items: items,
      hasNextPage: search.pageInfo.hasNextPage,
      endCursor: search.pageInfo.endCursor,
    );
  }

  /// Search users via GraphQL. Sort qualifiers in [query].
  @Lens(
    'search_users',
    'Search for users on GitHub',
    category: ToolCategory.search,
    access: ToolAccess.read,
  )
  Future<PaginatedResult<ProfileCardInput>> searchUsers(
    @Desc('Search query') final String query, {
    @Desc('Number of results (max 100)') final int first = 20,
    @Desc('Pagination cursor') final String? after,
    final void Function(Map<String, dynamic>? rawData)? onRawResponse,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerysearchUsers,
      Variables$Query$searchUsers(
        query: query,
        first: first,
        after: after,
      ).toJson(),
    );
    if (res.data != null && onRawResponse != null) {
      onRawResponse(res.data);
    }
    final Query$searchUsers data = Query$searchUsers.fromJson(res.data!);
    final Query$searchUsers$search search = data.search;

    final List<ProfileCardInput> items = <ProfileCardInput>[];
    if (search.nodes != null) {
      for (final Query$searchUsers$search$nodes? node in search.nodes!) {
        if (node == null) continue;
        if (node is UserCardData) {
          items.add(ProfileCardInputUser(FragmentUser(node as UserCardData)));
        } else if (node is OrgCardData) {
          items.add(ProfileCardInputOrg(FragmentOrg(node as OrgCardData)));
        }
      }
    }

    return PaginatedResult<ProfileCardInput>(
      items: items,
      hasNextPage: search.pageInfo.hasNextPage,
      endCursor: search.pageInfo.endCursor,
    );
  }

  /// Search discussions via GraphQL.
  @Lens(
    'search_discussions',
    'Search for discussions on GitHub',
    category: ToolCategory.search,
    access: ToolAccess.read,
  )
  Future<PaginatedResult<DiscussionCardData>> searchDiscussions(
    @Desc('Search query') final String query, {
    @Desc('Number of results (max 100)') final int first = 20,
    @Desc('Pagination cursor') final String? after,
    final void Function(Map<String, dynamic>? rawData)? onRawResponse,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerysearchDiscussions,
      Variables$Query$searchDiscussions(
        query: query,
        first: first,
        after: after,
      ).toJson(),
    );
    if (res.errors != null && res.errors!.isNotEmpty) {
      AppLogger.warning(
        'SearchService.searchDiscussions: GraphQL errors: ${res.errors}',
        tag: 'SearchService',
      );
    }
    if (res.data != null && onRawResponse != null) {
      onRawResponse(res.data);
    }
    final Query$searchDiscussions data = Query$searchDiscussions.fromJson(
      res.data!,
    );
    final Query$searchDiscussions$search search = data.search;
    final List<DiscussionCardData> items = <DiscussionCardData>[];
    if (search.nodes != null) {
      for (final Query$searchDiscussions$search$nodes? node in search.nodes!) {
        if (node != null && node is DiscussionCardData) {
          items.add(node as DiscussionCardData);
        }
      }
    }
    return PaginatedResult<DiscussionCardData>(
      items: items,
      hasNextPage: search.pageInfo.hasNextPage,
      endCursor: search.pageInfo.endCursor,
    );
  }

  /// Search code via REST (page-based pagination).
  @Lens(
    'search_code',
    'Search for code on GitHub',
    category: ToolCategory.search,
    access: ToolAccess.read,
  )
  Future<PaginatedResult<CodeSearchResult>> searchCode(
    @Desc('Search query') final String query, {
    @Desc('Number of results per page') final int first = 20,
    @Desc('Page number') final int page = 1,
  }) async {
    final Response<dynamic> res = await rest.get<dynamic>(
      '/search/code',
      queryParameters: <String, dynamic>{
        'q': query,
        'per_page': first,
        'page': page,
      },
    );
    return parseRestSearchResponse<CodeSearchResult>(
      res,
      fromJson: CodeSearchResult.fromJson,
      page: page,
      perPage: first,
    );
  }

  /// Search commits via REST (page-based pagination).
  @Lens(
    'search_commits',
    'Search for commits on GitHub',
    category: ToolCategory.search,
    access: ToolAccess.read,
  )
  Future<PaginatedResult<CommitListItemModel>> searchCommits(
    @Desc('Search query') final String query, {
    @Desc('Number of results per page') final int first = 20,
    @Desc('Page number') final int page = 1,
  }) async {
    final Response<dynamic> res = await rest.get<dynamic>(
      '/search/commits',
      queryParameters: <String, dynamic>{
        'q': query,
        'per_page': first,
        'page': page,
      },
      requestHeaders: <String, dynamic>{
        'Accept': 'application/vnd.github.cloak-preview+json',
      },
    );
    return parseRestSearchResponse<CommitListItemModel>(
      res,
      fromJson: CommitListItemModel.fromSearchCommitItem,
      page: page,
      perPage: first,
    );
  }

  /// Search topics via REST (page-based pagination).
  @Lens(
    'search_topics',
    'Search for topics on GitHub',
    category: ToolCategory.search,
    access: ToolAccess.read,
  )
  Future<PaginatedResult<TopicSearchResult>> searchTopics(
    @Desc('Search query') final String query, {
    @Desc('Number of results per page') final int first = 20,
    @Desc('Page number') final int page = 1,
  }) async {
    final Response<dynamic> res = await rest.get<dynamic>(
      '/search/topics',
      queryParameters: <String, dynamic>{
        'q': query,
        'per_page': first,
        'page': page,
      },
      requestHeaders: <String, dynamic>{
        'Accept': 'application/vnd.github.mercy-preview+json',
      },
    );
    return parseRestSearchResponse<TopicSearchResult>(
      res,
      fromJson: TopicSearchResult.fromJson,
      page: page,
      perPage: first,
    );
  }

  /// Search packages via REST (page-based pagination).
  @Lens(
    'search_packages',
    'Search for packages on GitHub',
    category: ToolCategory.search,
    access: ToolAccess.read,
  )
  Future<PaginatedResult<PackageSearchResult>> searchPackages(
    @Desc('Search query') final String query, {
    @Desc('Number of results per page') final int first = 20,
    @Desc('Page number') final int page = 1,
  }) async {
    final Response<dynamic> res = await rest.get<dynamic>(
      '/search/packages',
      queryParameters: <String, dynamic>{
        'q': query,
        'per_page': first,
        'page': page,
      },
    );
    return parseRestSearchResponse<PackageSearchResult>(
      res,
      fromJson: PackageSearchResult.fromJson,
      page: page,
      perPage: first,
    );
  }

  /// Search wiki via REST (page-based pagination).
  @Lens(
    'search_wiki',
    'Search for wiki pages on GitHub',
    category: ToolCategory.search,
    access: ToolAccess.read,
  )
  Future<PaginatedResult<WikiSearchResult>> searchWiki(
    @Desc('Search query') final String query, {
    @Desc('Number of results per page') final int first = 20,
    @Desc('Page number') final int page = 1,
  }) async {
    final Response<dynamic> res = await rest.get<dynamic>(
      '/search/wiki',
      queryParameters: <String, dynamic>{
        'q': query,
        'per_page': first,
        'page': page,
      },
    );
    return parseRestSearchResponse<WikiSearchResult>(
      res,
      fromJson: WikiSearchResult.fromJson,
      page: page,
      perPage: first,
    );
  }

  /// Search users for mention autocomplete (existing GQL query).
  Future<List<Query$searchMentionUsers$search$edges?>> searchMentionUsers(
    final String query,
    final String type, {
    final String? cursor,
  }) async {
    final String q = '$query${' type:$type'}';
    final GQLResponse res = await gql.query(
      documentNodeQuerysearchMentionUsers,
      Variables$Query$searchMentionUsers(query: q).toJson(),
    );
    final List<Query$searchMentionUsers$search$edges?> userEdges =
        Query$searchMentionUsers.fromJson(res.data!).search.edges ?? [];
    return userEdges;
  }

  /// Fetches count for each custom filter via dynamic search aliases.
  /// Returns map of filter id → count. Uses [rawQuery]; not cached.
  Future<Map<String, int>> fetchCustomFilterCounts(
    final List<CustomFilter> filters,
    final SearchScope scope,
  ) async {
    if (filters.isEmpty) return <String, int>{};
    final bound = filters.map((f) => f.boundTo(scope)).toList();
    final variables = <String, dynamic>{};
    final selections = <String>[];
    for (var i = 0; i < bound.length; i++) {
      final f = bound[i];
      final alias = f.aliasKey;
      final varName = '${alias}Q';
      variables[varName] = f.toCountQuery();
      final (gqlType, countField) = _searchTypeToGql(f.searchType);
      selections.add(
        '$alias: search(query: \$$varName, type: $gqlType, first: 0) { $countField }',
      );
    }
    final document =
        'query CustomFilterCounts('
        '${variables.keys.map((k) => '\$$k: String!').join(', ')}) '
        '{ ${selections.join(' ')} }';
    final res = await gql.rawQuery(document, variables: variables);
    final data = res.data;
    if (data == null) return <String, int>{};
    final result = <String, int>{};
    for (var i = 0; i < filters.length; i++) {
      final alias = bound[i].aliasKey;
      final (_, countField) = _searchTypeToGql(filters[i].searchType);
      final node = data[alias];
      final countValue = node is Map<String, dynamic> ? node[countField] : null;
      if (countValue is int) {
        result[filters[i].id] = countValue;
      }
    }
    return result;
  }

  (String gqlType, String countField) _searchTypeToGql(final SearchType type) {
    switch (type) {
      case SearchType.issuesPulls:
        return ('ISSUE', 'issueCount');
      case SearchType.repositories:
        return ('REPOSITORY', 'repositoryCount');
      case SearchType.discussions:
        return ('DISCUSSION', 'discussionCount');
      case SearchType.code:
        return ('CODE', 'codeCount');
      case SearchType.commits:
        return ('COMMIT', 'commitCount');
      case SearchType.users:
        return ('USER', 'userCount');
      case SearchType.topics:
      case SearchType.packages:
      case SearchType.wiki:
        return ('ISSUE', 'issueCount');
    }
  }
}
