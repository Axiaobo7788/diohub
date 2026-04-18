import 'package:freezed_annotation/freezed_annotation.dart';

part 'gollum_page.freezed.dart';
part 'gollum_page.g.dart';

/// A single wiki page entry from a GollumEvent payload.
@freezed
abstract class GollumPage with _$GollumPage {
  const factory GollumPage({
    final String? pageName,
    final String? title,
    final String? summary,
    final String? action,
    final String? sha,
    final String? htmlUrl,
  }) = _GollumPage;

  factory GollumPage.fromJson(final Map<String, dynamic> json) =>
      _$GollumPageFromJson(json);
}
