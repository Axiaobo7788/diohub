import 'package:diohub_models/models/users/user_info_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'fork_repo_result.freezed.dart';
part 'fork_repo_result.g.dart';

/// Response of GitHub REST POST /repos/{owner}/{repo}/forks (create fork).
@freezed
abstract  class ForkRepoResult with _$ForkRepoResult {
  const factory ForkRepoResult({
    required final String name,
    @JsonKey(name: 'full_name') required final String fullName,
    required final SimpleUser owner,
    final String? description,
    final String? url,
    @JsonKey(name: 'html_url') final String? htmlUrl,
    final String? language,
    @JsonKey(name: 'stargazers_count') final int? stargazersCount,
    @JsonKey(name: 'private') @Default(false) final bool isPrivate,
    @Default(true) final bool fork,
    @JsonKey(name: 'default_branch') final String? defaultBranch,
  }) = _ForkRepoResult;

  factory ForkRepoResult.fromJson(final Map<String, dynamic> json) =>
      _$ForkRepoResultFromJson(json);
}
