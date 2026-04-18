import 'package:diohub/common/charts/contribution_calendar_widget.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_graphql/fragments/repo_card_fields.graphql.dart';
import 'package:diohub_models/models/contributions/contribution_day.dart';
import 'package:diohub_models/models/visual_state.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'contribution_query_models.freezed.dart';

/// Typed key for contribution queries.
/// Eliminates string parsing and provides compile-time safety.
@freezed
abstract class ContributionQueryKey with _$ContributionQueryKey {
  const ContributionQueryKey._();

  const factory ContributionQueryKey({
    required String userName,
    required ContributionDateRange dateRange,
  }) = _ContributionQueryKey;

  /// Create key for the last year from today (default view)
  factory ContributionQueryKey.lastYear(final String userName) {
    final DateTime now = DateTime.now();
    final DateTime to = DateTime(now.year, now.month, now.day);
    final DateTime from = DateTime(to.year - 1, to.month, to.day);
    return ContributionQueryKey(
      userName: userName,
      dateRange: ContributionDateRange.custom(
        from: from,
        to: to,
        isLastYear: true,
      ),
    );
  }

  /// Create key for a specific year
  factory ContributionQueryKey.year(final String userName, final int year) =>
      ContributionQueryKey(
        userName: userName,
        dateRange: ContributionDateRange.year(year),
      );

  /// Create key for a custom date range
  factory ContributionQueryKey.customRange({
    required final String userName,
    required final DateTime from,
    required final DateTime to,
  }) {
    final DateTime normalizedFrom = DateTime(from.year, from.month, from.day);
    final DateTime normalizedTo = DateTime(to.year, to.month, to.day);
    return ContributionQueryKey(
      userName: userName,
      dateRange: ContributionDateRange.custom(
        from: normalizedFrom,
        to: normalizedTo,
      ),
    );
  }
}

/// Date range specification for contribution queries
@freezed
sealed class ContributionDateRange with _$ContributionDateRange {
  const ContributionDateRange._();

  const factory ContributionDateRange.year(int year) = YearRange;
  const factory ContributionDateRange.custom({
    required DateTime from,
    required DateTime to,
    @Default(false) bool isLastYear,
  }) = CustomRange;

  /// Get the actual from/to dates for the query
  (DateTime, DateTime) get dates => switch (this) {
    YearRange(year: final y) => (DateTime(y), DateTime(y, 12, 31)),
    CustomRange(from: final from, to: final to) => (from, to),
  };

  /// Check if this is a multi-year range
  bool get isMultiYear {
    final (DateTime from, DateTime to) = dates;
    return (to.year - from.year) > 0;
  }

  /// Extract selected year if this is a single-year range, null otherwise
  int? get displayYear => switch (this) {
    YearRange(year: final year) => year,
    CustomRange() => null,
  };

  /// Extract from date for display
  DateTime? get displayFromDate => switch (this) {
    YearRange() => null,
    CustomRange(from: final from) => from,
  };

  /// Extract to date for display
  DateTime? get displayToDate => switch (this) {
    YearRange() => null,
    CustomRange(to: final to) => to,
  };

  /// Check if this is a custom range (not a single year)
  bool get isCustomRange => this is CustomRange;

  /// Check if this represents "last year" (365 days ending today)
  bool get isLastYear => switch (this) {
    YearRange() => false,
    CustomRange(isLastYear: final v) => v,
  };

  /// Check if this is a custom range that spans exactly Jan 1 - Dec 31 of a single year
  int? get fullYearIfCustomRange => switch (this) {
    YearRange(year: final year) => year,
    CustomRange(from: final from, to: final to) => () {
      final DateTime normalizedFrom = DateTime(from.year, from.month, from.day);
      final DateTime normalizedTo = DateTime(to.year, to.month, to.day);
      if (normalizedFrom.year == normalizedTo.year &&
          normalizedFrom.month == 1 &&
          normalizedFrom.day == 1 &&
          normalizedTo.month == 12 &&
          normalizedTo.day == 31) {
        return normalizedFrom.year;
      }
      return null;
    }(),
  };
}

