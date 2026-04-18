import 'package:dio/dio.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/services/base/rest_pagination_helper.dart';
import 'package:diohub_graphql/schema.graphql.dart';
import 'package:diohub_graphql/queries/repositories/commit_info.graphql.dart';
import 'package:diohub_graphql/queries/repositories/commits_list.graphql.dart';
import 'package:diohub_graphql/queries/repositories/discussion_by_number.graphql.dart';
import 'package:diohub_graphql/queries/repositories/repo_info.graphql.dart';
import 'package:diohub_graphql/fragments/discussion_card_fields.graphql.dart';
import 'package:diohub_models/models/commits/commit_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repository/compare_result.dart';
import 'package:diohub_models/models/repositories/commit_comment_item.dart';
import 'package:diohub_models/models/repositories/community_profile.dart';
import 'package:diohub_models/models/repositories/pages_info.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/services/base/base_service.dart';

/// Service for repository content read operations:
/// - README rendering
/// - Discussions by number
/// - Commit history, info, comments, and compare operations
/// - Community profile and GitHub Pages info
class RepoContentService extends EntityService<RepoRef> {
  RepoContentService(super.apiClient, super.ref);

  // ============================================================================
  // Repository Info
  // ============================================================================

  /// Fetch repository using GraphQL.
  /// [initialRef] when non-null requests the optional `initialRef` field (ref name)
  /// so the response includes the ref's resolved OID for the branch provider.
  /// [viewer] when non-null builds quick-filter count variables for repo issues/pulls scopes.
  Future<Query$repositoryInfo$repository> fetchRepositoryGraphQL({
    final bool refresh = false,
    final String? initialRef,
    final String? viewer,
  }) async {
    final full = await fetchRepositoryGraphQLFull(
      refresh: refresh,
      initialRef: initialRef,
      viewer: viewer,
    );
    return full.repository!;
  }

  /// Same as [fetchRepositoryGraphQL] but returns full query data (includes
  /// quick-filter count aliases). Use when you need to parse counts.
  Future<Query$repositoryInfo> fetchRepositoryGraphQLFull({
    final bool refresh = false,
    final String? initialRef,
    final String? viewer,
  }) async {
    final issuesScope = SearchScope.repoIssues(repo: ref);
    final pullsScope = SearchScope.repoPulls(repo: ref);
    final countVars = <String, String>{
      ...issuesScope.buildCountVariables(viewer ?? ''),
      ...pullsScope.buildCountVariables(viewer ?? ''),
    };

    final GQLResponse response = await gql.query(
      documentNodeQueryrepositoryInfo,
      Variables$Query$repositoryInfo(
        owner: ref.owner,
        name: ref.name,
        includeInitialRef: initialRef != null,
        initialRef: initialRef ?? '',
        assignedToYouRepo_issuesQ:
            countVars['assignedToYouRepo_issuesQ']!,
        yourIssuesRepo_issuesQ: countVars['yourIssuesRepo_issuesQ']!,
        mentionsYouRepo_issuesQ: countVars['mentionsYouRepo_issuesQ']!,
        assignedToYouRepo_pullsQ:
            countVars['assignedToYouRepo_pullsQ']!,
        yourPullRequestsRepo_pullsQ:
            countVars['yourPullRequestsRepo_pullsQ']!,
        mentionsYouRepo_pullsQ: countVars['mentionsYouRepo_pullsQ']!,
      ).toJson(),
      refreshCache: refresh,
    );
    return Query$repositoryInfo.fromJson(response.data!);
  }

  // ============================================================================
  // README
  // ============================================================================

  /// Fetches the rendered HTML of the repository's README.
  ///
  /// Uses the `application/vnd.github.html` media type so the API returns
  /// pre-rendered HTML directly.
  ///
  /// [dir] optionally scopes the lookup to a sub-directory, e.g. `profile`
  /// for org profile READMEs at `{org}/.github/profile/README.md`.
  /// Ref: https://docs.github.com/en/rest/repos/contents#get-a-repository-readme-for-a-directory
  Future<String> fetchReadmeHtml({
    final String? branch,
    final String? dir,
  }) async {
    final String path =
        dir != null ? '${ref.apiPath}/readme/$dir' : '${ref.apiPath}/readme';
    final Response<String> response = await rest.get<String>(
      path,
      queryParameters: <String, dynamic>{
        'ref': branch,
      },
      requestHeaders: rest.acceptHeader(
        'application/vnd.github.html',
      ),
    );
    return response.data!;
  }

  // ============================================================================
  // Discussions
  // ============================================================================

  /// Fetches a single discussion by number (e.g. for events feed card).
  Future<Fragment$discussionCardFields?> fetchDiscussionByNumber(
      final int number) async {
    final GQLResponse response = await gql.query(
      documentNodeQuerydiscussionByNumber,
      Variables$Query$discussionByNumber(
        owner: ref.owner,
        name: ref.name,
        number: number,
      ).toJson(),
    );
    final data =
        Query$discussionByNumber.fromJson(response.data!);
    return data?.repository?.discussion;
  }

