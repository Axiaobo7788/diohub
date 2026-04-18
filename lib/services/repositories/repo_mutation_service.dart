import 'package:dio/dio.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub_graphql/schema.graphql.dart';
import 'package:diohub_graphql/queries/repositories/repo_mutations.graphql.dart';
import 'package:diohub_graphql/queries/repositories/repo_star_watch.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/project_mutations.graphql.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/fork_repo_result.dart';
import 'package:diohub_models/models/repositories/merge_upstream_result.dart';
import 'package:diohub_models/models/repositories/repo_setting_update.dart';
import 'package:diohub_models/models/repositories/secret_scanning_alert.dart';
import 'package:diohub_models/models/repositories/star_mutation_result.dart';
import 'package:diohub/services/base/base_service.dart';

/// Service for repository mutation operations:
/// - Star/unstar
/// - Watch/unwatch (subscriptions)
/// - Topics management
/// - Archive/unarchive
/// - Fork
/// - Settings updates
/// - Transfer ownership
/// - Delete
/// - Sync fork with upstream
/// - Project V2 item management (add/remove)
/// - Secret scanning alert updates
/// - Check suite re-requests
/// - Issue comment pin/unpin
class RepoMutationService extends EntityService<RepoRef> {
  RepoMutationService(super.apiClient, super.ref);

  // ============================================================================
  // Issue Comment Pinning (used by IssueCard actions)
  // ============================================================================

  /// Pin an issue comment in this repository (REST API).
  Future<void> pinIssueComment(final BigInt commentId) async {
    await rest.put<void>(
      '${ref.apiPath}/issues/comments/${commentId.toString()}/pin',
    );
  }

  /// Unpin an issue comment in this repository (REST API).
  Future<void> unpinIssueComment(final BigInt commentId) async {
    await rest.delete<void>(
      '${ref.apiPath}/issues/comments/${commentId.toString()}/pin',
    );
  }

  // ============================================================================
  // Star/Watch
  // ============================================================================

  /// Check if the authenticated user has starred this repository.
  /// Ref: https://docs.github.com/en/rest/reference/activity#check-if-a-repository-is-starred-by-the-authenticated-user
  Future<Query$hasStarred$repository> isStarred() async {
    final GQLResponse res = await gql.query(
      documentNodeQueryhasStarred,
      Variables$Query$hasStarred(
        name: ref.name,
        owner: ref.owner,
      ).toJson(),
      refreshCache: true,
    );
    return Query$hasStarred.fromJson(res.data!).repository!;
  }

  /// Toggle star on a repository via GraphQL.
  ///
  /// [repoNodeId] is the global node ID of the repository.
  /// Returns updated star state from the mutation for optimistic UI updates.
  Future<StarMutationResult?> changeStar({
    required final bool isStarred,
    required final String repoNodeId,
  }) async {
    if (isStarred) {
      final GQLResponse res = await gql.mutation(
        documentNodeMutationremoveStar,
        Variables$Mutation$removeStar(
          starrableId: repoNodeId,
        ).toJson(),
      );
      final starrable =
          Mutation$removeStar.fromJson(res.data!)?.removeStar?.starrable;
      return starrable != null
          ? StarMutationResult(
              viewerHasStarred: starrable.viewerHasStarred,
              stargazerCount: starrable.stargazerCount,
            )
          : null;
    } else {
      final GQLResponse res = await gql.mutation(
        documentNodeMutationaddStar,
        Variables$Mutation$addStar(
          starrableId: repoNodeId,
        ).toJson(),
      );
      final starrable =
          Mutation$addStar.fromJson(res.data!)?.addStar?.starrable;
      return starrable != null
          ? StarMutationResult(
              viewerHasStarred: starrable.viewerHasStarred,
              stargazerCount: starrable.stargazerCount,
            )
          : null;
    }
  }

