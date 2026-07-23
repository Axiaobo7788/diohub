import 'package:flutter/foundation.dart';

/// A public product update published on the GitHub Changelog.
@immutable
final class GitHubChangelogItem {
  const GitHubChangelogItem({
    required this.title,
    required this.link,
    required this.publishedAt,
  });

  final String title;
  final Uri link;

  /// Publication time normalized to UTC.
  final DateTime publishedAt;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is GitHubChangelogItem &&
          other.title == title &&
          other.link == link &&
          other.publishedAt == publishedAt;

  @override
  int get hashCode => Object.hash(title, link, publishedAt);

  @override
  String toString() =>
      'GitHubChangelogItem(title: $title, link: $link, '
      'publishedAt: $publishedAt)';
}
