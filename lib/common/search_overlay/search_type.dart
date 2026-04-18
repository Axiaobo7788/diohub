import 'package:flutter/material.dart' show IconData;
import 'package:flutter_vector_icons/flutter_vector_icons.dart' show Octicons;

enum QueryType { basic, spacedString, date, number, user, org, bool, custom }

enum SearchType {
  repositories,
  issuesPulls,
  discussions,
  code,
  commits,
  users,
  topics,
  packages,
  wiki,
}

extension SearchTypeExtension on SearchType {
  String get displayName {
    switch (this) {
      case SearchType.repositories:
        return 'Repositories';
      case SearchType.issuesPulls:
        return 'Issues & PRs';
      case SearchType.discussions:
        return 'Discussions';
      case SearchType.code:
        return 'Code';
      case SearchType.commits:
        return 'Commits';
      case SearchType.users:
        return 'Users';
      case SearchType.topics:
        return 'Topics';
      case SearchType.packages:
        return 'Packages';
      case SearchType.wiki:
        return 'Wiki';
    }
  }

  IconData get icon {
    switch (this) {
      case SearchType.repositories:
        return Octicons.repo;
      case SearchType.issuesPulls:
        return Octicons.issue_opened;
      case SearchType.discussions:
        return Octicons.comment_discussion;
      case SearchType.code:
        return Octicons.code;
      case SearchType.commits:
        return Octicons.git_commit;
      case SearchType.users:
        return Octicons.person;
      case SearchType.topics:
        return Octicons.hash;
      case SearchType.packages:
        return Octicons.package;
      case SearchType.wiki:
        return Octicons.book;
    }
  }

  bool get isGraphQL {
    switch (this) {
      case SearchType.repositories:
      case SearchType.issuesPulls:
      case SearchType.users:
      case SearchType.discussions:
        return true;
      case SearchType.code:
      case SearchType.commits:
      case SearchType.topics:
      case SearchType.packages:
      case SearchType.wiki:
        return false;
    }
  }
}
