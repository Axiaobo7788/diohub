import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// A horizontal bar chart widget showing top repositories by contribution count.
///
/// Displays repositories as horizontal bars sorted by contribution count.
class RepositoryBarChart extends StatelessWidget {
  const RepositoryBarChart({
    required this.repositories,
    this.maxRepositories = 10,
    this.height = 200,
    this.width,
    this.color,
    super.key,
  });

  /// List of repositories to display
  final List<ContributedRepository> repositories;

  /// Maximum number of repositories to display
  final int maxRepositories;

  /// Height of the chart
  final double height;

  /// Width of the chart (null = full width)
  final double? width;

  /// Primary color for bars
  final Color? color;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    // Sort and limit repositories
    final List<ContributedRepository> sortedRepos =
        List<ContributedRepository>.from(repositories)
          ..sort(
              (final ContributedRepository a, final ContributedRepository b) =>
                  b.contributionCount.compareTo(a.contributionCount));
    final List<ContributedRepository> displayRepos =
        sortedRepos.take(maxRepositories).toList();

    if (displayRepos.isEmpty) {
      return SizedBox(
        height: height,
        width: width,
        child: Center(
          child: Text(
            'No repositories to display',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final double maxValue = displayRepos.first.contributionCount.toDouble();
    final Color chartColor = color ?? colorScheme.primary;

    // Calculate height per bar (with spacing)
    final double barHeight =
        (height - 40) / displayRepos.length.clamp(1, maxRepositories);
    final double actualBarHeight = (barHeight * 0.7).clamp(20.0, 40.0);

    return SizedBox(
      height: height,
      width: width,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceBetween,
          maxY: maxValue * 1.1,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (final _) => colorScheme.surface,
              // tooltipBorderRadius: context.radius(RadiusSize.small),
              tooltipPadding: EdgeInsets.all(context.spacing.itemSpacing),
              tooltipMargin: 8,
              getTooltipItem: (final BarChartGroupData group,
                  final int groupIndex,
                  final BarChartRodData rod,
                  final int rodIndex) {
                final ContributedRepository repo = displayRepos[groupIndex];
                final String repoName = repo.name.length > 20
                    ? '${repo.name.substring(0, 20)}...'
                    : repo.name;
                return BarTooltipItem(
                  '$repoName\n${rod.toY.toInt()} contributions',
                  TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (final double value, final TitleMeta meta) {
                  final int index = value.toInt();
                  if (index >= 0 && index < displayRepos.length) {
                    final ContributedRepository repo = displayRepos[index];
                    final String repoName = repo.name.length > 15
                        ? '${repo.name.substring(0, 15)}...'
                        : repo.name;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: RotatedBox(
                        quarterTurns: 0,
                        child: Text(
                          repoName,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (final double value, final TitleMeta meta) {
                  if (value == meta.min || value == meta.max) {
                    return Text(
                      value.toInt().toString(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
          ),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: maxValue > 0 ? (maxValue / 4) : 1,
            getDrawingHorizontalLine: (final double value) => FlLine(
              color: colorScheme.outline.subtle,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outline.tintStrong,
              ),
              left: BorderSide(
                color: colorScheme.outline.tintStrong,
              ),
            ),
          ),
          barGroups: displayRepos
              .asMap()
              .entries
              .map((final MapEntry<int, ContributedRepository> entry) {
            final int index = entry.key;
            final ContributedRepository repo = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: <BarChartRodData>[
                BarChartRodData(
                  toY: repo.contributionCount.toDouble(),
                  color: chartColor,
                  width: actualBarHeight,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