  // ============================================================================
  // Commits
  // ============================================================================

  /// Fetch a single commit via REST API.
  /// Ref: https://docs.github.com/en/rest/reference/repos#get-a-commit
  Future<CommitModel> getCommit(
    final CommitRef commit, {
    final bool refresh = false,
  }) async {
    final Response<Map<String, dynamic>> response =
        await rest.get<Map<String, dynamic>>(
      commit.apiPath,
      refreshCache: refresh,
    );
    return Commit.fromJson(response.data!);
  }

  /// Lists comments for a single commit. REST page/per_page.
  /// Ref: https://docs.github.com/en/rest/commits/comments#list-commit-comments
  Future<List<CommitCommentItem>> listCommitComments({
    required final CommitRef commitRef,
    final int page = 1,
    final int perPage = 20,
    final bool refresh = false,
  }) async {
    final Response<dynamic> response = await rest.get<dynamic>(
      '${commitRef.apiPath}/comments',
      queryParameters: <String, dynamic>{'page': page, 'per_page': perPage},
      refreshCache: refresh,
    );
    final List<Object?> list = extractListFromResponse<Object?>(response);
    return list
        .whereType<Map<String, dynamic>>()
        .map((m) => CommitCommentItem.fromJson(m))
        .toList();
  }

  /// Creates a comment on a commit.
  /// Ref: https://docs.github.com/en/rest/commits/comments#create-a-commit-comment
  Future<void> createCommitComment({
    required final CommitRef commitRef,
    required final String body,
  }) async {
    await rest.post<Map<String, dynamic>>(
      '${commitRef.apiPath}/comments',
      data: <String, dynamic>{'body': body},
    );
  }

  /// Compare two commits: returns commit list in range base...head.
  /// Used for push event drill-down where GQL has no SHA-range equivalent.
  /// Ref: https://docs.github.com/en/rest/commits/commits#compare-two-commits
  Future<List<CompareCommitSummary>> getCompareCommits({
    required final String base,
    required final String head,
    final bool refresh = false,
  }) async {
    final result = await getCompare(base: base, head: head, refresh: refresh);
    return result.commits;
  }

  /// Full compare response: ahead/behind counts, commits, and changed files.
  Future<CompareResult> getCompare({
    required final String base,
    required final String head,
    final bool refresh = false,
  }) async {
    final Response<Map<String, dynamic>> response =
        await rest.get<Map<String, dynamic>>(
      '${ref.apiPath}/compare/$base...$head',
      refreshCache: refresh,
    );
    final Map<String, dynamic> data = response.data!;
    return CompareResult.fromJson(data);
  }

  /// Get paginated commits list using GraphQL.
  /// Returns commit history connection with edges and pageInfo.
  /// Use ref for branch/ref, oid for specific commit, or neither for default branch.
  Future<Fragment$commitHistoryConnection> getCommitsListGQL({
    required final int first,
    final String? after,
    final String? path,
    final String? ref,
    final String? oid,
    final String? author,
    final bool refresh = false,
  }) async {
    // Build author filter if provided
    Input$CommitAuthor? authorFilter;
    if (author != null) {
      authorFilter = Input$CommitAuthor(
        emails: [author],
      );
    }

    // Determine which query to use based on parameters
    if (oid != null) {
      // Use commitsListByOid for specific commit OID
      final GQLResponse response = await gql.query(
        documentNodeQuerycommitsListByOid,
        Variables$Query$commitsListByOid(
          owner: this.ref.owner,
          repo: this.ref.name,
          oid: oid,
          first: first,
          after: after,
          path: path,
          author: authorFilter,
        ).toJson(),
        refreshCache: refresh,
      );
      final data =
          Query$commitsListByOid.fromJson(response.data!).repository!;
      if (data.object == null) {
        throw Exception('Commit not found');
      }

      final commit =
          data.object!.maybeWhen(
        commit: (final c) =>
            c,
        orElse: () {
          throw Exception(
            'Object is not a Commit (type: ${data.object!.$__typename})',
          );
        },
      );
      return commit.history;
    } else if (ref != null) {
      // Use commitsListByRef for specific branch/ref
      final GQLResponse response = await gql.query(
        documentNodeQuerycommitsListByRef,
        Variables$Query$commitsListByRef(
          owner: this.ref.owner,
          repo: this.ref.name,
          ref: ref,
          first: first,
          after: after,
          path: path,
          author: authorFilter,
        ).toJson(),
        refreshCache: refresh,
      );
      final data =
          Query$commitsListByRef.fromJson(response.data!).repository!;
      if (data.ref?.target == null) {
        throw Exception('Ref not found');
      }

      // Handle Commit or Tag -> Commit
      return data.ref!.target!.maybeWhen(
        commit:
            (final c) =>
                c.history,
        tag: (final t) {
          // Tag.target is also GitObject, need to check if it's a Commit
          return t.target.maybeWhen(
            commit:
                (final c) =>
                    c.history,
            orElse: () {
              throw Exception(
                'Tag target is not a Commit (type: ${t.target.$__typename})',
              );
            },
          );
        },
        orElse: () {
          throw Exception(
            'Target is not a Commit or Tag (type: ${data.ref!.target!.$__typename})',
          );
        },
      );
    } else {
      // Use commitsList for default branch
      final GQLResponse response = await gql.query(
        documentNodeQuerycommitsList,
        Variables$Query$commitsList(
          owner: this.ref.owner,
          repo: this.ref.name,
          first: first,
          after: after,
          path: path,
          author: authorFilter,
        ).toJson(),
        refreshCache: refresh,
      );
      final data =
          Query$commitsList.fromJson(response.data!).repository!;
      if (data.defaultBranchRef?.target == null) {
        throw Exception('Repository has no default branch');
      }

      // Handle Commit or Tag -> Commit
      return data.defaultBranchRef!.target!.maybeWhen(
        commit:
            (final c) =>
                c.history,
        tag: (final t) {
          // Tag.target is also GitObject, need to check if it's a Commit
          return t.target.maybeWhen(
            commit:
                (final c) =>
                    c.history,
            orElse: () {
              throw Exception(
                'Tag target is not a Commit (type: ${t.target.$__typename})',
              );
            },
          );
        },
        orElse: () {
          throw Exception(
            'Target is not a Commit or Tag (type: ${data.defaultBranchRef!.target!.$__typename})',
          );
        },
      );
    }
  }

