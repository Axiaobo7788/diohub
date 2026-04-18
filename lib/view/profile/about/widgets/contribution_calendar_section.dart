import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/charts/contribution_calendar_widget.dart';
import 'package:diohub_models/models/contributions/contribution_day.dart';
import 'package:diohub/common/misc/contribution_info_chip.dart';
import 'package:diohub/common/misc/shimmer_bone.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/common/utils/contribution_utils.dart';
import 'package:diohub_models/models/contributions/contribution_chip_type.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/contribution_query_utils.dart';
import 'package:diohub/view/profile/about/widgets/day_activity_bottom_sheet.dart';
import 'package:flutter/material.dart';

/// A section widget that displays the contribution calendar with statistics.
///
/// This widget combines the contribution calendar grid with summary statistics
/// and provides interactive features like day details on tap.
class ContributionCalendarSection extends StatelessWidget {
  const ContributionCalendarSection({
    required this.weeks,
    required this.totalContributions,
    required this.providerKey,
    required this.createdAt,
    required this.userRef,
    this.colors,
    this.onDayTap,
    this.commits,
    this.pullRequests,
    this.issues,
    this.reviews,
    this.contributionResult,
    this.onChipTap,
    super.key,
  });

  /// List of weeks, each containing 7 days (Mon-Sun)
  final List<List<ContributionDay>> weeks;

  /// Total contributions in the displayed period
  final int totalContributions;

  /// Provider key containing date range information
  final ContributionQueryKey providerKey;

  /// User's GitHub account creation date (for "Since joining GitHub" option)
  final DateTime? createdAt;

  /// Color scheme for contribution levels
  final List<Color>? colors;

  /// Callback when a day is tapped
  final void Function(ContributionDay day)? onDayTap;

  /// Extract display values from providerKey
  int? get selectedYear => providerKey.dateRange.displayYear;
  DateTime? get customFromDate => providerKey.dateRange.displayFromDate;
  DateTime? get customToDate => providerKey.dateRange.displayToDate;
  bool get useCustomRange => providerKey.dateRange.isCustomRange;

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

  /// User ref for fetching day activity
  final UserRef userRef;