  /// Check if the authenticated user is subscribed to this repository.
  Future<Query$hasWatched$repository> isSubscribed() async =>
      Query$hasWatched.fromJson(
        (await gql.query(
          documentNodeQueryhasWatched,
          Variables$Query$hasWatched(
            owner: ref.owner,
            name: ref.name,
          ).toJson(),
        ))
            .data!,
      ).repository!;

  /// Update repository subscription via GraphQL.
  ///
  /// [repoNodeId] is the global node ID of the repository.
  /// [state] is the desired subscription state.
  Future<Enum$SubscriptionState?> subscribeToRepo({
    required final String repoNodeId,
    required final Enum$SubscriptionState state,
  }) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationupdateRepositorySubscription,
      Variables$Mutation$updateRepositorySubscription(
        subscribableId: repoNodeId,
        state: state,
      ).toJson(),
    );
    final data =
        Mutation$updateRepositorySubscription.fromJson(res.data!);
    return data?.updateSubscription?.subscribable?.viewerSubscription;
  }

  // ============================================================================
  // Topics
  // ============================================================================

  /// Update repository topics via GraphQL.
  /// [repositoryId] is the global node ID of the repository.
  /// Returns invalid topic names if any, or null on success.
  Future<List<String>?> updateTopics({
    required final String repositoryId,
    required final List<String> topicNames,
  }) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationupdateRepositoryTopics,
      Variables$Mutation$updateRepositoryTopics(
        repositoryId: repositoryId,
        topicNames: topicNames,
      ).toJson(),
    );
    final data =
        Mutation$updateRepositoryTopics.fromJson(res.data!);
    final invalid = data?.updateTopics?.invalidTopicNames;
    return invalid != null && invalid.isNotEmpty ? invalid : null;
  }

  // ============================================================================
  // Archive
  // ============================================================================

  /// Set repository archived state via GraphQL. Single entry point for archive/unarchive.
  Future<void> setArchived({
    required final String repositoryId,
    required final bool archived,
  }) async {
    if (archived) {
      await gql.mutation(
        documentNodeMutationarchiveRepository,
        Variables$Mutation$archiveRepository(
          repositoryId: repositoryId,
        ).toJson(),
      );
    } else {
      await gql.mutation(
        documentNodeMutationunarchiveRepository,
        Variables$Mutation$unarchiveRepository(
          repositoryId: repositoryId,
        ).toJson(),
      );
    }
  }

  // ============================================================================
  // Fork
  // ============================================================================

  /// Fork repository via REST (POST /repos/{owner}/{repo}/forks).
  /// Returns the created fork payload.
  Future<ForkRepoResult> forkRepo({
    final String? organization,
    final String? name,
    final bool? defaultBranchOnly,
  }) async {
    final Response<Map<String, dynamic>> res =
        await rest.post<Map<String, dynamic>>(
      '${ref.apiPath}/forks',
      data: <String, dynamic>{
        if (organization != null) 'organization': organization,
        if (name != null) 'name': name,
        if (defaultBranchOnly != null) 'default_branch_only': defaultBranchOnly,
      },
    );
    return ForkRepoResult.fromJson(res.data!);
  }

  /// Sync fork with upstream via REST (POST merge-upstream).
  Future<MergeUpstreamResult> syncFork({final String? branch}) async {
    final Response<Map<String, dynamic>> res =
        await rest.post<Map<String, dynamic>>(
      '${ref.apiPath}/merge-upstream',
      data: <String, dynamic>{if (branch != null) 'branch': branch},
    );
    return MergeUpstreamResult.fromJson(res.data!);
  }

  // ============================================================================
  // Settings, Transfer, Delete
  // ============================================================================

  /// Type-safe repository setting update. Single REST PATCH; only set fields are sent.
  Future<void> updateSetting(final RepoSettingUpdate update) async {
    final Map<String, dynamic> body = update.toRestBody();
    if (body.isEmpty) return;
    await rest.patch<Map<String, dynamic>>(ref.apiPath, data: body);
  }

  /// Transfer repository to new owner via REST POST.
  Future<void> transferRepo({
    required final String newOwner,
    final List<int>? teamIds,
  }) async {
    await rest.post<Map<String, dynamic>>(
      '${ref.apiPath}/transfer',
      data: <String, dynamic>{
        'new_owner': newOwner,
        if (teamIds != null && teamIds.isNotEmpty) 'team_ids': teamIds,
      },
    );
  }

  /// Delete repository via REST DELETE. Caller should navigate away on success.
  Future<void> deleteRepo() async {
    await rest.delete<void>(ref.apiPath);
  }

  // ============================================================================
  // Template Cloning
  // ============================================================================

  /// Create a repository from a template (GQL cloneTemplateRepository).
  /// Uses [ref.nodeId] as the template repository ID.
  Future<CloneTemplateResult?> cloneTemplateRepository({
    required String name,
    required String ownerId,
    required Enum$RepositoryVisibility visibility,
    String? description,
    bool includeAllBranches = false,
  }) async {
    final response = await gql.mutation(
      documentNodeMutationcloneTemplateRepository,
      Variables$Mutation$cloneTemplateRepository(
        input: Input$CloneTemplateRepositoryInput(
          repositoryId: ref.nodeId!,
          name: name,
          ownerId: ownerId,
          visibility: visibility,
          description: description,
          includeAllBranches: includeAllBranches,
        ),
      ).toJson(),
    );
    final data = Mutation$cloneTemplateRepository.fromJson(response.data!);
    return data?.cloneTemplateRepository?.repository;
  }

  // ============================================================================
  // Project V2 Item Management
  // ============================================================================

  /// Add an issue or PR (by node ID) to a project V2.
  /// Run: dart run build_runner build --delete-conflicting-outputs
  Future<bool> addProjectV2ItemById({
    required final String projectId,
    required final String contentId,
  }) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationaddProjectV2ItemById,
      Variables$Mutation$addProjectV2ItemById(
        input: Input$AddProjectV2ItemByIdInput(
          projectId: projectId,
          contentId: contentId,
        ),
      ).toJson(),
    );
    return res.data != null && res.errors == null;
  }

  /// Remove a project V2 item.
  /// Run: dart run build_runner build --delete-conflicting-outputs
  Future<bool> deleteProjectV2Item({
    required final String projectId,
    required final String itemId,
  }) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationdeleteProjectV2Item,
      Variables$Mutation$deleteProjectV2Item(
        input: Input$DeleteProjectV2ItemInput(
          projectId: projectId,
          itemId: itemId,
        ),
      ).toJson(),
    );
    return res.data != null && res.errors == null;
  }

  // ============================================================================
  // Security & Checks
  // ============================================================================

  /// Re-requests a check suite, triggering all check runs to re-run.
  /// POST /repos/{owner}/{repo}/check-suites/{checkSuiteId}/rerequest
  /// Returns 201 on success.
  Future<void> rerequestCheckSuite({required final int checkSuiteId}) async {
    await rest.post<Map<String, dynamic>>(
      '${ref.apiPath}/check-suites/$checkSuiteId/rerequest',
    );
  }

  /// Update a secret scanning alert (e.g. resolve with resolution).
  /// Returns the updated alert on success.
  Future<SecretScanningAlert?> updateSecretScanningAlert({
    required final int number,
    required final String state,
    final String? resolution,
    final String? resolutionComment,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{'state': state};
    if (resolution != null && resolution.isNotEmpty)
      body['resolution'] = resolution;
    if (resolutionComment != null && resolutionComment.isNotEmpty) {
      body['resolution_comment'] = resolutionComment;
    }
    final Response<Map<String, dynamic>> res =
        await rest.patch<Map<String, dynamic>>(
      '${ref.apiPath}/secret-scanning/alerts/$number',
      data: body,
    );
    final Map<String, dynamic>? data = res.data;
    if (data == null) return null;
    return SecretScanningAlert.fromJson(data);
  }
}
