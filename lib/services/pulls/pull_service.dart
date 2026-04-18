import 'package:dio/dio.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/services/base/rest_pagination_helper.dart';
import 'package:diohub_graphql/schema.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/pull_mutations.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_reactions.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_graphql/queries/issues_pulls/pr_review_checks.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/pr_review_comments.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/pr_merge_mutations.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/pr_review_mutations.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/pr_review_threads.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/pull_commits_list.graphql.dart';
import 'package:lens_annotations/lens_annotations.dart';
import 'package:diohub_graphql/queries/issues_pulls/pull_files.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/auto_merge_mutations.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/merge_queue_mutations.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/draft_mutations.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/update_branch_mutation.graphql.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart' show PaginatedResult;
import 'package:diohub/common/pagination/page_size.dart';
import 'package:diohub_models/models/commits/commit_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/issues/issue_pull_mutation_result.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:diohub/services/capabilities/capabilities.dart';
import 'package:diohub/services/capabilities/capable_entity_mixin.dart';
import 'package:diohub_models/models/issues/subject_mutation_payload.dart';

/// Return type for [getReviewThreadReplies] with proper pagination metadata.
class ThreadRepliesPage {
  const ThreadRepliesPage({
    required this.edges,
    required this.hasNextPage,
    required this.endCursor,
    required this.totalCount,
  });

  final List<
          Query$reviewThreadCommentsQuery$node$$PullRequestReviewThread$comments$edges?>
      edges;
  final bool hasNextPage;
  final String? endCursor;
  final int totalCount;
}

@LensService(group: 'pulls')
class PullService extends EntityService<PullRequestRef> with CapableEntityMixin<PullRequestRef> {
  PullService(super.apiClient, super.ref);

  String get _nodeId => ref.nodeId!;

  // ── Lens tool forwarding (capability methods on this entity) ──
  @Lens(
    'lock_pull_request',
    'Lock a pull request conversation',
    category: ToolCategory.pullRequest,
    access: ToolAccess.write,
  )
  Future<LockStateResult?> lock({@Desc('Lock reason') final Enum$LockReason? reason}) =>
      lockable.lock(reason: reason);
  
  @Lens(
    'unlock_pull_request',
    'Unlock a pull request conversation',
    category: ToolCategory.pullRequest,
    access: ToolAccess.write,
  )
  Future<LockStateResult?> unlock() => lockable.unlock();
  
  @Lens(
    'add_labels_to_pull',
    'Add labels to this pull request',
    category: ToolCategory.pullRequest,
    access: ToolAccess.write,
  )
  Future<LabelsMutationResult?> addLabels(@Desc('Label IDs') final List<String> labelIds) =>
      labelable.addLabels(labelIds);
  
  @Lens(
    'remove_labels_from_pull',
    'Remove labels from this pull request',
    category: ToolCategory.pullRequest,
    access: ToolAccess.write,
  )
  Future<LabelsMutationResult?> removeLabels(@Desc('Label IDs') final List<String> labelIds) =>
      labelable.removeLabels(labelIds);
  
  @Lens(
    'update_pull_subscription',
    'Update subscription to this pull request',
    category: ToolCategory.pullRequest,
    access: ToolAccess.write,
  )
  Future<Enum$SubscriptionState?> updateSubscription(
          @Desc('Subscription state') final Enum$SubscriptionState state) =>
      subscribable.updateSubscription(state);
  
  @Lens(
    'add_pull_comment',
    'Add a comment to this pull request',
    category: ToolCategory.pullRequest,
    access: ToolAccess.write,
  )
  Future<CommentAddedResult?> addComment({@Desc('Comment body') required final String body}) =>
      commentable.addComment(body: body);
  
  @Lens(
    'add_pull_reaction',
    'Add a reaction to this pull request',
    category: ToolCategory.pullRequest,
    access: ToolAccess.write,
  )
  Future<List<Fragment$reactorsGroup>?> addReaction(
          @Desc('Reaction content') final Enum$ReactionContent content) =>
      reactable.addReaction(content);
  
