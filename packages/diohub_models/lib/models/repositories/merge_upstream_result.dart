import 'package:freezed_annotation/freezed_annotation.dart';

part 'merge_upstream_result.freezed.dart';
part 'merge_upstream_result.g.dart';

/// Response of GitHub REST POST /repos/{owner}/{repo}/merge-upstream
/// (sync fork branch with upstream).
@freezed
abstract class MergeUpstreamResult with _$MergeUpstreamResult {
  const factory MergeUpstreamResult({
    final String? message,
    @JsonKey(name: 'merge_type') final String? mergeType,
    @JsonKey(name: 'base_branch') final MergeUpstreamBaseBranch? baseBranch,
  }) = _MergeUpstreamResult;

  factory MergeUpstreamResult.fromJson(final Map<String, dynamic> json) =>
      _$MergeUpstreamResultFromJson(json);
}

/// Base branch fragment in [MergeUpstreamResult].
@freezed
abstract class MergeUpstreamBaseBranch with _$MergeUpstreamBaseBranch {
  const factory MergeUpstreamBaseBranch({
    final String? name,
  }) = _MergeUpstreamBaseBranch;

  factory MergeUpstreamBaseBranch.fromJson(final Map<String, dynamic> json) =>
      _$MergeUpstreamBaseBranchFromJson(json);
}
