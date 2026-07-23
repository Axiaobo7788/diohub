import 'package:built_collection/built_collection.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_graphql/schema.graphql.dart';
import 'package:diohub_graphql/queries/repositories/commit_info.graphql.dart';
import 'package:diohub_graphql/queries/repositories/commits_list.graphql.dart';
import 'package:diohub_graphql/queries/repositories/discussion_by_number.graphql.dart';
import 'package:diohub_graphql/queries/repositories/discussions_list.graphql.dart';
import 'package:diohub_graphql/queries/repositories/projects_list.graphql.dart';
import 'package:diohub_graphql/queries/repositories/repo_info.graphql.dart';
import 'package:diohub_graphql/queries/repositories/repo_lists.graphql.dart';
import 'package:diohub_graphql/queries/repositories/repo_star_watch.graphql.dart';
import 'package:diohub_graphql/queries/repositories/stargazers.graphql.dart';
import 'package:diohub_graphql/queries/repositories/forks.graphql.dart';
import 'package:diohub_graphql/queries/repositories/watchers.graphql.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_graphql/fragments/discussion_card_fields.graphql.dart';
import 'package:diohub_models/models/commits/commit_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/community_profile.dart';
import 'package:diohub_models/models/repositories/fork_repo_result.dart';
import 'package:diohub_models/models/repositories/merge_upstream_result.dart';
import 'package:diohub_models/models/repositories/pages_info.dart';
import 'package:diohub_models/models/repositories/commit_comment_item.dart';
import 'package:diohub_models/models/repositories/repo_setting_update.dart';
import 'package:diohub_models/models/repositories/secret_scanning_alert.dart';
import 'package:diohub_models/models/repositories/star_mutation_result.dart';
import 'package:diohub_models/models/repository/compare_result.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub/models/repository_contributor_preview.dart';
import 'package:diohub/models/repository_document.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:lens_annotations/lens_annotations.dart';
import 'package:diohub/services/repositories/repo_content_service.dart';
import 'package:diohub/services/repositories/repo_mutation_service.dart';
import 'package:diohub/services/repositories/repo_list_service.dart';

/// Unified repository service facade that delegates to focused services:
/// - [RepoContentService]: Content read operations (README, discussions, commits, compare)
/// - [RepoMutationService]: Mutations (star, watch, archive, fork, settings, transfer, delete)
/// - [RepoListService]: Paginated list operations (stargazers, forks, watchers, discussions, projects)
///
/// This facade maintains backward compatibility while providing better code organization.
@LensService(group: 'repo')
class RepositoryServices extends EntityService<RepoRef> {
  RepositoryServices(super.apiClient, super.ref);

  // Lazy-initialized delegate services
  late final RepoContentService _content = RepoContentService(apiClient, ref);
  late final RepoMutationService _mutation = RepoMutationService(apiClient, ref);
  late final RepoListService _list = RepoListService(apiClient, ref);

  // ============================================================================
  // CONTENT SERVICE DELEGATION (15 methods)
  // ============================================================================

  /// Fetch only the fields required by repository cards.
  Future<RepoCardData> fetchRepositoryCardGraphQL({
    final bool refresh = false,
  }) => _content.fetchRepositoryCardGraphQL(refresh: refresh);

  /// Fetch repository info via GraphQL.
  Future<RepoInfo> fetchRepositoryGraphQL({
    final bool refresh = false,
    final String? initialRef,
    final String? viewer,
  }) =>
      _content.fetchRepositoryGraphQL(
        refresh: refresh,
        initialRef: initialRef,
        viewer: viewer,
      );

  /// Fetch repository info (full query data with counts).
  Future<RepoInfoData> fetchRepositoryGraphQLFull({
    final bool refresh = false,
    final String? initialRef,
    final String? viewer,
  }) =>
      _content.fetchRepositoryGraphQLFull(
        refresh: refresh,
        initialRef: initialRef,
        viewer: viewer,
      );

  /// Fetch README HTML.
  Future<String> fetchReadmeHtml({
    final String? branch,
    final String? dir,
  }) =>
      _content.fetchReadmeHtml(branch: branch, dir: dir);

  /// Fetch a rendered CONTRIBUTING or SECURITY document on demand.
  Future<RepositoryDocument?> fetchRepositoryDocumentHtml({
    required final RepositoryDocumentKind kind,
    required final String branch,
  }) => _content.fetchRepositoryDocumentHtml(kind: kind, branch: branch);

  /// Fetch a single discussion by number.
  Future<Fragment$discussionCardFields?> fetchDiscussionByNumber(final int number) =>
      _content.fetchDiscussionByNumber(number);

  /// Fetch a single commit via REST.
  Future<CommitModel> getCommit(
    final CommitRef commit, {
    final bool refresh = false,
  }) =>
      _content.getCommit(commit, refresh: refresh);

  /// List commit comments (REST pagination).
  Future<List<CommitCommentItem>> listCommitComments({
    required final CommitRef commitRef,
    final int page = 1,
    final int perPage = 20,
    final bool refresh = false,
  }) =>
      _content.listCommitComments(
        commitRef: commitRef,
        page: page,
        perPage: perPage,
        refresh: refresh,
      );