/// Data for a repository in the "Contributed to" section.
/// Stores the full GraphQL repository object to avoid data loss.
class ContributedRepository {
  const ContributedRepository({
    required this.graphQLRepository,
    required this.contributionCount,
    this.commitCount,
    this.reviewCount,
    this.issueCount,
    this.pullRequestCount,
  });

  /// Full GraphQL repository object (uses repoCardFields fragment from contributions query)
  final RepoCardData graphQLRepository;

  /// Total contribution count (sum of all contribution types)
  final int contributionCount;

  /// Number of commits contributed
  final int? commitCount;

  /// Number of PR reviews contributed
  final int? reviewCount;

  /// Number of issues contributed
  final int? issueCount;

  /// Number of pull requests contributed
  final int? pullRequestCount;

  String get name => graphQLRepository.name;
  String get owner => graphQLRepository.owner.when(
    organization: (o) => o.login,
    user: (u) => u.login,
    orElse: () => '',
  );
  String get url => graphQLRepository.url.toString();
  String? get description => graphQLRepository.description;
  int get stargazersCount => graphQLRepository.stargazerCount;
  bool get isPrivate => graphQLRepository.isPrivate;
  bool get isFork => graphQLRepository.isFork;
  String? get language => graphQLRepository.primaryLanguage?.name;
  String? get languageColor => graphQLRepository.primaryLanguage?.color;
}

/// Unified view model for contribution data.
/// Always has the same shape regardless of single-year or multi-year queries.
class ContributionViewModel {
  const ContributionViewModel({
    required this.weeks,
    required this.colors,
    required this.totalContributions,
    required this.totalCommitContributions,
    required this.totalPullRequestContributions,
    required this.totalIssueContributions,
    required this.totalPullRequestReviewContributions,
    required this.commitContributionsByRepository,
    required this.contributionYears,
  });

  final List<List<ContributionDay>> weeks;
  final List<Color> colors;
  final int totalContributions;
  final int totalCommitContributions;
  final int totalPullRequestContributions;
  final int totalIssueContributions;
  final int totalPullRequestReviewContributions;
  final List<ContributedRepository> commitContributionsByRepository;
  final List<int> contributionYears;
}

/// Per-year contribution highlights and metadata.
/// Contains the fields that don't get flattened during multi-year merge.
class YearlyContributionHighlights {
  const YearlyContributionHighlights({
    required this.year,
    required this.fromDate,
    required this.toDate,
    required this.startedAt,
    required this.endedAt,
    required this.restrictedContributionsCount,
    required this.totalCommitContributions,
    required this.totalIssueContributions,
    required this.totalPullRequestContributions,
    required this.totalPullRequestReviewContributions,
    required this.totalRepositoryContributions,
    required this.totalContributions,
    required this.totalRepositoriesWithContributedCommits,
    required this.totalRepositoriesWithContributedIssues,
    required this.totalRepositoriesWithContributedPullRequests,
    required this.totalRepositoriesWithContributedPullRequestReviews,
    required this.calendarMonths,
    this.earliestRestrictedContributionDate,
    this.latestRestrictedContributionDate,
    this.firstIssue,
    this.firstPullRequest,
    this.firstRepository,
    this.popularIssue,
    this.popularPullRequest,
    this.mostReviewedRepository,
    this.joinedGitHub,
  });

  /// The year this data represents (for multi-year ranges)
  final int year;

  /// Start date of the range for this year chunk
  final DateTime fromDate;

  /// End date of the range for this year chunk
  final DateTime toDate;

  /// Exact start timestamp from API (more accurate than fromDate)
  final DateTime startedAt;

  /// Exact end timestamp from API (more accurate than toDate)
  final DateTime endedAt;

  /// Count of contributions viewer can't see (private/restricted)
  final int restrictedContributionsCount;

  /// Date of earliest restricted contribution (if any)
  final DateTime? earliestRestrictedContributionDate;

  /// Date of latest restricted contribution (if any)
  final DateTime? latestRestrictedContributionDate;

  /// Total commits in this year
  final int totalCommitContributions;

  /// Total issues in this year
  final int totalIssueContributions;

  /// Total pull requests in this year
  final int totalPullRequestContributions;

  /// Total pull request reviews in this year
  final int totalPullRequestReviewContributions;

  /// Total repositories created in this year
  final int totalRepositoryContributions;

