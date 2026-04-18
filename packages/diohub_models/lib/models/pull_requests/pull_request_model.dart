import 'package:diohub_models/models/issues/issue_model.dart';
import 'package:diohub_models/models/users/user_info_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pull_request_model.freezed.dart';
part 'pull_request_model.g.dart';

@freezed
abstract class PullRequest with _$PullRequest {
  const factory PullRequest({
    required final int number,
    required final String title,

    /// Head (source) branch ref.
    required final PrBranchRef head,

    /// Base (target) branch ref. No more `base_` hack.
    @JsonKey(name: 'base') required final PrBranchRef baseBranch,
    final String? url,
    final String? htmlUrl,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    final PullRequestState? state,
    final String? body,
    final String? bodyHtml,
    final bool? merged,
    final DateTime? mergedAt,
    final DateTime? createdAt,
    final DateTime? updatedAt,
    final DateTime? closedAt,
    final bool? draft,
    final int? additions,
    final int? deletions,
    final int? changedFiles,
    final int? comments,
    final SimpleUser? user,
    @Default(<Label>[]) final List<Label> labels,
    @Default(<SimpleUser>[]) final List<SimpleUser> assignees,
    @JsonKey(name: 'requested_reviewers')
    @Default(<SimpleUser>[])
    final List<SimpleUser> requestedReviewers,
  }) = _PullRequest;

  factory PullRequest.fromJson(final Map<String, dynamic> json) =>
      _$PullRequestFromJson(json);
}

@freezed
abstract class PrBranchRef with _$PrBranchRef {
  const factory PrBranchRef({
    required final String ref,
    required final String sha,
    final PrBranchRepo? repo,
  }) = _PrBranchRef;

  factory PrBranchRef.fromJson(final Map<String, dynamic> json) =>
      _$PrBranchRefFromJson(json);
}

/// Minimal repo info embedded in PR head/base branch refs.
@freezed
abstract class PrBranchRepo with _$PrBranchRepo {
  const factory PrBranchRepo({
    required final String name,
    required final SimpleUser owner,
    final String? htmlUrl,
    final String? url,
    final String? description,
    final String? language,
  }) = _PrBranchRepo;

  factory PrBranchRepo.fromJson(final Map<String, dynamic> json) =>
      _$PrBranchRepoFromJson(json);
}


/// GitHub pull request state values.
/// Note: "merged" is not an API state — it's derived from the `merged` bool.
enum PullRequestState {
  @JsonValue('open')
  open,
  @JsonValue('closed')
  closed,
}

extension PullRequestStateX on PullRequest {
  bool get isOpen => state == PullRequestState.open;
  bool get isClosed => state == PullRequestState.closed;
  bool get isMerged => merged ?? false;
}
