import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub_models/models/pagination/unfinished_list.dart';
import 'package:diohub_graphql/schema.graphql.dart';
import 'package:diohub_graphql/fragments/common_exports.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_info_only.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_assignees.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_participants.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/pull_info_only.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_mutations.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_reactions.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/timeline.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/timeline_backward.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/pin_mutations.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/delete_issue_mutation.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/transfer_issue_mutation.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_graphql/queries/issues_pulls/sub_issues.graphql.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/issues/issue_pull_mutation_result.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:diohub/services/capabilities/capabilities.dart';
import 'package:diohub/services/capabilities/capable_entity_mixin.dart';
import 'package:diohub_models/models/issues/subject_mutation_payload.dart';
import 'package:diohub/services/issues/timeline_page_result.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub_graphql/queries/issues_pulls/sub_issue_mutations.graphql.dart';
import 'package:lens_annotations/lens_annotations.dart';

/// Result of transfer issue mutation: issue url to navigate to.
class TransferIssueResult {
  const TransferIssueResult({required this.url});
  final String url;
}

@LensService(group: 'issues')
class IssueService extends EntityService<IssueRef> with CapableEntityMixin<IssueRef> {
  IssueService(super.apiClient, super.ref);

  String get _nodeId => ref.nodeId!;

  late final CommentNodeService commentNode = CommentNodeService(apiClient, _nodeId);

  // ── Lens tool forwarding (capability methods on this entity) ──
  Future<LockStateResult?> lock({final Enum$LockReason? reason}) =>
      lockable.lock(reason: reason);
  Future<LockStateResult?> unlock() => lockable.unlock();
  Future<LabelsMutationResult?> addLabels(final List<String> labelIds) =>
      labelable.addLabels(labelIds);
  Future<LabelsMutationResult?> removeLabels(final List<String> labelIds) =>
      labelable.removeLabels(labelIds);
  Future<Enum$SubscriptionState?> updateSubscription(
          final Enum$SubscriptionState state) =>
      subscribable.updateSubscription(state);
  Future<CommentAddedResult?> addComment({required final String body}) =>
      commentable.addComment(body: body);
  Future<List<Fragment$reactorsGroup>?> addReaction(
          final Enum$ReactionContent content) =>
      reactable.addReaction(content);
  Future<List<Fragment$reactorsGroup>?> removeReaction(
          final Enum$ReactionContent content) =>
      reactable.removeReaction(content);
  Future<AssigneesMutationResult?> addAssignees(
          final List<String> assigneeIds) =>
      assignable.addAssignees(assigneeIds);
  Future<AssigneesMutationResult?> removeAssignees(
          final List<String> assigneeIds) =>
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

  /// Fetch issue or pull request info (unified). Requires issue/PR context.
  /// Fetches issue only (no union). Use when subject type is known to be issue (e.g. notifications).
  Future<IssueInfo> getIssueInfoOnly({
    final bool refresh = false,
  }) async {
    final GQLResponse response = await gql.query(
      documentNodeQueryissueInfoOnly,
      Variables$Query$issueInfoOnly(
        name: ref.repo.name,
        number: ref.number,
        owner: ref.repo.owner,
      ).toJson(),
      refreshCache: refresh,
    );
    final Query$issueInfoOnly data =
        Query$issueInfoOnly.fromJson(response.data!);
    final IssueInfo? issueNode =
        data.repository?.issue;
    if (issueNode == null) {
      throw StateError('Issue not found');
    }
    return issueNode;
  }

  /// Paginated sub-issues for this issue. For use with [SliverListBody] on the Sub-Issues tab.
  Future<PaginatedResult<SubIssueNode>>
      fetchSubIssues({
    int first = 20,
    String? after,
    bool refresh = false,
  }) async {
    final GQLResponse response = await gql.query(
      documentNodeQueryissueSubIssues,
      Variables$Query$issueSubIssues(
        owner: ref.repo.owner,
        name: ref.repo.name,
        number: ref.number,
        first: first,
        after: after,
      ).toJson(),
      refreshCache: refresh,
    );
    final Query$issueSubIssues? data =
        Query$issueSubIssues.fromJson(response.data!);
    final connection = data?.repository?.issue?.subIssues;
    if (connection == null) {
      return const PaginatedResult(
        items: [],
        hasNextPage: false,
        totalCount: 0,
      );
    }
    final nodes = connection.nodes
            ?.whereType<SubIssueNode>()
            .toList() ??
        <SubIssueNode>[];
    return PaginatedResult<
        SubIssueNode>(
      items: nodes,
      hasNextPage: connection.pageInfo.hasNextPage,
      endCursor: connection.pageInfo.endCursor,
      totalCount: connection.totalCount,
    );
  }