  /// Total contributions (from calendar) in this year
  final int totalContributions;

  /// How many repos had commits
  final int totalRepositoriesWithContributedCommits;

  /// How many repos had issues
  final int totalRepositoriesWithContributedIssues;

  /// How many repos had PRs
  final int totalRepositoriesWithContributedPullRequests;

  /// How many repos had pull request reviews
  final int totalRepositoriesWithContributedPullRequestReviews;

  /// Monthly breakdown for this year
  final List<ContributionMonth> calendarMonths;

  /// First issue opened in this range
  final ContributionHighlightItem? firstIssue;

  /// First pull request opened in this range
  final ContributionHighlightItem? firstPullRequest;

  /// First repository created in this range
  final ContributionHighlightItem? firstRepository;

  /// Most commented issue in this range
  final ContributionHighlightItem? popularIssue;

  /// Most commented pull request in this range
  final ContributionHighlightItem? popularPullRequest;

  /// Repository with most PR reviews in this range
  final ContributionHighlightItem? mostReviewedRepository;

  /// GitHub account join date (if in this range)
  final DateTime? joinedGitHub;
}

/// Type of contribution highlight
enum ContributionHighlightType {
  issue,
  pullRequest,
  repository,
  restricted,
  joined,
}

/// Represents a highlight contribution (issue, PR, or repo)
class ContributionHighlightItem {
  const ContributionHighlightItem({
    required this.title,
    required this.url,
    required this.createdAt,
    required this.repositoryName,
    required this.repositoryOwner,
    required this.type,
    this.number,
    this.commentCount,
    this.stargazerCount,
    this.isPrivate = false,
    this.isRestricted = false,
    this.state,
    this.body, // Description for issues/PRs
    this.mergedAt, // For PRs
    this.graphQLIssue, // GraphQL issue type (from issueInfoTimeline fragment)
    this.graphQLPullRequest, // GraphQL pull request type (from pullInfoTimeline fragment)
    this.graphQLRepository, // GraphQL repository type (from repositoryFields fragment)
  });

  final String title;
  final String url;
  final DateTime createdAt;
  final String repositoryName;
  final String repositoryOwner;
  final ContributionHighlightType type;
  final int? number; // For issues/PRs
  final int? commentCount; // For popular items
  final int? stargazerCount; // For repos
  final bool isPrivate;
  final bool isRestricted;
  final VisualState? state;
  final String? body; // Description body
  final DateTime? mergedAt; // For merged PRs
  final dynamic
  graphQLIssue; // GraphQL issue type (from issueInfoTimeline fragment)
  final dynamic
  graphQLPullRequest; // GraphQL pull request type (from pullInfoTimeline fragment)
  final dynamic
  graphQLRepository; // GraphQL repository type (from repositoryFields fragment)

  String get repositoryFullName => '$repositoryOwner/$repositoryName';

  /// Prefer building URL at call site with [ServerConfig.webUrl] for active server.
  String get repositoryUrl => 'https://github.com/$repositoryFullName';
}

/// Month metadata from contribution calendar
class ContributionMonth {
  const ContributionMonth({
    required this.name,
    required this.year,
    required this.firstDay,
    required this.totalWeeks,
  });

  final String name;
  final int year;
  final DateTime firstDay;
  final int totalWeeks;
}

/// Complete contribution collection result.
/// Bundles the flattened calendar/totals with per-year highlights.
class ContributionCollectionResult {
  const ContributionCollectionResult({
    required this.viewModel,
    required this.yearlyHighlights,
  });

  /// Flattened/merged calendar data (weeks, totals, repos, colors)
  final ContributionViewModel viewModel;

  /// Per-year highlight data (restricted counts, repo counts, months, etc.)
  final List<YearlyContributionHighlights> yearlyHighlights;

  /// Utility: Check if any year has restricted contributions
  bool get hasAnyRestrictedContributions => yearlyHighlights.any(
    (final YearlyContributionHighlights h) =>
        h.restrictedContributionsCount > 0,
  );

  /// Utility: Total restricted contributions across all years
  int get totalRestrictedContributions => yearlyHighlights.fold(
    0,
    (final int sum, final YearlyContributionHighlights h) =>
        sum + h.restrictedContributionsCount,
  );
}
