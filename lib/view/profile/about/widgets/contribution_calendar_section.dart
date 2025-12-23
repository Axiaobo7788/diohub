import 'package:diohub/common/animations/fade_animation_widget.dart';
import 'package:diohub/common/charts/contribution_calendar_widget.dart';
import 'package:diohub/common/misc/contribution_info_chip.dart';
import 'package:diohub/common/misc/shimmer_widget.dart';
import 'package:diohub/common/utils/contribution_utils.dart';
import 'package:diohub/models/contributions/contribution_chip_type.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/view/profile/about/widgets/day_activity_bottom_sheet.dart';
import 'package:diohub/style/surface_style_theme.dart';
import 'package:flutter/material.dart';

/// A section widget that displays the contribution calendar with statistics.
///
/// This widget combines the contribution calendar grid with summary statistics
/// and provides interactive features like day details on tap.
class ContributionCalendarSection extends StatelessWidget {
  const ContributionCalendarSection({
    required this.weeks,
    required this.totalContributions,
    this.colors,
    this.onDayTap,
    this.selectedYear,
    this.availableYears,
    this.customFromDate,
    this.customToDate,
    this.useCustomRange = false,
    this.createdAt,
    this.commits,
    this.pullRequests,
    this.issues,
    this.reviews,
    this.contributionResult,
    this.onChipTap,
    this.userLogin,
    super.key,
  });

  /// List of weeks, each containing 7 days (Mon-Sun)
  final List<List<ContributionDay>> weeks;

  /// Total contributions in the displayed period
  final int totalContributions;

  /// Color scheme for contribution levels
  final List<Color>? colors;

  /// Callback when a day is tapped
  final void Function(ContributionDay day)? onDayTap;

  /// Currently selected year (for display purposes only)
  final int? selectedYear;

  /// Available years to select from (for display purposes only)
  final List<int>? availableYears;

  /// Custom date range start (for display purposes only)
  final DateTime? customFromDate;

  /// Custom date range end (for display purposes only)
  final DateTime? customToDate;

  /// Whether custom date range is active (for display purposes only)
  final bool useCustomRange;

  /// User's GitHub account creation date (for "Since joining GitHub" option)
  final DateTime? createdAt;

  /// Number of commits
  final int? commits;

  /// Number of pull requests
  final int? pullRequests;

  /// Number of issues
  final int? issues;

  /// Optional number of reviews
  final int? reviews;

  /// Contribution result for calculating repo counts
  final ContributionCollectionResult? contributionResult;

  /// Callback when a chip is tapped
  final void Function(ContributionChipType chipType)? onChipTap;

  /// User login for fetching day activity
  final String? userLogin;

  /// Checks if the current custom range matches "Since joining GitHub"
  bool get _isSinceJoining {
    if (!useCustomRange || customFromDate == null || createdAt == null) {
      return false;
    }
    return customFromDate!.year == createdAt!.year &&
        customFromDate!.month == createdAt!.month &&
        customFromDate!.day == createdAt!.day;
  }

