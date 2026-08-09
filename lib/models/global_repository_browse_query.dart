import 'package:flutter/foundation.dart';

enum GlobalRepositoryVisibility { all, public, private }

enum GlobalRepositorySort { recentlyPushed, recentlyUpdated, name, stars }

/// Typed query state for the authenticated repository dashboard.
///
/// GitHub's repository search API only supports owner-scoped `user:` queries,
/// while this page must also include collaborator and organization-member
/// repositories. The server-side portion therefore uses the existing
/// authenticated repositories connection; [text] and [forksOnly] are
/// reversible projections over retained pages.
@immutable
final class GlobalRepositoryBrowseQuery {
  const GlobalRepositoryBrowseQuery({
    required this.login,
    this.text = '',
    this.visibility = GlobalRepositoryVisibility.all,
    this.forksOnly = false,
    this.sort = GlobalRepositorySort.recentlyPushed,
  });

  final String login;
  final String text;
  final GlobalRepositoryVisibility visibility;
  final bool forksOnly;
  final GlobalRepositorySort sort;

  String get normalizedText => text.trim().toLowerCase();

  /// Identity for the query session, including local projections.
  String get identity =>
      'login:$login/text:$normalizedText/visibility:${visibility.name}'
      '/forks:$forksOnly/sort:${sort.name}';

  /// Identity for immutable remote pages. Local projections deliberately do
  /// not fragment the Runtime cache.
  String get remoteIdentity =>
      'login:$login/visibility:${visibility.name}/sort:${sort.name}';

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is GlobalRepositoryBrowseQuery &&
          other.login == login &&
          other.normalizedText == normalizedText &&
          other.visibility == visibility &&
          other.forksOnly == forksOnly &&
          other.sort == sort;

  @override
  int get hashCode =>
      Object.hash(login, normalizedText, visibility, forksOnly, sort);
}
