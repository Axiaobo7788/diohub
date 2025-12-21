import 'package:diohub/common/charts/contribution_calendar_widget.dart';
import 'package:diohub/view/profile/about/widgets/activity_overview_section.dart';
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
    return ContributionQueryKey(
      userName: userName,
      dateRange: ContributionDateRange.custom(from: from, to: to),
    );
  }

  /// Create key for a specific year
  factory ContributionQueryKey.year(String userName, int year) {
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
  }) = CustomRange;

  /// Get the actual from/to dates for the query
  (DateTime, DateTime) get dates;

  /// Check if this is a multi-year range
  bool get isMultiYear {
    final (from, to) = dates;
    return (to.year - from.year) > 0;
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
  });

  final DateTime from;
  final DateTime to;

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
    required this.restrictedContributionsCount,
    required this.totalRepositoriesWithContributedCommits,
    required this.totalRepositoriesWithContributedIssues,
    required this.totalRepositoriesWithContributedPullRequests,
    required this.calendarMonths,
  });

  /// The year this data represents (for multi-year ranges)
  final int year;

  /// Start date of the range for this year chunk
  final DateTime fromDate;

  /// End date of the range for this year chunk
  final DateTime toDate;

  /// Count of contributions viewer can't see (private/restricted)
  final int restrictedContributionsCount;

  /// How many repos had commits
  final int totalRepositoriesWithContributedCommits;

  /// How many repos had issues
  final int totalRepositoriesWithContributedIssues;

  /// How many repos had PRs
  final int totalRepositoriesWithContributedPullRequests;

  /// Monthly breakdown for this year
  final List<ContributionMonth> calendarMonths;
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
