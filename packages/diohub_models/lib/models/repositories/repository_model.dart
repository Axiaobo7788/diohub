import 'package:diohub_models/models/users/user_info_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'repository_model.freezed.dart';
part 'repository_model.g.dart';

@freezed
abstract class Repository with _$Repository {
  const factory Repository({
    required final String name,
    required final String fullName,
    required final SimpleUser owner,
    final String? description,
    final String? url,
    final String? htmlUrl,
    final String? language,
    final int? stargazersCount,
    @JsonKey(name: 'private') @Default(false) final bool isPrivate,
    @Default(false) final bool fork,
    @Default(false) final bool archived,
    final String? defaultBranch,

    /// Parent repo (for forks).
    final Repository? parent,

    /// Root source repo (for forks of forks).
    final Repository? source,
  }) = _Repository;

  factory Repository.fromJson(final Map<String, dynamic> json) =>
      _$RepositoryFromJson(json);
}

