import 'package:freezed_annotation/freezed_annotation.dart';

part 'contributor_stat.freezed.dart';
part 'contributor_stat.g.dart';

/// One contributor from GitHub REST GET /repos/{owner}/{repo}/stats/contributors.
@freezed
abstract class ContributorStat with _$ContributorStat {
  const factory ContributorStat({
    final ContributorStatAuthor? author,
    @Default(0) final int total,
    @Default([]) final List<ContributorWeek> weeks,
  }) = _ContributorStat;

  factory ContributorStat.fromJson(final Map<String, dynamic> json) =>
      _$ContributorStatFromJson(json);
}

@freezed
abstract class ContributorStatAuthor with _$ContributorStatAuthor {
  const factory ContributorStatAuthor({
    final String? login,
    @JsonKey(name: 'avatar_url') final String? avatarUrl,
  }) = _ContributorStatAuthor;

  factory ContributorStatAuthor.fromJson(final Map<String, dynamic> json) =>
      _$ContributorStatAuthorFromJson(json);
}

@freezed
abstract class ContributorWeek with _$ContributorWeek {
  const factory ContributorWeek({
    @JsonKey(name: 'w') @Default(0) final int weekTimestamp,
    @JsonKey(name: 'a') @Default(0) final int additions,
    @JsonKey(name: 'd') @Default(0) final int deletions,
    @JsonKey(name: 'c') @Default(0) final int commits,
  }) = _ContributorWeek;

  factory ContributorWeek.fromJson(final Map<String, dynamic> json) =>
      _$ContributorWeekFromJson(json);
}
