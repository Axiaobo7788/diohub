import 'package:freezed_annotation/freezed_annotation.dart';

part 'directory_last_commit.freezed.dart';
part 'directory_last_commit.g.dart';

/// Domain model for the last commit that touched a path. Used in directory tiles.
@freezed
abstract class DirectoryLastCommit with _$DirectoryLastCommit {
  const factory DirectoryLastCommit({
    required String oid,
    @JsonKey(name: 'abbreviated_oid') required String abbreviatedOid,
    required String message,
    @JsonKey(name: 'committed_date') required DateTime committedDate,
    @JsonKey(name: 'author_name') String? authorName,
    @JsonKey(name: 'author_avatar_url') String? authorAvatarUrl,
  }) = _DirectoryLastCommit;

  factory DirectoryLastCommit.fromJson(Map<String, dynamic> json) =>
      _$DirectoryLastCommitFromJson(json);
}