  /// Create a commit comment.
  Future<void> createCommitComment({
    required final CommitRef commitRef,
    required final String body,
  }) =>
      _content.createCommitComment(commitRef: commitRef, body: body);

  /// Compare two commits (list only).
  Future<List<CompareCommitSummary>> getCompareCommits({
    required final String base,
    required final String head,
    final bool refresh = false,
  }) =>
      _content.getCompareCommits(base: base, head: head, refresh: refresh);

  /// Compare two commits (full result).
  Future<CompareResult> getCompare({
    required final String base,
    required final String head,
    final bool refresh = false,
  }) =>
      _content.getCompare(base: base, head: head, refresh: refresh);

  /// Get commits list via GraphQL.
  Future<CommitHistory> getCommitsListGQL({
    required final int first,
    final String? after,
    final String? path,
    final String? ref,
    final String? oid,
    final String? author,
    final bool refresh = false,
  }) =>
      _content.getCommitsListGQL(
        first: first,
        after: after,
        path: path,
        ref: ref,
        oid: oid,
        author: author,
        refresh: refresh,
      );

  /// Load commit history edges for pagination.
  Future<List<CommitEdge>> loadCommitHistoryEdges({
    required final int first,
    final String? after,
    final String? path,
    final String? ref,
    final String? oid,
    final bool refresh = false,
  }) =>
      _content.loadCommitHistoryEdges(
        first: first,
        after: after,
        path: path,
        ref: ref,
        oid: oid,
        refresh: refresh,
      );

  /// Load commits page for graph view.
  Future<List<CommitEdge>> loadCommitsPage({
    required final String selectedBranch,
    final String? cursor,
    final int first = 20,
  }) =>
      _content.loadCommitsPage(
        selectedBranch: selectedBranch,
        cursor: cursor,
        first: first,
      );

  /// Get commit info via GraphQL.
  Future<CommitInfo> getCommitInfo({
    required final String oid,
    final bool refresh = false,
  }) =>
      _content.getCommitInfo(oid: oid, refresh: refresh);

  /// Get community profile.
  Future<CommunityProfile> getCommunityProfile({
    final bool refresh = false,
  }) =>
      _content.getCommunityProfile(refresh: refresh);

  /// Get GitHub Pages info.
  Future<PagesInfo?> getPagesInfo({final bool refresh = false}) =>
      _content.getPagesInfo(refresh: refresh);

  // ============================================================================
  // MUTATION SERVICE DELEGATION (18 methods)
  // ============================================================================

  /// Pin an issue comment.
  Future<void> pinIssueComment(final BigInt commentId) =>
      _mutation.pinIssueComment(commentId);

  /// Unpin an issue comment.
  Future<void> unpinIssueComment(final BigInt commentId) =>
      _mutation.unpinIssueComment(commentId);

  /// Check if repository is starred.
  Future<HasStarredRepo> isStarred() => _mutation.isStarred();

  /// Star or unstar repository.
  @Lens(
    'star_repository',
    'Star or unstar a repository',
    category: ToolCategory.repository,
    access: ToolAccess.write,
  )
  Future<StarMutationResult?> changeStar({
    @Desc('Whether to star the repository') required final bool isStarred,
    @Desc('Repository node ID') required final String repoNodeId,
  }) =>
      _mutation.changeStar(isStarred: isStarred, repoNodeId: repoNodeId);

  /// Check if subscribed to repository.
  Future<HasWatchedRepo> isSubscribed() => _mutation.isSubscribed();

  /// Update repository subscription.
  @Lens(
    'watch_repository',
    'Update repository watch/subscription status',
    category: ToolCategory.repository,
    access: ToolAccess.write,
  )
  Future<Enum$SubscriptionState?> subscribeToRepo({
    @Desc('Repository node ID') required final String repoNodeId,
    @Desc('Subscription state') required final Enum$SubscriptionState state,
  }) =>
      _mutation.subscribeToRepo(repoNodeId: repoNodeId, state: state);

  /// Update repository topics.
  Future<List<String>?> updateTopics({
    required final String repositoryId,
    required final List<String> topicNames,
  }) =>
      _mutation.updateTopics(repositoryId: repositoryId, topicNames: topicNames);

  /// Set repository archived state.
  @Lens(
    'archive_repository',
    'Archive or unarchive a repository',
    category: ToolCategory.repository,
    access: ToolAccess.write,
  )
  Future<void> setArchived({
    @Desc('Repository ID') required final String repositoryId,
    @Desc('Whether to archive') required final bool archived,
  }) =>
      _mutation.setArchived(repositoryId: repositoryId, archived: archived);

  /// Fork repository.
  @Lens(
    'fork_repository',
    'Create a fork of this repository',
    category: ToolCategory.repository,
    access: ToolAccess.write,
  )
  Future<ForkRepoResult> forkRepo({
    @Desc('Organization to fork to') final String? organization,
    @Desc('Name for the fork') final String? name,
    @Desc('Only fork default branch') final bool? defaultBranchOnly,
  }) =>
      _mutation.forkRepo(
        organization: organization,
        name: name,
        defaultBranchOnly: defaultBranchOnly,
      );

