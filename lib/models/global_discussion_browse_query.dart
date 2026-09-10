import 'package:flutter/foundation.dart';

enum GlobalDiscussionFilter { all, unanswered, answered }

@immutable
final class GlobalDiscussionBrowseQuery {
  const GlobalDiscussionBrowseQuery({
    required this.login,
    this.text = '',
    this.filter = GlobalDiscussionFilter.all,
  });

  final String login;
  final String text;
  final GlobalDiscussionFilter filter;

  String get normalizedText => text.trim();

  String get apiQuery => <String>[
    if (normalizedText.isNotEmpty) normalizedText,
    'involves:$login',
    switch (filter) {
      GlobalDiscussionFilter.all => '',
      GlobalDiscussionFilter.unanswered => 'is:unanswered',
      GlobalDiscussionFilter.answered => 'is:answered',
    },
    'sort:updated-desc',
  ].where((final String part) => part.isNotEmpty).join(' ');

  String get identity => apiQuery.toLowerCase();

  GlobalDiscussionBrowseQuery copyWith({
    final String? text,
    final GlobalDiscussionFilter? filter,
  }) => GlobalDiscussionBrowseQuery(
    login: login,
    text: text ?? this.text,
    filter: filter ?? this.filter,
  );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is GlobalDiscussionBrowseQuery && identity == other.identity;

  @override
  int get hashCode => identity.hashCode;
}
