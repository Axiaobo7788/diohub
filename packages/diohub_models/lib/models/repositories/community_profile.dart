// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:diohub_models/models/repositories/community_profile_file.dart';

part 'community_profile.freezed.dart';
part 'community_profile.g.dart';

/// Response of GitHub REST GET /repos/{owner}/{repo}/community/profile.
@freezed
abstract class CommunityProfile with _$CommunityProfile {
  const factory CommunityProfile({
    @JsonKey(name: 'health_percentage') @Default(0) final int healthPercentage,
    final CommunityProfileFiles? files,
    @JsonKey(name: 'updated_at') final String? updatedAt,
    @JsonKey(name: 'content_reports_enabled')
    @Default(false)
    final bool contentReportsEnabled,
  }) = _CommunityProfile;

  factory CommunityProfile.fromJson(final Map<String, dynamic> json) =>
      _$CommunityProfileFromJson(json);
}

/// Nested "files" object in community profile.
@freezed
abstract class CommunityProfileFiles with _$CommunityProfileFiles {
  const factory CommunityProfileFiles({
    @JsonKey(name: 'readme') final CommunityProfileFile? readme,
    @JsonKey(name: 'license') final CommunityProfileFile? license,
    @JsonKey(name: 'code_of_conduct') final CommunityProfileFile? codeOfConduct,
    @JsonKey(name: 'code_of_conduct_file')
    final CommunityProfileFile? codeOfConductFile,
    @JsonKey(name: 'contributing') final CommunityProfileFile? contributing,
    @JsonKey(name: 'issue_template') final CommunityProfileFile? issueTemplate,
    @JsonKey(name: 'pull_request_template')
    final CommunityProfileFile? pullRequestTemplate,
  }) = _CommunityProfileFiles;

  factory CommunityProfileFiles.fromJson(final Map<String, dynamic> json) =>
      _$CommunityProfileFilesFromJson(json);
}
