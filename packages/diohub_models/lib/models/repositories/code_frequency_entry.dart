import 'package:freezed_annotation/freezed_annotation.dart';

part 'code_frequency_entry.freezed.dart';
part 'code_frequency_entry.g.dart';

/// One week from GitHub REST GET /repos/{owner}/{repo}/stats/code_frequency.
/// Raw API returns [week_timestamp, additions, deletions].
@freezed
abstract class CodeFrequencyEntry with _$CodeFrequencyEntry {
  const factory CodeFrequencyEntry({
    @Default(0) final int weekTimestamp,
    @Default(0) final int additions,
    @Default(0) final int deletions,
  }) = _CodeFrequencyEntry;

  factory CodeFrequencyEntry.fromJson(Map<String, dynamic> json) =>
      _$CodeFrequencyEntryFromJson(json);

  /// Parses one entry from the API array shape [week_ts, additions, deletions].
  factory CodeFrequencyEntry.fromList(final List<dynamic> list) {
    if (list.length < 3) return const CodeFrequencyEntry();
    return CodeFrequencyEntry(
      weekTimestamp: (list[0] is num) ? (list[0] as num).toInt() : 0,
      additions: (list[1] is num) ? (list[1] as num).toInt() : 0,
      deletions: (list[2] is num) ? (list[2] as num).toInt() : 0,
    );
  }
}