  /// Handle day tap - opens bottom sheet if day has contributions
  void _handleDayTap(BuildContext context, ContributionDay day) {
    // Call original callback if provided
    onDayTap?.call(day);

    // Only open bottom sheet if day has contributions and userLogin is available
    if (day.count > 0 && userLogin != null) {
      // Ensure we're working with UTC dates
      // The day.date might be in local time, so we need to extract the date components
      // and create a UTC date to ensure we query the correct day
      final dayDate = day.date.isUtc
          ? day.date
          : DateTime.utc(day.date.year, day.date.month, day.date.day);

      // Create start of day in UTC (00:00:00)
      final dayStart = DateTime.utc(
        dayDate.year,
        dayDate.month,
        dayDate.day,
      );

      // Create end of day in UTC (23:59:59.999)
      final dayEnd = dayStart.add(
        const Duration(
          hours: 23,
          minutes: 59,
          seconds: 59,
          milliseconds: 999,
        ),
      );

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => DayActivityBottomSheet(
          login: userLogin!,
          from: dayStart,
          to: dayEnd,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use colors from GitHub API (provided via colors parameter)
    // Colors come from contributionCalendar.colors in GraphQL response
    final defaultColors = colors;
    if (defaultColors == null || defaultColors.isEmpty) {
      // Should not happen - colors always come from GitHub API
      // Return error state if somehow missing
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contribution Graph',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to load contribution colors',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ),
      );
    }

    // Determine if calendar should scroll (multi-year ranges)
    bool shouldScroll = false;
    String subtitleText;

    if (useCustomRange && customFromDate != null && customToDate != null) {
      final daysDiff = customToDate!.difference(customFromDate!).inDays;
      final yearsDiff = daysDiff / 365.25;

      // Enable scrolling for ranges > 1 year
      shouldScroll = yearsDiff > 1.0;

      if (_isSinceJoining) {
        subtitleText = 'Since joining GitHub';
      } else {
        final fromStr = formatDateOnly(customFromDate!);
        final toStr = formatDateOnly(customToDate!);
        subtitleText = 'from $fromStr to $toStr';
      }
    } else if (selectedYear == null) {
      subtitleText = 'Last Year';
      shouldScroll = false;
    } else {
      subtitleText = '$selectedYear';
      shouldScroll = false;
    }

    final colorScheme = theme.colorScheme;

    // Calculate repo counts from contribution result
    int reposWithCommits = 0;
    int reposWithIssues = 0;
    int reposWithPRs = 0;
    int reposWithReviews = 0;
    int totalRepositoriesCreated = 0;

    if (contributionResult != null) {
      for (final highlight in contributionResult!.yearlyHighlights) {
        reposWithCommits += highlight.totalRepositoriesWithContributedCommits;
        reposWithIssues += highlight.totalRepositoriesWithContributedIssues;
        reposWithPRs += highlight.totalRepositoriesWithContributedPullRequests;
        reposWithReviews +=
            highlight.totalRepositoriesWithContributedPullRequestReviews;
        totalRepositoriesCreated += highlight.totalRepositoryContributions;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$totalContributions ${totalContributions == 1 ? 'contribution' : 'contributions'}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitleText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FadeAnimationSection(
            duration: const Duration(milliseconds: 300),
            child: ContributionCalendarWidget(
              weeks: weeks,
              colors: defaultColors,
              onDayTap: (day) => _handleDayTap(context, day),
              showMonthLabels: true,
              showDayLabels: false,
              cellSize: 11.0,
              cellSpacing: 2.0,
              shouldScroll: shouldScroll,
            ),
          ),
          if (commits != null ||
              pullRequests != null ||
              issues != null ||
              reviews != null ||
              totalRepositoriesCreated > 0 ||
              (contributionResult != null &&
                  contributionResult!.totalRestrictedContributions > 0)) ...[
            const SizedBox(height: 12),
            _buildInfoChips(
              context,
              colorScheme,
              reposWithCommits: reposWithCommits,
              reposWithIssues: reposWithIssues,
              reposWithPRs: reposWithPRs,
              reposWithReviews: reposWithReviews,
              totalRepositoriesCreated: totalRepositoriesCreated,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChips(
    BuildContext context,
    ColorScheme colorScheme, {
    required int reposWithCommits,
    required int reposWithIssues,
    required int reposWithPRs,
    required int reposWithReviews,
    required int totalRepositoriesCreated,
  }) {
    final chips = <Widget>[];

    if (commits != null && commits! > 0) {
      chips.add(ContributionInfoChip.commits(
        count: commits!,
        repoCount: reposWithCommits,
        onTap: onChipTap != null
            ? () => onChipTap!(ContributionChipType.commits)
            : null,
      ));
    }
    if (pullRequests != null && pullRequests! > 0) {
      chips.add(ContributionInfoChip.pullRequests(
        count: pullRequests!,
        repoCount: reposWithPRs,
        onTap: onChipTap != null
            ? () => onChipTap!(ContributionChipType.pullRequests)
            : null,
      ));
    }
    if (issues != null && issues! > 0) {
      chips.add(ContributionInfoChip.issues(
        count: issues!,
        repoCount: reposWithIssues,
        onTap: onChipTap != null
            ? () => onChipTap!(ContributionChipType.issues)
            : null,
      ));
    }
    if (reviews != null && reviews! > 0) {
      chips.add(ContributionInfoChip.reviews(
        count: reviews!,
        repoCount: reposWithReviews,
        onTap: onChipTap != null
            ? () => onChipTap!(ContributionChipType.reviews)
            : null,
      ));
    }

    if (totalRepositoriesCreated > 0) {
      chips.add(ContributionInfoChip.repositories(
        count: totalRepositoriesCreated,
        onTap: onChipTap != null
            ? () => onChipTap!(ContributionChipType.createdRepos)
            : null,
      ));
    }

    if (contributionResult != null &&
        contributionResult!.totalRestrictedContributions > 0) {
      chips.add(ContributionInfoChip.private(
        count: contributionResult!.totalRestrictedContributions,
        colorScheme: colorScheme,
        onTap: onChipTap != null
            ? () => onChipTap!(ContributionChipType.private)
            : null,
      ));
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: chips,
    );
  }
}

/// Loading state for contribution calendar section
class ContributionCalendarSectionLoading extends StatelessWidget {
  const ContributionCalendarSectionLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerWidget.container(
            height: 20,
            width: 200,
            borderRadius:
                theme.surfaceStyle.borderRadius(size: BorderRadiusSize.small),
          ),
          const SizedBox(height: 12),
          ShimmerWidget.container(
            height: 120,
            borderRadius:
                theme.surfaceStyle.borderRadius(size: BorderRadiusSize.small),
          ),
        ],
      ),
    );
  }
}