  /// Sync fork with upstream.
  Future<MergeUpstreamResult> syncFork({final String? branch}) =>
      _mutation.syncFork(branch: branch);

  /// Update repository settings.
  Future<void> updateSetting(final RepoSettingUpdate update) =>
      _mutation.updateSetting(update);

  /// Transfer repository to new owner.
  Future<void> transferRepo({
    required final String newOwner,
    final List<int>? teamIds,
  }) =>
      _mutation.transferRepo(newOwner: newOwner, teamIds: teamIds);

  /// Delete repository.
  Future<void> deleteRepo() => _mutation.deleteRepo();

  /// Clone template repository.
  Future<CloneTemplateResult?> cloneTemplateRepository({
    required String name,
    required String ownerId,
    required Enum$RepositoryVisibility visibility,
    String? description,
    bool includeAllBranches = false,
  }) =>
      _mutation.cloneTemplateRepository(
        name: name,
        ownerId: ownerId,
        visibility: visibility,
        description: description,
        includeAllBranches: includeAllBranches,
      );

  /// Add item to Project V2.
  Future<bool> addProjectV2ItemById({
    required final String projectId,
    required final String contentId,
  }) =>
      _mutation.addProjectV2ItemById(
        projectId: projectId,
        contentId: contentId,
      );

  /// Delete Project V2 item.
  Future<bool> deleteProjectV2Item({
    required final String projectId,
    required final String itemId,
  }) =>
      _mutation.deleteProjectV2Item(projectId: projectId, itemId: itemId);

  /// Re-request check suite.
  Future<void> rerequestCheckSuite({required final int checkSuiteId}) =>
      _mutation.rerequestCheckSuite(checkSuiteId: checkSuiteId);

  /// Update secret scanning alert.
  Future<SecretScanningAlert?> updateSecretScanningAlert({
    required final int number,
    required final String state,
    final String? resolution,
    final String? resolutionComment,
  }) =>
      _mutation.updateSecretScanningAlert(
        number: number,
        state: state,
        resolution: resolution,
        resolutionComment: resolutionComment,
      );

  // ============================================================================
  // LIST SERVICE DELEGATION (7 methods)
  // ============================================================================

  Future<List<RepositoryContributorPreview>> fetchContributorPreview({
    final int limit = 12,
    final bool refresh = false,
  }) => _list.fetchContributorPreview(limit: limit, refresh: refresh);

  /// Fetch discussions (paginated).
  Future<PaginatedResult<DiscussionEdge>>
      fetchDiscussionsPaginated({
    required final int first,
    final String? after,
    final Input$DiscussionOrder? orderBy,
    final List<Enum$DiscussionState>? states,
    final bool refresh = false,
  }) =>
          _list.fetchDiscussionsPaginated(
            first: first,
            after: after,
            orderBy: orderBy,
            states: states,
            refresh: refresh,
          );

  /// Fetch projects (paginated).
  Future<PaginatedResult<ProjectV2Edge>>
      fetchProjectsPaginated({
    required final int first,
    final String? after,
    final Input$ProjectV2Order? orderBy,
    final bool refresh = false,
  }) =>
          _list.fetchProjectsPaginated(
            first: first,
            after: after,
            orderBy: orderBy,
            refresh: refresh,
          );

  /// List Projects V2 for picker.
  Future<
          PaginatedResult<
              ProjectV2PickerEdge?>>
      listProjectsV2GQL({
    required final int first,
    final String? after,
  }) =>
          _list.listProjectsV2GQL(first: first, after: after);

  /// Fetch stargazers (paginated).
  Future<PaginatedResult<StargazerEdge>>
      fetchStargazersPaginated({
    required final int first,
    final String? after,
    final bool refresh = false,
  }) =>
          _list.fetchStargazersPaginated(
            first: first,
            after: after,
            refresh: refresh,
          );

  /// Fetch stargazer timestamps for star history chart (capped at maxPages * 100).
  Future<List<DateTime>> fetchStargazerTimestamps({
    int maxPages = 5,
  }) =>
      _list.fetchStargazerTimestamps(maxPages: maxPages);

  /// Fetch forks (paginated).
  Future<PaginatedResult<ForkEdge>>
      fetchForksPaginated({
    required final int first,
    final String? after,
    final Input$RepositoryOrder? orderBy,
    final bool refresh = false,
  }) =>
          _list.fetchForksPaginated(
            first: first,
            after: after,
            orderBy: orderBy,
            refresh: refresh,
          );

  /// Fetch watchers (paginated).
  Future<PaginatedResult<WatcherEdge>>
      fetchWatchersPaginated({
    required final int first,
    final String? after,
    final bool refresh = false,
  }) =>
          _list.fetchWatchersPaginated(
            first: first,
            after: after,
            refresh: refresh,
          );

  /// List secret scanning alerts.
  Future<List<SecretScanningAlert>> listSecretScanningAlerts({
    final int page = 1,
    final int perPage = 30,
    final String? state,
  }) =>
      _list.listSecretScanningAlerts(
        page: page,
        perPage: perPage,
        state: state,
      );
}
