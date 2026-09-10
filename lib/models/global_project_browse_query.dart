import 'package:flutter/foundation.dart';

enum GlobalProjectSort { recentlyUpdated, name }

@immutable
final class GlobalProjectBrowseQuery {
  const GlobalProjectBrowseQuery({
    required this.login,
    this.text = '',
    this.sort = GlobalProjectSort.recentlyUpdated,
  });

  final String login;
  final String text;
  final GlobalProjectSort sort;

  String get normalizedText => text.trim();

  String get identity => <String>[
    'login:${login.toLowerCase()}',
    'query:${normalizedText.toLowerCase()}',
    'sort:${sort.name}',
  ].join('/');

  GlobalProjectBrowseQuery copyWith({
    final String? text,
    final GlobalProjectSort? sort,
  }) => GlobalProjectBrowseQuery(
    login: login,
    text: text ?? this.text,
    sort: sort ?? this.sort,
  );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is GlobalProjectBrowseQuery && identity == other.identity;

  @override
  int get hashCode => identity.hashCode;
}
