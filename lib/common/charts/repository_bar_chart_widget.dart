import 'package:diohub/view/profile/about/widgets/activity_overview_section.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Sort and limit repositories
    final sortedRepos = List<ContributedRepository>.from(repositories)
      ..sort((a, b) => b.contributionCount.compareTo(a.contributionCount));
    final displayRepos = sortedRepos.take(maxRepositories).toList();

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

    final maxValue = displayRepos.first.contributionCount.toDouble();
    final chartColor = color ?? colorScheme.primary;

    // Calculate height per bar (with spacing)
    final barHeight = (height - 40) / displayRepos.length.clamp(1, maxRepositories);
    final actualBarHeight = (barHeight * 0.7).clamp(20.0, 40.0);

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
              getTooltipColor: (_) => colorScheme.surface,
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final repo = displayRepos[groupIndex];
                final repoName = repo.name.length > 20
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
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < displayRepos.length) {
                    final repo = displayRepos[index];
                    final repoName = repo.name.length > 15
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
                getTitlesWidget: (value, meta) {
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
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxValue > 0 ? (maxValue / 4) : 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: colorScheme.outline.withOpacity(0.1),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
              left: BorderSide(
                color: colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          barGroups: displayRepos.asMap().entries.map((entry) {
            final index = entry.key;
            final repo = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
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







