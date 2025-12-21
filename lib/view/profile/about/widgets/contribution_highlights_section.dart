import 'package:diohub/common/misc/nested_card_with_header.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Displays per-year contribution highlights
class ContributionHighlightsSection extends StatelessWidget {
  const ContributionHighlightsSection({
    required this.yearlyHighlights,
    super.key,
  });

  final List<YearlyContributionHighlights> yearlyHighlights;

  @override
  Widget build(BuildContext context) {
    // Only show if we have multi-year data or interesting single-year data
    if (yearlyHighlights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: NestedCardWithHeader(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        header: Text(
          'Highlights by year',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        childPadding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: yearlyHighlights.asMap().entries.map((entry) {
            return _YearHighlightItem(
              highlight: entry.value,
              isLast: entry.key == yearlyHighlights.length - 1,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _YearHighlightItem extends StatelessWidget {
  const _YearHighlightItem({
    required this.highlight,
    required this.isLast,
  });

  final YearlyContributionHighlights highlight;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Year header
          Row(
            children: [
              Text(
                '${highlight.year}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDateRange(highlight.fromDate, highlight.toDate),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Per-year chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              // Restricted contributions
              if (highlight.restrictedContributionsCount > 0)
                _buildSmallChip(
                  context,
                  icon: Octicons.lock,
                  label: '${highlight.restrictedContributionsCount} private',
                  color: theme.colorScheme.tertiary,
                ),

              // Repo counts
              if (highlight.totalRepositoriesWithContributedCommits > 0)
                _buildSmallChip(
                  context,
                  icon: Octicons.git_commit,
                  label:
                      '${highlight.totalRepositoriesWithContributedCommits} repos',
                  color: const Color(0xFF2196F3),
                ),

              if (highlight.totalRepositoriesWithContributedIssues > 0)
                _buildSmallChip(
                  context,
                  icon: Octicons.issue_opened,
                  label:
                      '${highlight.totalRepositoriesWithContributedIssues} repos',
                  color: const Color(0xFF4CAF50),
                ),

              if (highlight.totalRepositoriesWithContributedPullRequests > 0)
                _buildSmallChip(
                  context,
                  icon: Octicons.git_pull_request,
                  label:
                      '${highlight.totalRepositoriesWithContributedPullRequests} repos',
                  color: const Color(0xFF9C27B0),
                ),

              // Month count
              if (highlight.calendarMonths.isNotEmpty)
                _buildSmallChip(
                  context,
                  icon: Octicons.calendar,
                  label:
                      '${highlight.calendarMonths.length} ${highlight.calendarMonths.length == 1 ? 'month' : 'months'}',
                  color: theme.colorScheme.secondary,
                ),
            ],
          ),

          // Divider (except for last item)
          if (!isLast)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDateRange(DateTime from, DateTime to) {
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    if (from.year == to.year && from.month == to.month) {
      return '${monthNames[from.month - 1]} ${from.day}-${to.day}';
    } else if (from.year == to.year) {
      return '${monthNames[from.month - 1]} ${from.day} - ${monthNames[to.month - 1]} ${to.day}';
    } else {
      return '${monthNames[from.month - 1]} ${from.day}, ${from.year} - ${monthNames[to.month - 1]} ${to.day}, ${to.year}';
    }
  }

  Widget _buildSmallChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

