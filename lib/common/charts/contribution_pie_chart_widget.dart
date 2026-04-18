import 'package:diohub/common/animations/chart_entrance.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A pie chart widget showing contribution type distribution.
///
/// Displays commits, issues, pull requests, and reviews as segments.
class ContributionPieChart extends ConsumerWidget {
  const ContributionPieChart({
    required this.commits,
    required this.issues,
    required this.pullRequests,
    this.reviews,
    this.height = 200,
    this.width,
    super.key,
  });

  /// Number of commits
  final int commits;

  /// Number of issues
  final int issues;

  /// Number of pull requests
  final int pullRequests;

  /// Optional number of reviews
  final int? reviews;

  /// Height of the chart
  final double height;

  /// Width of the chart (null = full width)
  final double? width;

  /// Colors for each contribution type (distinct colors for better visualization)
  static const Map<String, Color> _typeColors = <String, Color>{
    'Commits': Color(0xFF40C463), // GitHub green
    'Issues': Color(0xFF7B1FA2), // Purple
    'Pull Requests': Color(0xFF1E88E5), // Blue
    'Reviews': Color(0xFFFFB300), // Amber
  };

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final int total = commits + issues + pullRequests + (reviews ?? 0);

    if (total == 0) {
      return SizedBox(
        height: height,
        width: width,
        child: Center(
          child: Text(
            'No contributions yet',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // Build pie chart sections
    final List<PieChartSectionData> sections = <PieChartSectionData>[];

    if (commits > 0) {
      sections.add(
        PieChartSectionData(
          value: commits.toDouble(),
          title: '${(commits / total * 100).toStringAsFixed(1)}%',
          color: _typeColors['Commits'],
          radius: 60,
          titleStyle: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      );
    }

    if (issues > 0) {
      sections.add(
        PieChartSectionData(
          value: issues.toDouble(),
          title: '${(issues / total * 100).toStringAsFixed(1)}%',
          color: _typeColors['Issues'],
          radius: 60,
          titleStyle: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      );
    }

    if (pullRequests > 0) {
      sections.add(
        PieChartSectionData(
          value: pullRequests.toDouble(),
          title: '${(pullRequests / total * 100).toStringAsFixed(1)}%',
          color: _typeColors['Pull Requests'],
          radius: 60,
          titleStyle: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      );
    }

    if (reviews != null && reviews! > 0) {
      sections.add(
        PieChartSectionData(
          value: reviews!.toDouble(),
          title: '${(reviews! / total * 100).toStringAsFixed(1)}%',
          color: _typeColors['Reviews'],
          radius: 60,
          titleStyle: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      );
    }

    return ChartEntrance(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: height,
            width: width,
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                pieTouchData: PieTouchData(
                  enabled: true,
                  touchCallback: (final FlTouchEvent event,
                      final PieTouchResponse? pieTouchResponse) {
                    // Handle touch if needed
                  },
                ),
              ),
            ),
          ),
          context.spacing.contentGap,
          _buildLegend(context),
        ],
      ),
    );
  }

  Widget _buildLegend(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final List<_LegendItem> legendItems = <_LegendItem>[];

    if (commits > 0) {
      legendItems.add(
        _LegendItem(
          label: 'Commits',
          color: _typeColors['Commits']!,
          count: commits,
        ),
      );
    }

    if (issues > 0) {
      legendItems.add(
        _LegendItem(
          label: 'Issues',
          color: _typeColors['Issues']!,
          count: issues,
        ),
      );
    }

    if (pullRequests > 0) {
      legendItems.add(
        _LegendItem(
          label: 'Pull Requests',
          color: _typeColors['Pull Requests']!,
          count: pullRequests,
        ),
      );
    }

    if (reviews != null && reviews! > 0) {
      legendItems.add(
        _LegendItem(
          label: 'Reviews',
          color: _typeColors['Reviews']!,
          count: reviews!,
        ),
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: legendItems
          .map(
            (final _LegendItem item) => Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${item.label} (${item.count})',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _LegendItem {
  const _LegendItem({
    required this.label,
    required this.color,
    required this.count,
  });

  final String label;
  final Color color;
  final int count;
}
