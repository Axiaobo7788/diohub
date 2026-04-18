import 'package:diohub_models/models/issues/issue_model.dart';
import 'package:diohub_models/models/pull_requests/pull_request_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_summaries.freezed.dart';
part 'event_summaries.g.dart';

/// Lightweight summary of an Issue as embedded in Events API payloads.
/// All fields nullable to survive GitHub's trimmed payloads.
@freezed
abstract class EventIssueSummary with _$EventIssueSummary {
  const factory EventIssueSummary({
    final int? number,
    final String? url,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    final IssueState? state,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    final IssueStateReason? stateReason,
  }) = _EventIssueSummary;

  factory EventIssueSummary.fromJson(final Map<String, dynamic> json) =>
      _$EventIssueSummaryFromJson(json);
}

/// Lightweight summary of a PullRequest as embedded in Events API payloads.
/// All fields nullable to survive GitHub's trimmed payloads.
@freezed
abstract class EventPrSummary with _$EventPrSummary {
  const factory EventPrSummary({
    final int? number,
    final String? url,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    final PullRequestState? state,
    final EventBranchRef? head,
    @JsonKey(name: 'base') final EventBranchRef? baseBranch,
  }) = _EventPrSummary;

  factory EventPrSummary.fromJson(final Map<String, dynamic> json) =>
      _$EventPrSummaryFromJson(json);
}

/// Minimal branch ref from Events API head/base objects.
@freezed
abstract class EventBranchRef with _$EventBranchRef {
  const factory EventBranchRef({
    final String? ref,
  }) = _EventBranchRef;

  factory EventBranchRef.fromJson(final Map<String, dynamic> json) =>
      _$EventBranchRefFromJson(json);
}

/// Lightweight summary of an IssueComment as embedded in Events API payloads.
@freezed
abstract class EventCommentSummary with _$EventCommentSummary {
  const factory EventCommentSummary({
    final String? body,
    final String? htmlUrl,
  }) = _EventCommentSummary;

  factory EventCommentSummary.fromJson(final Map<String, dynamic> json) =>
      _$EventCommentSummaryFromJson(json);
}

/// Lightweight summary of a Repository as embedded in Events API payloads
/// (used for forkee).
@freezed
abstract class EventRepoSummary with _$EventRepoSummary {
  const factory EventRepoSummary({
    final String? name,
    final String? fullName,
    final String? url,
    final String? htmlUrl,
    final String? description,
  }) = _EventRepoSummary;

  factory EventRepoSummary.fromJson(final Map<String, dynamic> json) =>
      _$EventRepoSummaryFromJson(json);
}