  @Lens(
    'remove_pull_reaction',
    'Remove a reaction from this pull request',
    category: ToolCategory.pullRequest,
    access: ToolAccess.write,
  )
  Future<List<Fragment$reactorsGroup>?> removeReaction(
          @Desc('Reaction content') final Enum$ReactionContent content) =>
      reactable.removeReaction(content);
  
  @Lens(
    'add_pull_assignees',
    'Add assignees to this pull request',
    category: ToolCategory.pullRequest,
    access: ToolAccess.write,
  )
  Future<AssigneesMutationResult?> addAssignees(
          @Desc('Assignee IDs') final List<String> assigneeIds) =>
      assignable.addAssignees(assigneeIds);
  
  @Lens(
    'remove_pull_assignees',
    'Remove assignees from this pull request',
    category: ToolCategory.pullRequest,
    access: ToolAccess.write,
  )
  Future<AssigneesMutationResult?> removeAssignees(
          @Desc('Assignee IDs') final List<String> assigneeIds) =>
      assignable.removeAssignees(assigneeIds);

  // ── Lens comment-scoped forwarding (require comment node id as first arg) ──
  Future<List<CommentEditHistoryItem>> getEditHistory(
    final String commentNodeId, {
    final int first = 20,
    final String? after,
  }) =>
      CommentNodeService(apiClient, commentNodeId)
          .getEditHistory(first: first, after: after);
  Future<IssueCommentUpdate?> updateComment(
    final String commentNodeId,
    final String body,
  ) =>
      updateCommentById(commentNodeId, body);
  Future<void> deleteComment(final String commentNodeId) =>
      deleteCommentById(commentNodeId);
  Future<void> minimize(
    final String commentNodeId,
    final Enum$ReportedContentClassifiers classifier,
  ) =>
      MinimizableService(apiClient, commentNodeId).minimize(classifier);
  Future<void> unminimize(final String commentNodeId) =>
      MinimizableService(apiClient, commentNodeId).unminimize();

  /// Fetch paginated PR commits via GraphQL. Requires PR context.
  Future<
          PaginatedResult<
              Query$pullCommitsList$repository$pullRequest$commits$edges?>>
      getPullCommitsGQL({
    required final int first,
    final String? after,
    final bool refresh = false,
  }) async {
    final GQLResponse response = await gql.query(
      documentNodeQuerypullCommitsList,
      Variables$Query$pullCommitsList(
        owner: ref.repo.owner,
        repo: ref.repo.name,
        number: ref.number,
        first: first,
        after: after,
      ).toJson(),
      refreshCache: refresh,
    );
    final Query$pullCommitsList data =
        Query$pullCommitsList.fromJson(response.data!);
    final Query$pullCommitsList$repository$pullRequest? pullRequest =
        data.repository?.pullRequest;
    if (pullRequest == null) {
      throw Exception('Pull request not found');
    }
    return PaginatedResult.fromEdges(
      pullRequest.commits.edges?.toList() ?? [],
      pullRequest.commits.pageInfo.hasNextPage,
      pullRequest.commits.pageInfo.endCursor,
    );
  }

  /// Fetch paginated PR changed files via GraphQL.
  /// Returns edges so the caller can use lastItem?.cursor for the next page.
  Future<List<Query$pullFiles$repository$pullRequest$files$edges>>
      getPullFilesGQL({
    required final int first,
    final String? after,
    final bool refresh = false,
  }) async {
    final result =
        await getPullFilesGQLPage(first: first, after: after, refresh: refresh);
    return result.items
        .whereType<Query$pullFiles$repository$pullRequest$files$edges>()
        .toList();
  }

