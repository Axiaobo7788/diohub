import 'package:freezed_annotation/freezed_annotation.dart';

part 'release_result.freezed.dart';
part 'release_result.g.dart';

/// REST response for create/update release.
@freezed
abstract class ReleaseResult with _$ReleaseResult {
  const factory ReleaseResult({
    required int id,
    @JsonKey(name: 'tag_name') required String tagName,
    String? name,
    String? body,
    @Default(false) bool draft,
    @Default(false) bool prerelease,
    @JsonKey(name: 'html_url') required String htmlUrl,
    @JsonKey(name: 'published_at') DateTime? publishedAt,
    @JsonKey(name: 'upload_url') String? uploadUrl,
  }) = _ReleaseResult;

  factory ReleaseResult.fromJson(final Map<String, dynamic> json) =>
      _$ReleaseResultFromJson(json);
}
