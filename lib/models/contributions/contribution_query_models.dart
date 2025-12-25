import 'package:diohub/app/global.dart';
import 'package:diohub/common/charts/contribution_calendar_widget.dart';
import 'package:diohub/view/profile/about/widgets/activity_overview_section.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Typed key for contribution queries.
/// Eliminates string parsing and provides compile-time safety.
class ContributionQueryKey {
  const ContributionQueryKey({
    required this.userName,
    required this.dateRange,
  });

  final String userName;
  final ContributionDateRange dateRange;

  /// Create key for the last year from today (default view)
  factory ContributionQueryKey.lastYear(String userName) {
    final now = DateTime.now();
    final to = DateTime(now.year, now.month, now.day);
    final from = DateTime(to.year - 1, to.month, to.day);
    if (kDebugMode) {
      log.d(
          '[ContributionQueryKey.lastYear] Creating key for userName: "$userName", from: ${from.toIso8601String()}, to: ${to.toIso8601String()}');
    }
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
  factory ContributionQueryKey.year(String userName, int year) {
    if (kDebugMode) {
      log.d(
          '[ContributionQueryKey.year] Creating key for userName: "$userName", year: $year');
    }
    return ContributionQueryKey(
      userName: userName,
      dateRange: ContributionDateRange.year(year),
    );
  }

  /// Create key for a custom date range
  factory ContributionQueryKey.customRange({
    required String userName,
    required DateTime from,
    required DateTime to,
  }) {
    if (kDebugMode) {
      log.d(
          '[ContributionQueryKey.customRange] Creating key for userName: "$userName", from: ${from.toIso8601String()}, to: ${to.toIso8601String()}');
    }
    return ContributionQueryKey(
      userName: userName,
      dateRange: ContributionDateRange.custom(from: from, to: to),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContributionQueryKey &&
          runtimeType == other.runtimeType &&
          userName == other.userName &&
          dateRange == other.dateRange;

  @override
  int get hashCode => userName.hashCode ^ dateRange.hashCode;
}

/// Date range specification for contribution queries
sealed class ContributionDateRange {
  const ContributionDateRange();

  const factory ContributionDateRange.year(int year) = YearRange;
  const factory ContributionDateRange.custom({
    required DateTime from,
    required DateTime to,
    bool isLastYear,
  }) = CustomRange;

  /// Get the actual from/to dates for the query
  (DateTime, DateTime) get dates;

  /// Check if this is a multi-year range
  bool get isMultiYear {
    final (from, to) = dates;
    return (to.year - from.year) > 0;
  }

  /// Extract selected year if this is a single-year range, null otherwise
  int? get displayYear {
    return switch (this) {
      YearRange(:final year) => year,
      CustomRange() => null,
    };
  }

  /// Extract from date for display
  DateTime? get displayFromDate {
    return switch (this) {
      YearRange() => null,
      CustomRange(:final from) => from,
    };
  }

  /// Extract to date for display
  DateTime? get displayToDate {
    return switch (this) {
      YearRange() => null,
      CustomRange(:final to) => to,
    };
  }

  /// Check if this is a custom range (not a single year)
  bool get isCustomRange => this is CustomRange;

  /// Check if this represents "last year" (365 days ending today)
  /// This is a simple boolean flag set when creating via ContributionQueryKey.lastYear()
  bool get isLastYear => false;

  /// Check if this is a custom range that spans exactly Jan 1 - Dec 31 of a single year
  /// Returns the year if it's a full year range, null otherwise
  int? get fullYearIfCustomRange {
    return switch (this) {
      YearRange(:final year) => year,
      CustomRange(:final from, :final to) => () {
          // Normalize dates to day level for comparison
          final normalizedFrom = DateTime(from.year, from.month, from.day);
          final normalizedTo = DateTime(to.year, to.month, to.day);

          // Check if it's Jan 1 - Dec 31 of the same year
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
}

class YearRange extends ContributionDateRange {
  const YearRange(this.year);

  final int year;

  @override
  (DateTime, DateTime) get dates =>
      (DateTime(year, 1, 1), DateTime(year, 12, 31));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YearRange &&
          runtimeType == other.runtimeType &&
          year == other.year;

  @override
  int get hashCode => year.hashCode;
}

class CustomRange extends ContributionDateRange {
  const CustomRange({
    required this.from,
    required this.to,
    bool isLastYear = false,
  }) : _isLastYear = isLastYear;

  final DateTime from;
  final DateTime to;
  final bool _isLastYear;

  @override
  bool get isLastYear => _isLastYear;

  @override
  (DateTime, DateTime) get dates => (from, to);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomRange &&
          runtimeType == other.runtimeType &&
          from == other.from &&
          to == other.to;

  @override
  int get hashCode => from.hashCode ^ to.hashCode;
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
    this.state, // OPEN or CLOSED for issues/PRs
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
  final String? state; // OPEN, CLOSED for issues/PRs
  final String? body; // Description body
  final DateTime? mergedAt; // For merged PRs
  final dynamic
      graphQLIssue; // GraphQL issue type (from issueInfoTimeline fragment)
  final dynamic
      graphQLPullRequest; // GraphQL pull request type (from pullInfoTimeline fragment)
  final dynamic
      graphQLRepository; // GraphQL repository type (from repositoryFields fragment)

  String get repositoryFullName => '$repositoryOwner/$repositoryName';
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
  bool get hasAnyRestrictedContributions =>
      yearlyHighlights.any((h) => h.restrictedContributionsCount > 0);

  /// Utility: Total restricted contributions across all years
  int get totalRestrictedContributions => yearlyHighlights.fold(
        0,
        (sum, h) => sum + h.restrictedContributionsCount,
      );
}