  /// Fetch one page of PR changed files via GraphQL.
  /// Returns [PaginatedResult] with items, [hasNextPage], and [endCursor].
  Future<PaginatedResult<Query$pullFiles$repository$pullRequest$files$edges?>>
      getPullFilesGQLPage({
    required final int first,
    final String? after,
    final bool refresh = false,
  }) async {
    final GQLResponse response = await gql.query(
      documentNodeQuerypullFiles,
      Variables$Query$pullFiles(
        owner: ref.repo.owner,
        repo: ref.repo.name,
        number: ref.number,
        first: first,
        after: after,
      ).toJson(),
      refreshCache: refresh,
    );
    final Query$pullFiles? data = Query$pullFiles.fromJson(response.data!);
    final Query$pullFiles$repository$pullRequest$files? files =
        data?.repository?.pullRequest?.files;
    final List<Query$pullFiles$repository$pullRequest$files$edges?>? rawList =
        files?.edges?.toList();
    final List<Query$pullFiles$repository$pullRequest$files$edges?> list =
        rawList ?? <Query$pullFiles$repository$pullRequest$files$edges?>[];
    final bool hasNextPage = files?.pageInfo.hasNextPage ?? false;
    final String? endCursor = files?.pageInfo.endCursor;
    return PaginatedResult.fromEdges(list, hasNextPage, endCursor);
  }

  /// Fetch a single page of PR changed files with patch (diff) via REST.
  /// Use with [PaginationController] + [PageNumberForwardSource] for progressive loading.
  Future<List<DiffEntry>> getPullFilePatchesPage({
    required final int page,
    final int perPage = kDefaultPageSize,
    final bool refresh = false,
  }) async {
    final Response<dynamic> response = await rest.get<dynamic>(
      '${ref.apiPath}/files',
      queryParameters: <String, dynamic>{'page': page, 'per_page': perPage},
      refreshCache: refresh,
    );
    final List<Object?> items = extractListFromResponse<Object?>(response);
    if (items.isEmpty) return <DiffEntry>[];
    return items.map((final dynamic raw) {
      final Map<String, dynamic> item = raw as Map<String, dynamic>;
      return DiffEntry(
        filename: item['filename'] as String? ?? '',
        status: item['status'] as String?,
        additions: (item['additions'] as num?)?.toInt() ?? 0,
        deletions: (item['deletions'] as num?)?.toInt() ?? 0,
        changes: (item['changes'] as num?)?.toInt() ?? 0,
        patch: item['patch'] as String?,
        contentsUrl: null,
      );
    }).toList();
  }

  /// Fetch a single PR file's patch (diff) via REST. Pages through the files list
  /// until the given [path] is found. Returns null if not found.
  Future<DiffEntry?> getPullFilePatch(final String path) async {
    int page = 1;
    while (true) {
      final List<DiffEntry> batch = await getPullFilePatchesPage(
        page: page,
        perPage: kDefaultPageSize,
        refresh: page == 1,
      );
      if (batch.isEmpty) return null;
      for (final e in batch) {
        if (e.filename == path) return e;
      }
      if (batch.length < kDefaultPageSize) return null;
      page++;
    }
  }

  Future<List<Query$getPRReviewComments$node$$PullRequestReview$comments$edges?>>
      getPRReview(
    final String id, {
    required final bool refresh,
    final String? cursor,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerygetPRReviewComments,
      Variables$Query$getPRReviewComments(
        after: cursor,
        id: id,
      ).toJson(),
      refreshCache: refresh,
    );
    final data = Query$getPRReviewComments.fromJson(res.data!).node;
    if (data is Query$getPRReviewComments$node$$PullRequestReview) {
      return data.comments.edges?.toList() ?? [];
    }
    throw UnimplementedError();
  }

