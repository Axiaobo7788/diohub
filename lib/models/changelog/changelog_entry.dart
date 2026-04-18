import 'package:freezed_annotation/freezed_annotation.dart';

part 'changelog_entry.freezed.dart';
part 'changelog_entry.g.dart';

/// Changelog entry derived from GitHub Release.
@freezed
abstract class ChangelogEntry with _$ChangelogEntry {
  const factory ChangelogEntry({
    required String tagName,
    required DateTime publishedAt,
    required String bodyHtml,
    String? name,
    @Default(false) bool isPrerelease,
  }) = _ChangelogEntry;

  factory ChangelogEntry.fromJson(Map<String, dynamic> json) =>
      _$ChangelogEntryFromJson(json);
}
