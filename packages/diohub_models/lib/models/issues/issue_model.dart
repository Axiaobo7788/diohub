import 'package:diohub_models/models/repositories/repository_model.dart';
import 'package:diohub_models/models/users/user_info_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'issue_model.freezed.dart';
part 'issue_model.g.dart';

@freezed
abstract class Issue with _$Issue {
  const factory Issue({
    required final int number,
    required final String title,
    final String? url,
    final String? htmlUrl,
    final String? repositoryUrl,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    final IssueState? state,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    final IssueStateReason? stateReason,
    final String? body,
    final String? bodyHtml,
    final int? comments,
    final SimpleUser? user,
    @Default(<Label>[]) final List<Label> labels,
    @Default(<SimpleUser>[]) final List<SimpleUser> assignees,
    final IssuePullRequest? pullRequest,
    final Repository? repository,
    final DateTime? createdAt,
    final DateTime? updatedAt,
    final DateTime? closedAt,
  }) = _Issue;

  factory Issue.fromJson(final Map<String, dynamic> json) =>
      _$IssueFromJson(json);
}

@freezed
abstract class Label with _$Label {
  const factory Label({
    required final String name,
    required final String color,
    final int? id,
    final String? description,
  }) = _Label;

  factory Label.fromJson(final Map<String, dynamic> json) =>
      _$LabelFromJson(json);
}

/// Stub indicating an issue is actually a pull request.
/// Present on Issue when it's a PR; provides the PR URL.
@freezed
abstract class IssuePullRequest with _$IssuePullRequest {
  const factory IssuePullRequest({
    final String? url,
    final String? htmlUrl,
  }) = _IssuePullRequest;

  factory IssuePullRequest.fromJson(final Map<String, dynamic> json) =>
      _$IssuePullRequestFromJson(json);
}


enum IssueState {
  @JsonValue('open')
  open,
  @JsonValue('closed')
  closed,
}

enum IssueStateReason {
  @JsonValue('completed')
  completed,
  @JsonValue('not_planned')
  notPlanned,
  @JsonValue('duplicate')
  duplicate,
  @JsonValue('reopened')
  reopened,
}

extension IssueStateX on Issue {
  bool get isOpen => state == IssueState.open;
  bool get isClosed => state == IssueState.closed;
}