  /// Load a page of commit edges for pagination (e.g. Code tab commit browser).
  ///
  /// [ref] branch ref (e.g. refs/heads/main), [oid] specific commit, or both null
  /// for default branch. Returns edges so caller can use lastItem?.cursor for next page.
  Future<List<Fragment$commitHistoryConnection$edges>> loadCommitHistoryEdges({
    required final int first,
    final String? after,
    final String? path,
    final String? ref,
    final String? oid,
    final bool refresh = false,
  }) async {
    final Fragment$commitHistoryConnection history = await getCommitsListGQL(
      first: first,
      after: after,
      path: path,
      ref: ref,
      oid: oid,
      refresh: refresh,
    );
    return history.edges
            ?.whereType<Fragment$commitHistoryConnection$edges>()
            .toList() ??
        <Fragment$commitHistoryConnection$edges>[];
  }

  /// Load a page of commit edges for the graph view (single ref).
  Future<List<Fragment$commitHistoryConnection$edges>> loadCommitsPage({
    required final String selectedBranch,
    final String? cursor,
    final int first = 20,
  }) async {
    final String fullRefName = selectedBranch.startsWith('refs/')
        ? selectedBranch
        : 'refs/heads/$selectedBranch';

    return loadCommitHistoryEdges(
      first: first,
      after: cursor,
      ref: fullRefName,
    );
  }

  /// Get commit info using GraphQL.
  Future<Query$commitInfo$repository$object$$Commit> getCommitInfo({
    required final String oid,
    final bool refresh = false,
  }) async {
    final GQLResponse response = await gql.query(
      documentNodeQuerycommitInfo,
      Variables$Query$commitInfo(
        owner: ref.owner,
        name: ref.name,
        oid: oid,
      ).toJson(),
      refreshCache: refresh,
    );
    final data =
        Query$commitInfo.fromJson(response.data!).repository!;
    if (data.object == null) {
      throw Exception('Commit not found');
    }
    return data.object!.maybeWhen(
      commit: (final commit) =>
          commit,
      orElse: () => throw Exception('Object is not a Commit'),
    );
  }

  // ============================================================================
  // Repository Metadata
  // ============================================================================

  /// Community profile metrics (health score, checklist).
  /// REST GET /repos/{owner}/{repo}/community/profile
  Future<CommunityProfile> getCommunityProfile({
    final bool refresh = false,
  }) async {
    final Response<Map<String, dynamic>> res =
        await rest.get<Map<String, dynamic>>(
      '${ref.apiPath}/community/profile',
      refreshCache: refresh,
    );
    final Map<String, dynamic>? data = res.data;
    if (data == null) return const CommunityProfile();
    return CommunityProfile.fromJson(data);
  }

  /// GitHub Pages info. Returns null when Pages is not configured (404).
  Future<PagesInfo?> getPagesInfo({final bool refresh = false}) async {
    try {
      final Response<Map<String, dynamic>> res =
          await rest.get<Map<String, dynamic>>(
        '${ref.apiPath}/pages',
        refreshCache: refresh,
      );
      final Map<String, dynamic>? data = res.data;
      if (data == null) return null;
      return PagesInfo.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
