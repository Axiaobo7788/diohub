import 'package:freezed_annotation/freezed_annotation.dart';

part 'punch_card_entry.freezed.dart';
part 'punch_card_entry.g.dart';

/// One slot from GitHub REST GET /repos/{owner}/{repo}/stats/punch_card.
/// Raw API returns [day (0–6), hour (0–23), commits].
@freezed
abstract class PunchCardEntry with _$PunchCardEntry {
  const factory PunchCardEntry({
    @Default(0) final int day,
    @Default(0) final int hour,
    @Default(0) final int commits,
  }) = _PunchCardEntry;

  factory PunchCardEntry.fromJson(Map<String, dynamic> json) =>
      _$PunchCardEntryFromJson(json);

  /// Parses one entry from the API array shape [day, hour, commits].
  factory PunchCardEntry.fromList(final List<dynamic> list) {
    if (list.length < 3) return const PunchCardEntry();
    return PunchCardEntry(
      day: (list[0] is num) ? (list[0] as num).toInt() : 0,
      hour: (list[1] is num) ? (list[1] as num).toInt() : 0,
      commits: (list[2] is num) ? (list[2] as num).toInt() : 0,
    );
  }
}
