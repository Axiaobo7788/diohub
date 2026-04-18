import 'package:diohub/common/charts/stat_card_widget.dart';
import 'package:diohub/common/misc/shimmer_bone.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/contribution_colors.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
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
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final List<StatCardData> stats = <StatCardData>[
      StatCardData(
        icon: Octicons.git_commit,
        value: _formatNumber(commits),
        label: 'Commits',
        color: ContributionColors.commit,
        onTap: onStatTap != null ? () => onStatTap!('commits') : null,
      ),
      StatCardData(
        icon: Octicons.git_pull_request,
        value: _formatNumber(pullRequests),
        label: 'Pull Requests',
        color: ContributionColors.pullRequest,
        onTap: onStatTap != null ? () => onStatTap!('pullRequests') : null,
      ),
      StatCardData(
        icon: Octicons.issue_opened,
        value: _formatNumber(issues),
        label: 'Issues',
        color: ContributionColors.issue,
        onTap: onStatTap != null ? () => onStatTap!('issues') : null,
      ),
      if (reviews != null)
        StatCardData(
          icon: Octicons.check,
          value: _formatNumber(reviews!),
          label: 'Reviews',
          color: ContributionColors.review,
          onTap: onStatTap != null ? () => onStatTap!('reviews') : null,
        ),
    ];

    final AppSpacing spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.itemSpacing,
        vertical: spacing.itemSpacing,
      ),
      child: Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: context.radius(RadiusSize.medium),
        child: Padding(
          padding: context.spacing.contentPadding,
          child: Row(
            children: stats
                .asMap()
                .entries
                .map((final MapEntry<int, StatCardData> entry) {
              final int index = entry.key;
              final StatCardData stat = entry.value;
              return Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (index > 0)
                      Container(
                        width: 1,
                        height: 20,
                        margin: context.spacing.listInset,
                        color: colorScheme.outlineVariant.borderO,
                      ),
                    Expanded(
                      child: StatCardWidget(
                        icon: stat.icon,
                        value: stat.value,
                        label: stat.label,
                        color: stat.color,
                        onTap: stat.onTap,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        iconSize: 12,
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

  String _formatNumber(final int number) {
    if (number < 1000) return number.toString();
    if (number < 1000000) return '${(number / 1000).toStringAsFixed(1)}k';
    return '${(number / 1000000).toStringAsFixed(1)}M';
  }
}

/// Loading state for contribution statistics section
class ContributionStatisticsSectionLoading extends StatelessWidget {
  const ContributionStatisticsSectionLoading({super.key});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppSpacing spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.itemSpacing,
        vertical: spacing.itemSpacing,
      ),
      child: Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: context.radius(RadiusSize.medium),
        child: Padding(
          padding: context.spacing.contentPadding,
          child: ShimmerScope(
            child: Row(
              children: List.generate(
                4,
                (final int index) => Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      if (index > 0)
                        Container(
                          width: 1,
                          height: 20,
                          margin: context.spacing.listInset,
                          color: Colors.grey.borderO,
                        ),
                      const Expanded(
                        child: ShimmerBone.block(
                          height: 40,
                          radiusSize: RadiusSize.small,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