  Future<ThreadRepliesPage> getReviewThreadReplies(
    final String nodeID,
    final String? cursor, {
    required final bool refresh,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQueryreviewThreadCommentsQuery,
      Variables$Query$reviewThreadCommentsQuery(
        after: cursor,
        nodeID: nodeID,
      ).toJson(),
      refreshCache: refresh,
    );
    final node = Query$reviewThreadCommentsQuery.fromJson(res.data!).node;
    if (node is! Query$reviewThreadCommentsQuery$node$$PullRequestReviewThread) {
      throw StateError('Expected PullRequestReviewThread but got ${node?.$__typename}');
    }
    final comments = node.comments;
    return ThreadRepliesPage(
      edges: comments.edges?.toList() ?? [],
      hasNextPage: comments.pageInfo.hasNextPage,
      endCursor: comments.pageInfo.endCursor,
      totalCount: comments.totalCount,
    );
  }

  /// Fetches one page of PR review threads. Use [cursor] for pagination.
  Future<Query$getPullRequestReviewThreads?> getPullRequestReviewThreads({
    final String? cursor,
    final bool refresh = false,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerygetPullRequestReviewThreads,
      Variables$Query$getPullRequestReviewThreads(
        owner: ref.repo.owner,
        name: ref.repo.name,
        number: ref.number,
        after: cursor,
      ).toJson(),
      refreshCache: refresh,
    );
    if (res.data == null) return null;
    return Query$getPullRequestReviewThreads.fromJson(res.data!);
  }

