import 'package:freezed_annotation/freezed_annotation.dart';

part 'pages_info.freezed.dart';
part 'pages_info.g.dart';

String? _httpsCertStateFromJson(Object? value) {
  if (value == null) return null;
  if (value is Map) return value['state'] as String?;
  return null;
}

/// GitHub Pages info from REST GET /repos/{owner}/{repo}/pages.
@freezed
abstract class PagesInfo with _$PagesInfo {
  const factory PagesInfo({
    required String url,
    String? status,
    @JsonKey(name: 'html_url') required String htmlUrl,
    PagesSource? source,
    @JsonKey(name: 'build_type') String? buildType,
    @JsonKey(name: 'https_certificate', fromJson: _httpsCertStateFromJson)
    String? httpsCertificate,
    @JsonKey(name: 'https_enforced') bool? httpsEnforced,
    String? cname,
  }) = _PagesInfo;

  factory PagesInfo.fromJson(Map<String, dynamic> json) =>
      _$PagesInfoFromJson(json);
}

@freezed
abstract class PagesSource with _$PagesSource {
  const factory PagesSource({
    required String branch,
    required String path,
  }) = _PagesSource;

  factory PagesSource.fromJson(Map<String, dynamic> json) =>
      _$PagesSourceFromJson(json);
}