  /// Add an existing issue as a sub-issue of this issue.
  @Lens(
    'add_sub_issue',
    'Add a sub-issue to this issue',
    category: ToolCategory.issue,
    access: ToolAccess.write,
  )
  Future<Mutation$addSubIssue?> addSubIssue({
    @Desc('Sub-issue node ID') final String? subIssueNodeId,
    @Desc('Sub-issue URL') final String? subIssueUrl,
  }) async {
    assert(
      subIssueNodeId != null || subIssueUrl != null,
      'Either subIssueNodeId or subIssueUrl must be provided',
    );
    final GQLResponse res = await gql.mutation(
      documentNodeMutationaddSubIssue,
      Variables$Mutation$addSubIssue(
        issueId: _nodeId,
        subIssueId: subIssueNodeId,
        subIssueUrl: subIssueUrl,
      ).toJson(),
    );
    if (res.data == null) return null;
    return Mutation$addSubIssue.fromJson(res.data!);
  }

  /// Remove [subIssueNodeId] from this issue's sub-issues.
  @Lens(
    'remove_sub_issue',
    'Remove a sub-issue from this issue',
    category: ToolCategory.issue,
    access: ToolAccess.write,
  )
  Future<Mutation$removeSubIssue?> removeSubIssue({
    @Desc('Sub-issue node ID to remove') required final String subIssueNodeId,
  }) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationremoveSubIssue,
      Variables$Mutation$removeSubIssue(
        issueId: _nodeId,
        subIssueId: subIssueNodeId,
      ).toJson(),
    );
    if (res.data == null) return null;
    return Mutation$removeSubIssue.fromJson(res.data!);
  }

  /// Fetches pull request only (no union). Use when subject type is known to be PR (e.g. notifications).
  Future<PullInfo> getPullInfoOnly({
    final bool refresh = false,
  }) async {
    final GQLResponse response = await gql.query(
      documentNodeQuerypullInfoOnly,
      Variables$Query$pullInfoOnly(
        name: ref.repo.name,
        number: ref.number,
        owner: ref.repo.owner,
      ).toJson(),
      refreshCache: refresh,
    );
    final Query$pullInfoOnly data = Query$pullInfoOnly.fromJson(response.data!);
    final PullInfo? prNode =
        data.repository?.pullRequest;
    if (prNode == null) {
      throw StateError('Pull request not found');
    }
    return prNode;
  }

  Future<List<NodeWithPaginationInfo<Fragment$actor$$User>>> getAssignees({
    required final String? after,
  }) async {
    final GQLResponse response = await gql.query(
      documentNodeQueryissuePullAssignees,
      Variables$Query$issuePullAssignees(
        number: ref.number,
        owner: ref.repo.owner,
        name: ref.repo.name,
        after: after,
      ).toJson(),
    );
    return Query$issuePullAssignees.fromJson(response.data!)
        .repository!
        .issueOrPullRequest!
        .maybeWhen(
          issue: (
            final Query$issuePullAssignees$repository$issueOrPullRequest$$Issue
                data,
          ) =>
              data.assignees.edges!
                  .map<NodeWithPaginationInfo<Fragment$actor$$User>>(
                    (
                      final Query$issuePullAssignees$repository$issueOrPullRequest$$Issue$assignees$edges?
                          p0,
                    ) =>
                        NodeWithPaginationInfo<Fragment$actor$$User>.fromEdge(
                      p0!,
                      // Safe cast: parent union is discriminated by maybeWhen branch
                      getNode: (e) =>
                          (e as Query$issuePullAssignees$repository$issueOrPullRequest$$Issue$assignees$edges)
                              .node,
                      getCursor: (e) =>
                          (e as Query$issuePullAssignees$repository$issueOrPullRequest$$Issue$assignees$edges)
                              .cursor,
                    ),
                  )
                  .toList(),
          pullRequest: (
            final Query$issuePullAssignees$repository$issueOrPullRequest$$PullRequest
                data,
          ) =>
              data.assignees.edges!
                  .map<NodeWithPaginationInfo<Fragment$actor$$User>>(
                    (
                      final Query$issuePullAssignees$repository$issueOrPullRequest$$PullRequest$assignees$edges?
                          p0,
                    ) =>
                        NodeWithPaginationInfo<Fragment$actor$$User>.fromEdge(
                      p0!,
                      // Safe cast: parent union is discriminated by maybeWhen branch
                      getNode: (e) =>
                          (e as Query$issuePullAssignees$repository$issueOrPullRequest$$PullRequest$assignees$edges)
                              .node,
                      getCursor: (e) =>
                          (e as Query$issuePullAssignees$repository$issueOrPullRequest$$PullRequest$assignees$edges)
                              .cursor,
                    ),
                  )
                  .toList(),
          orElse: () => throw UnimplementedError(),
        );
  }

  Future<List<NodeWithPaginationInfo<Fragment$actor$$User>>> getParticipants({
    required final String? after,
  }) async {
    final GQLResponse response = await gql.query(
      documentNodeQueryissuePullParticipants,
      Variables$Query$issuePullParticipants(
        number: ref.number,
        name: ref.repo.name,
        owner: ref.repo.owner,
        after: after,
      ).toJson(),
    );

    // BuiltList<Fragment$actor$$User> getList()=>
    // ignore: avoid_dynamic_calls
    return Query$issuePullParticipants.fromJson(response.data!)
        .repository!
        .issueOrPullRequest!
        .maybeWhen(
          issue: (
            final Query$issuePullParticipants$repository$issueOrPullRequest$$Issue
                p0,
          ) =>
              p0.participants.edges!
                  .map<NodeWithPaginationInfo<Fragment$actor$$User>>(
                    (
                      final Query$issuePullParticipants$repository$issueOrPullRequest$$Issue$participants$edges?
                          p0,
                    ) =>
                        NodeWithPaginationInfo<Fragment$actor$$User>.fromEdge(
                      p0!,
                      // Safe cast: parent union is discriminated by maybeWhen branch
                      getNode: (e) =>
                          (e as Query$issuePullParticipants$repository$issueOrPullRequest$$Issue$participants$edges)
                              .node,
                      getCursor: (e) =>
                          (e as Query$issuePullParticipants$repository$issueOrPullRequest$$Issue$participants$edges)
                              .cursor,
                    ),
                  )
                  .toList(),
          pullRequest: (
            final Query$issuePullParticipants$repository$issueOrPullRequest$$PullRequest
                p0,
          ) =>
              p0.participants.edges!
                  .map<NodeWithPaginationInfo<Fragment$actor$$User>>(
                    (
                      final Query$issuePullParticipants$repository$issueOrPullRequest$$PullRequest$participants$edges?
                          p0,
                    ) =>
                        NodeWithPaginationInfo<Fragment$actor$$User>.fromEdge(
                      p0!,
                      // Safe cast: parent union is discriminated by maybeWhen branch
                      getNode: (e) =>
                          (e as Query$issuePullParticipants$repository$issueOrPullRequest$$PullRequest$participants$edges)
                              .node,
                      getCursor: (e) =>
                          (e as Query$issuePullParticipants$repository$issueOrPullRequest$$PullRequest$participants$edges)
                              .cursor,
                    ),
                  )
                  .toList(),
          orElse: () => throw UnimplementedError(),
        );
  }

  // Ref: https://docs.github.com/en/rest/reference/issues#list-timeline-events-for-an-issue
  Future<TimelinePageResult> getTimeline({
    required final bool refresh,
    final String? after,
    final DateTime? since,
  }) async {
    final GQLResponse response = await gql.query(
      documentNodeQuerygetTimeline,
      Variables$Query$getTimeline(
        number: ref.number,
        owner: ref.repo.owner,
        name: ref.repo.name,
        after: after,
        since: since,
      ).toJson(),
      refreshCache: refresh,
      requestHeaders:
          gql.acceptHeader('application/vnd.github.starfox-preview+json'),
    );
    final data = Query$getTimeline.fromJson(response.data!)
        .repository!
        .issueOrPullRequest!;
    final List<dynamic> edges = data.when<List<dynamic>>(
      issue: (
        final Query$getTimeline$repository$issueOrPullRequest$$Issue p0,
      ) =>
          p0.timelineItems.edges!,
      pullRequest: (
        final Query$getTimeline$repository$issueOrPullRequest$$PullRequest p0,
      ) =>
          p0.timelineItems.edges!,
      orElse: () => throw UnimplementedError('Invalid issue/PR type'),
    );
    // pageInfo from raw response until generated types include it
    final Map<String, dynamic>? repo =
        response.data!['repository'] as Map<String, dynamic>?;
    final Map<String, dynamic>? issueOrPr =
        repo?['issueOrPullRequest'] as Map<String, dynamic>?;
    final Map<String, dynamic>? timelineItems =
        issueOrPr?['timelineItems'] as Map<String, dynamic>?;
    final Map<String, dynamic>? pageInfo =
        timelineItems?['pageInfo'] as Map<String, dynamic>?;
    final bool hasNextPage = pageInfo?['hasNextPage'] as bool? ?? true;
    final bool hasPreviousPage = pageInfo?['hasPreviousPage'] as bool? ?? false;
    final String? startCursor = pageInfo?['startCursor'] as String?;
    final String? endCursor = pageInfo?['endCursor'] as String?;
    return TimelinePageResult(
      edges: edges,
      hasNextPage: hasNextPage,
      hasPreviousPage: hasPreviousPage,
      startCursor: startCursor,
      endCursor: endCursor,
    );
  }

  /// Fetch timeline items backward (for "Load earlier" flow).
  /// Returns edges in chronological order (API returns reverse order for last:/before:).
  Future<TimelinePageResult> getTimelineBackward({
    final String? before,
    required final int last,
  }) async {
    final GQLResponse response = await gql.query(
      documentNodeQuerygetTimelineBackward,
      Variables$Query$getTimelineBackward(
        number: ref.number,
        owner: ref.repo.owner,
        name: ref.repo.name,
        before: before,
        last: last,
      ).toJson(),
      requestHeaders:
          gql.acceptHeader('application/vnd.github.starfox-preview+json'),
    );
    final data = Query$getTimelineBackward.fromJson(response.data!)
        .repository!
        .issueOrPullRequest!;
    return data.when<TimelinePageResult>(
      issue:
          (final Query$getTimelineBackward$repository$issueOrPullRequest$$Issue
              i) {
        final conn = i.timelineItems;
        final edgesRaw = conn.edges!;
        final edges = edgesRaw.reversed.toList();
        final pageInfo = conn.pageInfo;
        return TimelinePageResult(
          edges: edges,
          hasNextPage: pageInfo.hasNextPage,
          hasPreviousPage: pageInfo.hasPreviousPage,
          startCursor: pageInfo.startCursor,
          endCursor: pageInfo.endCursor,
        );
      },
      pullRequest: (
        final Query$getTimelineBackward$repository$issueOrPullRequest$$PullRequest
            p,
      ) {
        final conn = p.timelineItems;
        final edgesRaw = conn.edges!;
        final edges = edgesRaw.reversed.toList();
        final pageInfo = conn.pageInfo;
        return TimelinePageResult(
          edges: edges,
          hasNextPage: pageInfo.hasNextPage,
          hasPreviousPage: pageInfo.hasPreviousPage,
          startCursor: pageInfo.startCursor,
          endCursor: pageInfo.endCursor,
        );
      },
      orElse: () => throw UnimplementedError('Invalid issue/PR type'),
    );
  }

  /// Close an issue via GraphQL. Returns the updated issue as typed payload for patching provider state.
  @Lens(
    'close_issue',
    'Close this issue with an optional reason',
    category: ToolCategory.issue,
    access: ToolAccess.write,
  )
  Future<SubjectMutationPayload?> closeIssue({
    @Desc('Optional close reason') final Enum$IssueClosedStateReason? reason,
  }) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationcloseIssue,
      Variables$Mutation$closeIssue(
        issueId: _nodeId,
        stateReason: reason,
      ).toJson(),
    );
    final Mutation$closeIssue? data = Mutation$closeIssue.fromJson(res.data!);
    final IssueInfo? issue = data?.closeIssue?.issue;
    return SubjectMutationPayload.fromJson(issue?.toJson());
  }

  /// Reopen an issue via GraphQL. Returns the updated issue as typed payload for patching provider state.
  @Lens(
    'reopen_issue',
    'Reopen this closed issue',
    category: ToolCategory.issue,
    access: ToolAccess.write,
  )
  Future<SubjectMutationPayload?> reopenIssue() async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationreopenIssue,
      Variables$Mutation$reopenIssue(
        issueId: _nodeId,
      ).toJson(),
    );
    final Mutation$reopenIssue? data = Mutation$reopenIssue.fromJson(res.data!);
    final IssueInfo? issue = data?.reopenIssue?.issue;
    return SubjectMutationPayload.fromJson(issue?.toJson());
  }

  /// Delete an issue via GraphQL. Caller should pop the issue screen on success.
  @Lens(
    'delete_issue',
    'Delete this issue permanently',
    category: ToolCategory.issue,
    access: ToolAccess.optIn,
  )
  Future<void> deleteIssue() async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationdeleteIssue,
      Variables$Mutation$deleteIssue(
        issueId: _nodeId,
      ).toJson(),
    );
    Mutation$deleteIssue.fromJson(res.data!);
  }

  /// Transfer an issue to another repository. Returns the new issue url on success.
  @Lens(
    'transfer_issue',
    'Transfer this issue to another repository',
    category: ToolCategory.issue,
    access: ToolAccess.write,
  )
  Future<TransferIssueResult?> transferIssue(
    @Desc('Target repository node ID') final String repositoryId,
  ) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationtransferIssue,
      Variables$Mutation$transferIssue(
        issueId: _nodeId,
        repositoryId: repositoryId,
      ).toJson(),
    );
    final Mutation$transferIssue? data = Mutation$transferIssue.fromJson(res.data!);
    final Mutation$transferIssue$transferIssue$issue? issue =
        data?.transferIssue?.issue;
    if (issue?.url == null) return null;
    return TransferIssueResult(url: issue!.url.toString());
  }

  @Lens(
    'pin_issue',
    'Pin this issue to the repository',
    category: ToolCategory.issue,
    access: ToolAccess.write,
  )
  Future<bool?> pinIssue() async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationpinIssue,
      Variables$Mutation$pinIssue(
        issueId: _nodeId,
      ).toJson(),
    );
    final Mutation$pinIssue? data = Mutation$pinIssue.fromJson(res.data!);
    return data?.pinIssue?.issue?.isPinned;
  }

  @Lens(
    'unpin_issue',
    'Unpin this issue from the repository',
    category: ToolCategory.issue,
    access: ToolAccess.write,
  )
  Future<bool?> unpinIssue() async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationunpinIssue,
      Variables$Mutation$unpinIssue(
        issueId: _nodeId,
      ).toJson(),
    );
    final Mutation$unpinIssue? data = Mutation$unpinIssue.fromJson(res.data!);
    return data?.unpinIssue?.issue?.isPinned;
  }

  /// Update an issue via GraphQL (title, body, state, assignees, labels, milestone).
  /// Returns the updated issue as typed payload for patching provider state, or null on failure.
  @Lens(
    'update_issue',
    'Update issue properties (title, body, state, assignees, labels, milestone)',
    category: ToolCategory.issue,
    access: ToolAccess.write,
  )
  Future<SubjectMutationPayload?> updateIssue({
    @Desc('New title') final String? title,
    @Desc('New body') final String? body,
    @Desc('New state') final Enum$IssueState? state,
    @Desc('Assignee node IDs') final List<String>? assigneeIds,
    @Desc('Label node IDs') final List<String>? labelIds,
    @Desc('Milestone node ID') final String? milestoneId,
  }) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationupdateIssue,
      Variables$Mutation$updateIssue(
        id: _nodeId,
        title: title,
        body: body,
        state: state,
        assigneeIds: assigneeIds,
        labelIds: labelIds,
        milestoneId: milestoneId,
      ).toJson(),
    );
    if (res.data == null) return null;
    final Mutation$updateIssue? data = Mutation$updateIssue.fromJson(res.data!);
    final IssueInfo? issue = data?.updateIssue?.issue;
    return SubjectMutationPayload.fromJson(issue?.toJson());
  }

  /// Update only title/body of an issue via slim mutation. Returns result for client-side patch.
  Future<TitleBodyEditResult?> editIssueContent({
    final String? title,
    final String? body,
  }) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationeditIssueContent,
      Variables$Mutation$editIssueContent(
        id: _nodeId,
        title: title,
        body: body,
      ).toJson(),
    );
    if (res.data == null) return null;
    final Mutation$editIssueContent? data =
        Mutation$editIssueContent.fromJson(res.data!);
    final Mutation$editIssueContent$updateIssue$issue? issue =
        data?.updateIssue?.issue;
    if (issue == null) return null;
    return TitleBodyEditResult(
      title: issue.title,
      titleHTML: issue.titleHTML,
      body: issue.body,
      bodyHTML: issue.bodyHTML,
      lastEditedAt: issue.lastEditedAt ?? DateTime.now(),
      editor: issue.editor,
    );
  }

  /// Set or clear issue milestone via slim mutation. Returns result for client-side patch.
  Future<SetMilestoneMutationResult?> setMilestone({
    final String? milestoneId,
  }) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationsetIssueMilestone,
      Variables$Mutation$setIssueMilestone(
        id: _nodeId,
        milestoneId: milestoneId,
      ).toJson(),
    );
    if (res.data == null) return null;
    final Mutation$setIssueMilestone? data =
        Mutation$setIssueMilestone.fromJson(res.data!);
    final m = data?.updateIssue?.issue?.milestone;
    return SetMilestoneMutationResult(milestone: m);
  }
}
