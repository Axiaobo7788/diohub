// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'community_profile_file.freezed.dart';
part 'community_profile_file.g.dart';

/// One file entry in GitHub community profile (e.g. README, license, code of conduct).
@freezed
abstract class CommunityProfileFile with _$CommunityProfileFile {
  const factory CommunityProfileFile({
    final String? name,
    final String? url,
    @JsonKey(name: 'html_url') final String? htmlUrl,
    @JsonKey(name: 'spdx_id') final String? spdxId,
  }) = _CommunityProfileFile;

  factory CommunityProfileFile.fromJson(final Map<String, dynamic> json) =>
      _$CommunityProfileFileFromJson(json);
}
