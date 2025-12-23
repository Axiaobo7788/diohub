import 'package:diohub/common/charts/stat_card_widget.dart';
import 'package:diohub/common/misc/shimmer_widget.dart';
import 'package:diohub/style/surface_style_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// A section widget that displays contribution statistics in a grid.
///
/// Shows key metrics like commits, PRs, issues, and reviews
/// in an easy-to-scan card layout.
class ContributionStatisticsSection extends StatelessWidget {
  const ContributionStatisticsSection({
    required this.commits,
    required this.pullRequests,
    required this.issues,
    this.reviews,
    this.onStatTap,
    super.key,
  });

  /// Number of commits
  final int commits;

  /// Number of pull requests
  final int pullRequests;

  /// Number of issues
  final int issues;

  /// Optional number of reviews
  final int? reviews;

  /// Callback when a stat card is tapped
  final void Function(String statType)? onStatTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final stats = <StatCardData>[
      StatCardData(
        icon: Octicons.git_commit,
        value: _formatNumber(commits),
        label: 'Commits',
        color: Colors.green.shade400,
        onTap: onStatTap != null ? () => onStatTap!('commits') : null,
      ),
      StatCardData(
        icon: Octicons.git_pull_request,
        value: _formatNumber(pullRequests),
        label: 'Pull Requests',
        color: Colors.blue.shade400,
        onTap: onStatTap != null ? () => onStatTap!('pullRequests') : null,
      ),
      StatCardData(
        icon: Octicons.issue_opened,
        value: _formatNumber(issues),
        label: 'Issues',
        color: Colors.purple.shade400,
        onTap: onStatTap != null ? () => onStatTap!('issues') : null,
      ),
      if (reviews != null)
        StatCardData(
          icon: Octicons.check,
          value: _formatNumber(reviews!),
          label: 'Reviews',
          color: Colors.orange.shade400,
          onTap: onStatTap != null ? () => onStatTap!('reviews') : null,
        ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: Theme.of(context)
            .surfaceStyle
            .borderRadius(size: BorderRadiusSize.medium),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: stats.asMap().entries.map((entry) {
              final index = entry.key;
              final stat = entry.value;
              return Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (index > 0)
                      Container(
                        width: 1,
                        height: 20,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: colorScheme.outlineVariant.withOpacity(0.3),
                      ),
                    Expanded(
                      child: StatCardWidget(
                        icon: stat.icon,
                        value: stat.value,
                        label: stat.label,
                        color: stat.color,
                        onTap: stat.onTap,
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 4),
                        iconSize: 12.0,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number < 1000) return number.toString();
    if (number < 1000000) return '${(number / 1000).toStringAsFixed(1)}k';
    return '${(number / 1000000).toStringAsFixed(1)}M';
  }
}

/// Loading state for contribution statistics section
class ContributionStatisticsSectionLoading extends StatelessWidget {
  const ContributionStatisticsSectionLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: Theme.of(context)
            .surfaceStyle
            .borderRadius(size: BorderRadiusSize.medium),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: List.generate(4, (index) {
              return Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (index > 0)
                      Container(
                        width: 1,
                        height: 20,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: Colors.grey.withOpacity(0.3),
                      ),
                    Expanded(
                      child: ShimmerWidget.container(
                        height: 40,
                        borderRadius: Theme.of(context)
                            .surfaceStyle
                            .borderRadius(size: BorderRadiusSize.small),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
