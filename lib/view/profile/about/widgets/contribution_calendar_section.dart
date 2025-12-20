import 'package:diohub/common/animations/fade_animation_widget.dart';
import 'package:diohub/common/charts/contribution_calendar_widget.dart';
import 'package:diohub/common/misc/nested_card_with_header.dart';
import 'package:diohub/common/misc/shimmer_widget.dart';
import 'package:diohub/common/utils/contribution_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

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

  /// Checks if the current custom range matches "Since joining GitHub"
  bool get _isSinceJoining {
    if (!useCustomRange || customFromDate == null || createdAt == null) {
      return false;
    }
    return customFromDate!.year == createdAt!.year &&
        customFromDate!.month == createdAt!.month &&
        customFromDate!.day == createdAt!.day;
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
      return NestedCardWithHeader(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        header: Text(
          'Contribution Graph',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        childPadding: const EdgeInsets.all(12),
        child: Text(
          'Unable to load contribution colors',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
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
    return NestedCardWithHeader(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      header: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '$totalContributions ${totalContributions == 1 ? 'contribution' : 'contributions'}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (commits != null ||
              pullRequests != null ||
              issues != null ||
              reviews != null) ...[
            const SizedBox(width: 12),
            _buildCompactStats(context, colorScheme),
          ],
        ],
      ),
      trailing: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Text(
          subtitleText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      childPadding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
      child: FadeAnimationSection(
        duration: const Duration(milliseconds: 300),
        child: ContributionCalendarWidget(
          weeks: weeks,
          colors: defaultColors,
          onDayTap: onDayTap,
          showMonthLabels: true,
          showDayLabels: false,
          cellSize: 11.0,
          cellSpacing: 2.0,
          shouldScroll: shouldScroll,
        ),
      ),
    );
  }

  Widget _buildCompactStats(BuildContext context, ColorScheme colorScheme) {
    final theme = Theme.of(context);
    final stats = <_StatItem>[];

    if (commits != null && commits! > 0) {
      stats.add(_StatItem(
        icon: Octicons.git_commit,
        value: commits!,
        color: const Color(0xFF2196F3), // Blue for commits
      ));
    }
    if (pullRequests != null && pullRequests! > 0) {
      stats.add(_StatItem(
        icon: Octicons.git_pull_request,
        value: pullRequests!,
        color: const Color(0xFF9C27B0), // Purple for pull requests
      ));
    }
    if (issues != null && issues! > 0) {
      stats.add(_StatItem(
        icon: Octicons.issue_opened,
        value: issues!,
        color: const Color(0xFF4CAF50), // Green for issues
      ));
    }
    if (reviews != null && reviews! > 0) {
      stats.add(_StatItem(
        icon: Octicons.check,
        value: reviews!,
        color: const Color(0xFFFF9800), // Orange for reviews
      ));
    }

    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: stats.map((stat) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              stat.icon,
              size: 12,
              color: stat.color,
            ),
            const SizedBox(width: 2),
            Text(
              _formatNumber(stat.value),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _formatNumber(int number) {
    if (number < 1000) return number.toString();
    if (number < 1000000) return '${(number / 1000).toStringAsFixed(1)}k';
    return '${(number / 1000000).toStringAsFixed(1)}M';
  }
}

class _StatItem {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final int value;
  final Color color;
}

/// Loading state for contribution calendar section
class ContributionCalendarSectionLoading extends StatelessWidget {
  const ContributionCalendarSectionLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return NestedCardWithHeader(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      header: ShimmerWidget.container(
        height: 20,
        width: 200,
        borderRadius: BorderRadius.circular(4),
      ),
      childPadding: const EdgeInsets.all(12),
      child: ShimmerWidget.container(
        height: 120,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
