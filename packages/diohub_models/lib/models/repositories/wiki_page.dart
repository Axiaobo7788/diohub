import 'package:freezed_annotation/freezed_annotation.dart';

part 'wiki_page.freezed.dart';
part 'wiki_page.g.dart';

/// A single entry from the wiki Contents API list (GET .../contents/).
@freezed
abstract class WikiPageListItem with _$WikiPageListItem {
  const WikiPageListItem._();

  const factory WikiPageListItem({
    required final String name,
    required final String path,
    required final String sha,
    @Default(0) final int size,
  }) = _WikiPageListItem;

  factory WikiPageListItem.fromJson(final Map<String, dynamic> json) =>
      _$WikiPageListItemFromJson(json);

  /// Slug derived from filename (strip .md).
  String get slug => name.endsWith('.md') ? name.substring(0, name.length - 3) : name;

  /// Display title: slug with hyphens/underscores replaced by spaces.
  String get displayTitle =>
      slug.replaceAll('-', ' ').replaceAll('_', ' ');
}

/// A loaded wiki page with raw and rendered content.
@freezed
abstract class WikiPage with _$WikiPage {
  const factory WikiPage({
    required final String slug,
    required final String title,
    required final String rawMarkdown,
    required final String renderedHtml,
    required final String sha,
  }) = _WikiPage;
}