  /// Viewer's pending (draft) review on the PR. Returns the GQL response; use
  /// [Query$getViewerPendingReview.node] and reviews to show rich state.
  Future<Query$getViewerPendingReview?> getViewerPendingReview(
    final String pullNodeId,
  ) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerygetViewerPendingReview,
      Variables$Query$getViewerPendingReview(
        pullNodeID: pullNodeId,
      ).toJson(),
    );
    return Query$getViewerPendingReview.fromJson(res.data!);
  }

  /// Reply to a review thread via GraphQL (addPullRequestReviewThreadReply).
  /// Call [getThreadForCommentId] first if you only have a comment ID.
  Future<bool> replyToThread(
    final String pullRequestReviewThreadId,
    final String body, {
    final String? pullRequestReviewId,
  }) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationaddPullRequestReviewThreadReply,
      Variables$Mutation$addPullRequestReviewThreadReply(
        pullRequestReviewThreadId: pullRequestReviewThreadId,
        body: body,
        pullRequestReviewId: pullRequestReviewId,
      ).toJson(),
    );
    return res.data != null;
  }

  /// Create a new review thread on a specific line of a file.
  /// If [pullRequestReviewId] is null, creates a standalone single-comment review.
  /// Returns the new thread's node ID, or null on failure.
  Future<String?> addReviewThread({
    required final String pullRequestId,
    final String? pullRequestReviewId,
    required final String body,
    required final String path,
    required final int line,
    required final Enum$DiffSide side,
    final int? startLine,
    final Enum$DiffSide? startSide,
    final Enum$PullRequestReviewThreadSubjectType? subjectType,
  }) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationaddPullRequestReviewThread,
      Variables$Mutation$addPullRequestReviewThread(
        pullRequestId: pullRequestId,
        pullRequestReviewId: pullRequestReviewId,
        body: body,
        path: path,
        line: line,
        side: side,
        startLine: startLine,
        startSide: startSide,
        subjectType: subjectType,
      ).toJson(),
    );
    if (res.data == null) return null;
    final Mutation$addPullRequestReviewThread? data =
        Mutation$addPullRequestReviewThread.fromJson(res.data!);
    return data?.addPullRequestReviewThread?.thread?.id;
  }

  /// Submit a pending pull request review (comment, approve, or request changes).
  Future<bool> submitPullRequestReview(
    final String pullRequestReviewId,
    final Enum$PullRequestReviewEvent event, {
    final String? body,
  }) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationsubmitPullRequestReview,
      Variables$Mutation$submitPullRequestReview(
        pullRequestReviewId: pullRequestReviewId,
        event: event,
        body: body,
      ).toJson(),
    );
    return res.data != null;
  }

  /// Delete (discard) a pending pull request review.
  Future<bool> deletePullRequestReview(
    final String pullRequestReviewId,
  ) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationdeletePullRequestReview,
      Variables$Mutation$deletePullRequestReview(
        pullRequestReviewId: pullRequestReviewId,
      ).toJson(),
    );
    return res.data != null;
  }

  /// Dismiss a pull request review with a message (maintainer/admin only).
  Future<bool> dismissPullRequestReview(
    final String pullRequestReviewId, {
    required final String message,
  }) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationdismissPullRequestReview,
      Variables$Mutation$dismissPullRequestReview(
        pullRequestReviewId: pullRequestReviewId,
        message: message,
      ).toJson(),
    );
    return res.data != null;
  }

  /// Update the body of a pull request review.
  Future<bool> updatePullRequestReview(
    final String pullRequestReviewId, {
    required final String body,
  }) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationupdatePullRequestReview,
      Variables$Mutation$updatePullRequestReview(
        pullRequestReviewId: pullRequestReviewId,
        body: body,
      ).toJson(),
    );
    return res.data != null;
  }

  /// Update a single review comment.
  Future<bool> updatePullRequestReviewComment(
    final String pullRequestReviewCommentId, {
    required final String body,
  }) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationupdatePullRequestReviewComment,
      Variables$Mutation$updatePullRequestReviewComment(
        pullRequestReviewCommentId: pullRequestReviewCommentId,
        body: body,
      ).toJson(),
    );
    return res.data != null;
  }

  /// Resolve a review thread.
  Future<bool> resolveReviewThread(final String threadId) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationresolveReviewThread,
      Variables$Mutation$resolveReviewThread(
        threadId: threadId,
      ).toJson(),
    );
    return res.data != null;
  }

  /// Unresolve a review thread.
  Future<bool> unresolveReviewThread(final String threadId) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationunresolveReviewThread,
      Variables$Mutation$unresolveReviewThread(
        threadId: threadId,
      ).toJson(),
    );
    return res.data != null;
  }

  /// Mark a file as viewed on the PR (GraphQL mutation).
  /// Uses [ref.nodeId]; ref must have nodeId set (e.g. pullRef.copyWith(nodeId: nodeId)).
  Future<bool> markFileAsViewed(final String path) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationmarkFileAsViewed,
      Variables$Mutation$markFileAsViewed(
        pullRequestId: _nodeId,
        path: path,
      ).toJson(),
    );
    return res.data != null;
  }

  /// Unmark a file as viewed on the PR (GraphQL mutation).
  /// Uses [ref.nodeId]; ref must have nodeId set.
  Future<bool> unmarkFileAsViewed(final String path) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationunmarkFileAsViewed,
      Variables$Mutation$unmarkFileAsViewed(
        pullRequestId: _nodeId,
        path: path,
      ).toJson(),
    );
    return res.data != null;
  }

  /// Merge a pull request via GraphQL. Returns the merged pull request from the
  /// mutation payload for state updates, or null on failure.
  /// Uses [ref.nodeId]; ref must have nodeId set.
  Future<Mutation$mergePullRequest$mergePullRequest$pullRequest?> mergePullRequest({
    final Enum$PullRequestMergeMethod? mergeMethod,
    final String? commitHeadline,
    final String? commitBody,
  }) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationmergePullRequest,
      Variables$Mutation$mergePullRequest(
        pullRequestId: _nodeId,
        mergeMethod: mergeMethod,
        commitHeadline: commitHeadline,
        commitBody: commitBody,
      ).toJson(),
    );
    if (res.data == null) return null;
    final Mutation$mergePullRequest? data =
        Mutation$mergePullRequest.fromJson(res.data!);
    return data?.mergePullRequest?.pullRequest;
  }

  /// Request reviews from users (and optionally teams) via GraphQL.
  /// Uses [ref.nodeId]; ref must have nodeId set.
  Future<bool> requestReviews({
    final List<String>? userIds,
    final List<String>? teamIds,
  }) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationrequestReviews,
      Variables$Mutation$requestReviews(
        pullRequestId: _nodeId,
        userIds: userIds,
        teamIds: teamIds,
      ).toJson(),
    );
    return res.data != null;
  }

  /// Update a pull request via GraphQL (title, body, assignees, labels, milestone, baseRef, state).
  /// Returns the updated pull request as typed payload for patching provider state, or null on failure.
  Future<SubjectMutationPayload?> updatePullRequest({
    final String? title,
    final String? body,
    final List<String>? assigneeIds,
    final List<String>? labelIds,
    final String? milestoneId,
    final String? baseRefName,
    final Enum$PullRequestUpdateState? state,
  }) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationupdatePullRequest,
      Variables$Mutation$updatePullRequest(
        pullRequestId: _nodeId,
        title: title,
        body: body,
        assigneeIds: assigneeIds,
        labelIds: labelIds,
        milestoneId: milestoneId,
        baseRefName: baseRefName,
        state: state,
      ).toJson(),
    );
    if (res.data == null) return null;
    final Mutation$updatePullRequest? data =
        Mutation$updatePullRequest.fromJson(res.data!);
    final PullInfo? pr =
        data?.updatePullRequest?.pullRequest;
    return SubjectMutationPayload.fromJson(pr?.toJson());
  }

  /// Set or clear PR milestone via slim mutation. Returns result for client-side patch.
  Future<SetMilestoneMutationResult?> setMilestone({
    final String? milestoneId,
  }) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationsetPullRequestMilestone,
      Variables$Mutation$setPullRequestMilestone(
        pullRequestId: _nodeId,
        milestoneId: milestoneId,
      ).toJson(),
    );
    if (res.data == null) return null;
    final Mutation$setPullRequestMilestone? data =
        Mutation$setPullRequestMilestone.fromJson(res.data!);
    final m = data?.updatePullRequest?.pullRequest?.milestone;
    return SetMilestoneMutationResult(milestone: m);
  }

  /// Update only title/body of a PR via slim mutation. Returns result for client-side patch.
  Future<TitleBodyEditResult?> editPullRequestContent({
    final String? title,
    final String? body,
  }) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationeditPullRequestContent,
      Variables$Mutation$editPullRequestContent(
        pullRequestId: _nodeId,
        title: title,
        body: body,
      ).toJson(),
    );
    if (res.data == null) return null;
    final Mutation$editPullRequestContent? data =
        Mutation$editPullRequestContent.fromJson(res.data!);
    final Mutation$editPullRequestContent$updatePullRequest$pullRequest? pr =
        data?.updatePullRequest?.pullRequest;
    if (pr == null) return null;
    return TitleBodyEditResult(
      title: pr.title,
      titleHTML: pr.titleHTML,
      body: pr.body,
      bodyHTML: pr.bodyHTML,
      lastEditedAt: pr.lastEditedAt ?? DateTime.now(),
      editor: pr.editor,
    );
  }

  /// Enable auto-merge on this PR. Uses [ref.nodeId]; ref must have nodeId set.
  Future<void> enableAutoMerge({
    final Enum$PullRequestMergeMethod? mergeMethod,
  }) async {
    await gql.mutation(
      documentNodeMutationenableAutoMerge,
      Variables$Mutation$enableAutoMerge(
        pullRequestId: _nodeId,
        mergeMethod: mergeMethod,
      ).toJson(),
    );
  }

  /// Disable auto-merge on this PR. Uses [ref.nodeId]; ref must have nodeId set.
  Future<void> disableAutoMerge() async {
    await gql.mutation(
      documentNodeMutationdisableAutoMerge,
      Variables$Mutation$disableAutoMerge(
        pullRequestId: _nodeId,
      ).toJson(),
    );
  }

  /// Add this PR to the merge queue. Uses [ref.nodeId]; ref must have nodeId set.
  Future<void> enqueuePullRequest() async {
    await gql.mutation(
      documentNodeMutationenqueuePullRequest,
      Variables$Mutation$enqueuePullRequest(
        pullRequestId: _nodeId,
      ).toJson(),
    );
  }

  /// Remove this PR from the merge queue. Uses [ref.nodeId]; ref must have nodeId set.
  Future<void> dequeuePullRequest() async {
    await gql.mutation(
      documentNodeMutationdequeuePullRequest,
      Variables$Mutation$dequeuePullRequest(
        pullRequestId: _nodeId,
      ).toJson(),
    );
  }

  /// Convert this PR to draft. Uses [ref.nodeId]; ref must have nodeId set.
  Future<bool> convertToDraft() async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationconvertToDraft,
      Variables$Mutation$convertToDraft(
        pullRequestId: _nodeId,
      ).toJson(),
    );
    return res.data != null;
  }

  /// Mark this PR ready for review. Uses [ref.nodeId]; ref must have nodeId set.
  Future<bool> markReadyForReview() async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationmarkReadyForReview,
      Variables$Mutation$markReadyForReview(
        pullRequestId: _nodeId,
      ).toJson(),
    );
    return res.data != null;
  }

  /// Update this PR branch (rebase/merge with base). Uses [ref.nodeId]; ref must have nodeId set.
  Future<String?> updatePullRequestBranch({
    final String? expectedHeadOid,
  }) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationupdatePullRequestBranch,
      Variables$Mutation$updatePullRequestBranch(
        pullRequestId: _nodeId,
        expectedHeadOid: expectedHeadOid,
      ).toJson(),
    );
    if (res.data == null) return null;
    final Mutation$updatePullRequestBranch? data =
        Mutation$updatePullRequestBranch.fromJson(res.data!);
    return data?.updatePullRequestBranch?.pullRequest?.headRefOid;
  }

  /// Close this pull request via GraphQL. Returns the updated PR as typed payload for patching provider state.
  /// Uses [ref.nodeId]; ref must have nodeId set.
  Future<SubjectMutationPayload?> closePullRequest() async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationclosePullRequest,
      Variables$Mutation$closePullRequest(
        pullRequestId: _nodeId,
      ).toJson(),
    );
    final Mutation$closePullRequest? data =
        Mutation$closePullRequest.fromJson(res.data!);
    final PullInfo? pr =
        data?.closePullRequest?.pullRequest;
    return SubjectMutationPayload.fromJson(pr?.toJson());
  }

  /// Reopen this pull request via GraphQL. Returns the updated PR as typed payload for patching provider state.
  /// Uses [ref.nodeId]; ref must have nodeId set.
  Future<SubjectMutationPayload?> reopenPullRequest() async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationreopenPullRequest,
      Variables$Mutation$reopenPullRequest(
        pullRequestId: _nodeId,
      ).toJson(),
    );
    final Mutation$reopenPullRequest? data =
        Mutation$reopenPullRequest.fromJson(res.data!);
    final PullInfo? pr =
        data?.reopenPullRequest?.pullRequest;
    return SubjectMutationPayload.fromJson(pr?.toJson());
  }

  /// Revert this merged pull request. Returns the new PR (number, url, title) or null.
  Future<({int number, String url, String title})?> revertPullRequest({
    final String? title,
    final String? body,
    final bool draft = false,
  }) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationrevertPullRequest,
      Variables$Mutation$revertPullRequest(
        pullRequestId: _nodeId,
        title: title,
        body: body,
        draft: draft,
      ).toJson(),
    );
    final Mutation$revertPullRequest? data =
        Mutation$revertPullRequest.fromJson(res.data!);
    final pr = data?.revertPullRequest?.revertPullRequest;
    return pr != null
        ? (number: pr.number, url: pr.url.toString(), title: pr.title)
        : null;
  }
}
