import 'package:flutter/foundation.dart';

/// Compact representation returned by GitHub's repository contributors list.
///
/// Unlike the Insights contributor-stat model, this does not contain 52 weeks
/// of contribution history and is suitable for the Repository Code sidebar.
@immutable
class RepositoryContributorPreview {
  const RepositoryContributorPreview({
    required this.login,
    required this.avatarUrl,
    required this.contributions,
  });

  final String login;
  final String? avatarUrl;
  final int contributions;
}
