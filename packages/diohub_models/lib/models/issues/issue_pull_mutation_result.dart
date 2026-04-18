import 'package:built_collection/built_collection.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_graphql/fragments/milestone.graphql.dart';
import 'package:diohub_models/models/issues/subject_mutation_payload.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'issue_pull_mutation_result.freezed.dart';

/// Result of lock/unlock mutation for patching provider state (no refetch).
class LockStateResult {
  const LockStateResult({required this.locked, this.activeLockReason});
  final bool locked;
  final LockReason? activeLockReason;
}

/// Result of update issue comment for patching timeline state.
class IssueCommentUpdate {
  const IssueCommentUpdate({
    required this.id,
    required this.body,
    required this.bodyHTML,
    this.lastEditedAt,
  });
  final String id;
  final String body;
  final String bodyHTML;
  final DateTime? lastEditedAt;
}

/// One entry in comment edit history (userContentEdits node).
class CommentEditHistoryItem {
  const CommentEditHistoryItem({
    required this.editedAt,
    this.editorLogin,
    this.editorAvatarUrl,
    this.diff,
  });
  final DateTime editedAt;
  final String? editorLogin;
  final String? editorAvatarUrl;
  final String? diff;
}

/// Result of a mutation; used to patch notifier state without refetch.
@freezed
sealed class IssuePullMutationResult with _$IssuePullMutationResult {
  const IssuePullMutationResult._();

  const factory IssuePullMutationResult.subject({
    IssueInfo? issue,
    PullInfo? pullRequest,
  }) = SubjectMutationResult;

  const factory IssuePullMutationResult.labels({
    BuiltList<IssueLabelNode?>? issueLabels,
    BuiltList<PullLabelNode?>? pullLabels,
  }) = LabelsMutationResult;

  const factory IssuePullMutationResult.assignees({
    BuiltList<IssueAssigneeNode?>? issueAssignees,
    BuiltList<PullAssigneeNode?>? pullAssignees,
  }) = AssigneesMutationResult;

  const factory IssuePullMutationResult.commentAdded({
    required Object commentEdge,
    required int commentsTotalCount,
  }) = CommentAddedResult;

  const factory IssuePullMutationResult.titleBodyEdit({
    required String title,
    required String titleHTML,
    required String body,
    required String bodyHTML,
    required DateTime lastEditedAt,
    Object? editor,
  }) = TitleBodyEditResult;

  const factory IssuePullMutationResult.setMilestone({
    Fragment$milestoneFields? milestone,
  }) = SetMilestoneMutationResult;
}

/// Creates [SubjectMutationResult] from GraphQL payload.
SubjectMutationResult subjectMutationResultFromPayload(
        SubjectMutationPayload p) =>
    SubjectMutationResult(issue: p.issue, pullRequest: p.pullRequest);
