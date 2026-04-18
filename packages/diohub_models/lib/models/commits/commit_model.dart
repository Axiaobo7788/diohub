import 'package:diohub_models/models/users/user_info_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'commit_model.freezed.dart';
part 'commit_model.g.dart';

/// Default for [Commit.files]; used by generated code to avoid List<dynamic>.
const List<DiffEntry> _commitFilesDefault = <DiffEntry>[];

@freezed
abstract class Commit with _$Commit {
  const factory Commit({
    required final String sha,
    final String? url,
    final String? htmlUrl,
    final CommitDetail? commit,
    final SimpleUser? author,
    final SimpleUser? committer,
    final CommitStats? stats,
    @Default(<DiffEntry>[]) final List<DiffEntry> files,
  }) = _Commit;

  factory Commit.fromJson(final Map<String, dynamic> json) =>
      _$CommitFromJson(json);
}

/// The nested "commit" object inside a Commit response.
@freezed
abstract class CommitDetail with _$CommitDetail {
  const factory CommitDetail({
    final String? message,
    final CommitUser? author,
    final CommitUser? committer,
  }) = _CommitDetail;

  factory CommitDetail.fromJson(final Map<String, dynamic> json) =>
      _$CommitDetailFromJson(json);
}

/// Git-level author/committer (not a GitHub user — has name/email/date).
@freezed
abstract class CommitUser with _$CommitUser {
  const factory CommitUser({
    final String? name,
    final String? email,
    final DateTime? date,
  }) = _CommitUser;

  factory CommitUser.fromJson(final Map<String, dynamic> json) =>
      _$CommitUserFromJson(json);
}

@freezed
abstract class CommitStats with _$CommitStats {
  const factory CommitStats({
    @Default(0) final int additions,
    @Default(0) final int deletions,
    @Default(0) final int total,
  }) = _CommitStats;

  factory CommitStats.fromJson(final Map<String, dynamic> json) =>
      _$CommitStatsFromJson(json);
}

@freezed
abstract class DiffEntry with _$DiffEntry {
  const factory DiffEntry({
    required final String filename,
    final String? status,
    @Default(0) final int additions,
    @Default(0) final int deletions,
    @Default(0) final int changes,
    final String? patch,
    final String? contentsUrl,
  }) = _DiffEntry;

  factory DiffEntry.fromJson(final Map<String, dynamic> json) =>
      _$DiffEntryFromJson(json);
}

typedef CommitModel = Commit;
typedef FileElement = DiffEntry;

// ---------------------------------------------------------------------------
// State enums & extensions
// ---------------------------------------------------------------------------

/// Diff entry status values (from commits / pull request files).
enum DiffStatus {
  added,
  removed,
  modified,
  renamed,
  copied,
  changed,
  unchanged;

  static DiffStatus? fromString(final String? value) =>
      switch (value?.toLowerCase()) {
        'added' => added,
        'removed' => removed,
        'modified' => modified,
        'renamed' => renamed,
        'copied' => copied,
        'changed' => changed,
        'unchanged' => unchanged,
        _ => null,
      };
}

extension DiffEntryStatusX on DiffEntry {
  DiffStatus? get diffStatus => DiffStatus.fromString(status);
  bool get isAdded => diffStatus == DiffStatus.added;
  bool get isRemoved => diffStatus == DiffStatus.removed;
  bool get isModified => diffStatus == DiffStatus.modified;
}