  /// Handle day tap - opens bottom sheet if day has contributions
  void _handleDayTap(final BuildContext context, final ContributionDay day) {
    // Call original callback if provided
    onDayTap?.call(day);

    if (day.count > 0) {
      // Ensure we're working with UTC dates
      // The day.date might be in local time, so we need to extract the date components
      // and create a UTC date to ensure we query the correct day
      final DateTime dayDate = day.date.isUtc
          ? day.date
          : DateTime.utc(day.date.year, day.date.month, day.date.day);

      // Create start of day in UTC (00:00:00)
      final DateTime dayStart = DateTime.utc(
        dayDate.year,
        dayDate.month,
        dayDate.day,
      );

      // Create end of day in UTC (23:59:59.999)
      final DateTime dayEnd = dayStart.add(
        const Duration(hours: 23, minutes: 59, seconds: 59, milliseconds: 999),
      );

      AppSheet.scrollable(
        context,
        header: AppSheetHeader.text(
          'Activity on ${formatDateOnly(dayStart)}',
          trailing: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        bodyBuilder:
            (
              final BuildContext context,
              StateSetter setState,
              ScrollController scrollController,
            ) => DayActivityBottomSheet(
              userRef: userRef,
              from: dayStart,
              to: dayEnd,
              scrollController: scrollController,
            ),
      );
    }
  }

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Use colors from GitHub API (provided via colors parameter)
    // Colors come from contributionCalendar.colors in GraphQL response
    final List<Color>? defaultColors = colors;
    if (defaultColors == null || defaultColors.isEmpty) {
      // Should not happen - colors always come from GitHub API
      // Return error state if somehow missing
      final AppSpacing spacing = context.spacing;
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.itemSpacing,
          vertical: spacing.itemSpacing,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Contribution Graph',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: spacing.compactSpacing * 2),
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

    final ContributionDateRange dateRange = providerKey.dateRange;

    // Check for "Last Year" first (it's a CustomRange with isLastYear flag)
    if (dateRange.isLastYear) {
      subtitleText = 'Last Year';
      shouldScroll = false;
    } else if (useCustomRange &&
        customFromDate != null &&
        customToDate != null) {
      final int daysDiff = customToDate!.difference(customFromDate!).inDays;
      final double yearsDiff = daysDiff / 365.25;

      // Enable scrolling for ranges > 1 year
      shouldScroll = yearsDiff > 1.0;

      if (isSinceJoining(
        useCustomRange: useCustomRange,
        customFromDate: customFromDate,
        createdAt: createdAt,
      )) {
        subtitleText = 'Since joining GitHub';
      } else {
        // Check if custom range spans exactly a full year (Jan 1 - Dec 31)
        final int? fullYear = dateRange.fullYearIfCustomRange;
        if (fullYear != null) {
          // Show just the year if it's a full year range
          subtitleText = '$fullYear';
        } else {
          // Show date range for partial year ranges
          final String fromStr = formatDateOnly(customFromDate!);
          final String toStr = formatDateOnly(customToDate!);
          subtitleText = 'from $fromStr to $toStr';
        }
      }
    } else if (selectedYear == null) {
      subtitleText = 'Last Year';
      shouldScroll = false;
    } else {
      subtitleText = '$selectedYear';
      shouldScroll = false;
    }

    final ColorScheme colorScheme = theme.colorScheme;

    // Calculate repo counts from contribution result
    int reposWithCommits = 0;
    int reposWithIssues = 0;
    int reposWithPRs = 0;
    int reposWithReviews = 0;
    int totalRepositoriesCreated = 0;

    if (contributionResult != null) {
      for (final YearlyContributionHighlights highlight
          in contributionResult!.yearlyHighlights) {
        reposWithCommits += highlight.totalRepositoriesWithContributedCommits;
        reposWithIssues += highlight.totalRepositoriesWithContributedIssues;
        reposWithPRs += highlight.totalRepositoriesWithContributedPullRequests;
        reposWithReviews +=
            highlight.totalRepositoriesWithContributedPullRequestReviews;
        totalRepositoriesCreated += highlight.totalRepositoryContributions;
      }
    }

    final AppSpacing spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.itemSpacing,
        vertical: spacing.itemSpacing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
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
          SizedBox(height: spacing.compactSpacing * 2),
          ContributionCalendarWidget(
            weeks: weeks,
            colors: defaultColors,
            onDayTap: (final ContributionDay day) =>
                _handleDayTap(context, day),
            showDayLabels: false,
            cellSize: 11,
            shouldScroll: shouldScroll,
          ),
          if (commits != null ||
              pullRequests != null ||
              issues != null ||
              reviews != null ||
              totalRepositoriesCreated > 0 ||
              (contributionResult != null &&
                  contributionResult!.totalRestrictedContributions >
                      0)) ...<Widget>[
            SizedBox(height: spacing.compactSpacing * 2),
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
    final BuildContext context,
    final ColorScheme colorScheme, {
    required final int reposWithCommits,
    required final int reposWithIssues,
    required final int reposWithPRs,
    required final int reposWithReviews,
    required final int totalRepositoriesCreated,
  }) {
    final List<Widget> chips = <Widget>[];

    if (commits != null && commits! > 0) {
      chips.add(
        ContributionInfoChip.commits(
          count: commits!,
          repoCount: reposWithCommits,
          onTap: onChipTap != null
              ? () => onChipTap!(ContributionChipType.commits)
              : null,
        ),
      );
    }
    if (pullRequests != null && pullRequests! > 0) {
      chips.add(
        ContributionInfoChip.pullRequests(
          count: pullRequests!,
          repoCount: reposWithPRs,
          onTap: onChipTap != null
              ? () => onChipTap!(ContributionChipType.pullRequests)
              : null,
        ),
      );
    }
    if (issues != null && issues! > 0) {
      chips.add(
        ContributionInfoChip.issues(
          count: issues!,
          repoCount: reposWithIssues,
          onTap: onChipTap != null
              ? () => onChipTap!(ContributionChipType.issues)
              : null,
        ),
      );
    }
    if (reviews != null && reviews! > 0) {
      chips.add(
        ContributionInfoChip.reviews(
          count: reviews!,
          repoCount: reposWithReviews,
          onTap: onChipTap != null
              ? () => onChipTap!(ContributionChipType.reviews)
              : null,
        ),
      );
    }

    if (totalRepositoriesCreated > 0) {
      chips.add(
        ContributionInfoChip.repositories(
          count: totalRepositoriesCreated,
          onTap: onChipTap != null
              ? () => onChipTap!(ContributionChipType.createdRepos)
              : null,
        ),
      );
    }

    if (contributionResult != null &&
        contributionResult!.totalRestrictedContributions > 0) {
      chips.add(
        ContributionInfoChip.private(
          count: contributionResult!.totalRestrictedContributions,
          colorScheme: colorScheme,
          onTap: onChipTap != null
              ? () => onChipTap!(ContributionChipType.private)
              : null,
        ),
      );
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    final AppSpacing spacing = context.spacing;
    return Wrap(
      spacing: spacing.compactSpacing * 2,
      runSpacing: spacing.itemSpacing,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: chips,
    );
  }
}

/// Loading state for contribution calendar section
class ContributionCalendarSectionLoading extends StatelessWidget {
  const ContributionCalendarSectionLoading({super.key});

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.itemSpacing,
        vertical: spacing.itemSpacing,
      ),
      child: ShimmerScope(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ShimmerBone.title(width: 200),
            SizedBox(height: spacing.compactSpacing * 2),
            ShimmerBone.block(height: 120),
            SizedBox(height: spacing.compactSpacing * 2),
            Wrap(
              spacing: spacing.compactSpacing * 2,
              runSpacing: spacing.itemSpacing,
              children: <Widget>[
                ShimmerBone.chip(width: 70),
                ShimmerBone.chip(),
                ShimmerBone.chip(width: 80),
                ShimmerBone.chip(width: 55),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
