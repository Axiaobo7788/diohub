import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'compose_mode.freezed.dart';

/// Sealed hierarchy of compose flow modes.
/// All behavior branching in [ComposeScaffold] is driven by [ComposeConfig.mode].
@freezed
sealed class ComposeMode with _$ComposeMode {
  const factory ComposeMode.newIssue({RepoIssueTemplate? template}) =
      NewIssueMode;
  const factory ComposeMode.editIssue({required IssueRef issueRef}) =
      EditIssueMode;
  const factory ComposeMode.newPullRequest({
    String? initialBaseRef,
    String? initialHeadRef,
  }) = NewPullRequestMode;
  const factory ComposeMode.editPullRequest({required PullRequestRef pullRef}) =
      EditPullRequestMode;
  const factory ComposeMode.comment({
    IssueRef? issueRef,
    PullRequestRef? pullRef,
  }) = CommentMode;
  const factory ComposeMode.editComment({
    required ComposeCommentRef commentRef,
    required String initialBody,
  }) = EditCommentMode;
}

/// Ref-like contract for edit-comment flows.
abstract interface class ComposeCommentRef {
  String get apiPath;
  String get entityType;
  String? get parentPath;
}
