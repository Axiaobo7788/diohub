import 'package:diohub/common/charts/contribution_calendar_widget.dart';
import 'package:diohub/common/utils/contribution_utils.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_graphql/queries/users/user_typedefs.dart' as gql;
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub_models/models/contributions/contribution_day.dart';
import 'package:flutter/material.dart';

/// Converts GraphQL contribution data to widget-friendly formats.
///
/// This class provides type-safe conversion methods for contribution data
/// from GraphQL types to widget data structures.
class ContributionDataConverter {
  /// Converts GraphQL contribution calendar weeks to ContributionDay format
  static List<List<ContributionDay>> convertWeeks(
    final List<gql.ContributionWeek?>? weeks,
  ) {
    if (weeks == null || weeks.isEmpty) {
      return <List<ContributionDay>>[];
    }

    return weeks
        .whereType<gql.ContributionWeek>()
        .map(
          (final gql.ContributionWeek week) => week.contributionDays
              .whereType<gql.ContributionDay>()
              .map(
                (final gql.ContributionDay day) => ContributionDay(
                  date: DateTime.parse(day.date.toString()),
                  count: day.contributionCount,
                  // Use GitHub colors from API
                  color: parseContributionColor(day.color),
                  level: convertContributionLevel(day.contributionLevel),
                ),
              )
              .toList(),
        )
        .toList();
  }

  /// Converts GraphQL contribution calendar colors to Color list
  static List<Color> convertColors(final List<String>? colors) {
    if (colors == null || colors.isEmpty) {
      return kDefaultContributionColors;
    }

    return parseContributionColors(colors);
  }

  /// Extracts months from contribution weeks for labels
  static List<DateTime> extractMonths(
    final List<gql.ContributionWeek?>? weeks,
  ) {
    if (weeks == null || weeks.isEmpty) {
      return <DateTime>[];
    }

    return weeks
        .whereType<gql.ContributionWeek>()
        .expand((final gql.ContributionWeek week) => week.contributionDays)
        .whereType<gql.ContributionDay>()
        .map(
          (final gql.ContributionDay day) =>
              DateTime.parse(day.date.toString()),
        )
        .map((final DateTime date) => DateTime(date.year, date.month))
        .toSet()
        .toList()
      ..sort();
  }

  /// Converts contributed repositories from GraphQL
  /// Uses repoCardFields fragment from user_contributions query
  static List<ContributedRepository> convertRepositories(
    final List<gql.CommitContributionsByRepo?>? repositories,
  ) {
    return _convertRepos<gql.CommitContributionsByRepo>(
      repositories,
      (repo) => ContributedRepository(
        // Safe cast: GraphQL fragment ensures repository is RepoCardData
        graphQLRepository: repo.repository as RepoCardData,
        contributionCount: repo.contributions.totalCount,
        commitCount: repo.contributions.totalCount,
      ),
    );
  }

  /// Converts PR review contributed repositories from GraphQL
  /// Stores full GraphQL object to avoid data loss
  static List<ContributedRepository> convertReviewRepositories(
    final List<gql.PRReviewContributionsByRepo?>? repositories,
  ) {
    return _convertRepos<gql.PRReviewContributionsByRepo>(
      repositories,
      (repo) => ContributedRepository(
        // Safe cast: GraphQL fragment ensures repository is RepoCardData
        graphQLRepository: repo.repository as RepoCardData,
        contributionCount: repo.contributions.totalCount,
        reviewCount: repo.contributions.totalCount,
      ),
    );
  }

  /// Converts issue contributed repositories from GraphQL
  /// Stores full GraphQL object to avoid data loss
  static List<ContributedRepository> convertIssueRepositories(
    final List<gql.IssueContributionsByRepo?>? repositories,
  ) {
    return _convertRepos<gql.IssueContributionsByRepo>(
      repositories,
      (repo) => ContributedRepository(
        // Safe cast: GraphQL fragment ensures repository is RepoCardData
        graphQLRepository: repo.repository as RepoCardData,
        contributionCount: repo.contributions.totalCount,
        issueCount: repo.contributions.totalCount,
      ),
    );
  }

  /// Converts pull request contributed repositories from GraphQL
  /// Stores full GraphQL object to avoid data loss
  static List<ContributedRepository> convertPullRequestRepositories(
    final List<gql.PRContributionsByRepo?>? repositories,
  ) {
    return _convertRepos<gql.PRContributionsByRepo>(
      repositories,
      (repo) => ContributedRepository(
        // Safe cast: GraphQL fragment ensures repository is RepoCardData
        graphQLRepository: repo.repository as RepoCardData,
        contributionCount: repo.contributions.totalCount,
        pullRequestCount: repo.contributions.totalCount,
      ),
    );
  }

  /// Generic helper to convert repository contribution lists
  static List<ContributedRepository> _convertRepos<T>(
    final List<T?>? repositories,
    ContributedRepository Function(T) mapper,
  ) {
    if (repositories == null || repositories.isEmpty) {
      return <ContributedRepository>[];
    }
    return repositories.whereType<T>().map(mapper).toList();
  }
}
