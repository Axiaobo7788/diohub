import 'package:freezed_annotation/freezed_annotation.dart';

part 'commit_activity_entry.freezed.dart';
part 'commit_activity_entry.g.dart';

/// One week from GitHub REST GET /repos/{owner}/{repo}/stats/commit_activity.
/// [days] is 7 elements (Sun–Sat) with commit counts per day.
@freezed
abstract class CommitActivityEntry with _$CommitActivityEntry {
  const factory CommitActivityEntry({
    @Default(0) final int week,
    @Default([]) final List<int> days,
    @Default(0) final int total,
  }) = _CommitActivityEntry;

  factory CommitActivityEntry.fromJson(final Map<String, dynamic> json) =>
      _$CommitActivityEntryFromJson(json);
}
