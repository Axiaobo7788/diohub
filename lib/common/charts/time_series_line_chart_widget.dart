import 'package:diohub/common/animations/chart_entrance.dart';
import 'package:diohub/common/charts/contribution_calendar_widget.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub_models/models/contributions/contribution_day.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:diohub/style/app_spacing.dart';

/// A line chart widget showing contribution trends over time.
///
/// Displays daily or weekly contribution counts as a line chart.
class TimeSeriesLineChart extends ConsumerWidget {
  const TimeSeriesLineChart({
    required this.weeks,
    this.groupBy = TimeGrouping.daily,
    this.height = 200,
    this.width,
    this.color,
    super.key,
  });

  static final DateFormat _formatMonthDay = DateFormat('MMM d');
  static final DateFormat _formatIso = DateFormat('yyyy-MM-dd');

  /// List of weeks containing daily contribution data
  final List<List<ContributionDay>> weeks;

  /// How to group the data (daily or weekly)
  final TimeGrouping groupBy;

  /// Height of the chart
  final double height;

  /// Width of the chart (null = full width)
  final double? width;

  /// Primary color for the line
  final Color? color;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    // Aggregate data based on grouping
    final Map<String, int> dataPoints = groupBy == TimeGrouping.daily
        ? _aggregateDaily()
        : _aggregateWeekly();

    if (dataPoints.isEmpty) {
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

    final double maxValue = dataPoints.values
        .reduce((final int a, final int b) => a > b ? a : b)
        .toDouble();
    final Color chartColor = color ?? colorScheme.primary;

    return ChartEntrance(
      child: SizedBox(
        height: height,
        width: width,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: maxValue > 0 ? (maxValue / 4) : 1,
              getDrawingHorizontalLine: (final double value) =>
                  FlLine(color: colorScheme.outline.subtle, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (final double value, final TitleMeta meta) {
                    final int index = value.toInt();
                    if (index >= 0 && index < dataPoints.length) {
                      final String dateKey = dataPoints.keys.elementAt(index);
                      // Show abbreviated date
                      if (groupBy == TimeGrouping.daily) {
                        final DateTime date = DateTime.parse(dateKey);
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${date.month}/${date.day}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 9,
                            ),
                          ),
                        );
                      } else {
                        // Weekly - show week start date
                        final DateTime date = DateTime.parse(dateKey);
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${date.month}/${date.day}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 9,
                            ),
                          ),
                        );
                      }
                    }
                    return const Text('');
                  },
                  interval: groupBy == TimeGrouping.daily ? 30 : 4,
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
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(color: colorScheme.outline.tintStrong),
                left: BorderSide(color: colorScheme.outline.tintStrong),
              ),
            ),
            minX: 0,
            maxX: (dataPoints.length - 1).toDouble(),
            minY: 0,
            maxY: maxValue * 1.1,
            lineBarsData: <LineChartBarData>[
              LineChartBarData(
                spots: dataPoints.entries.toList().asMap().entries.map((
                  final MapEntry<int, MapEntry<String, int>> entry,
                ) {
                  final int index = entry.key;
                  final MapEntry<String, int> dateEntry =
                      entry.value; // MapEntry<String, int>
                  final int value = dateEntry.value; // int
                  return FlSpot(index.toDouble(), value.toDouble());
                }).toList(),
                isCurved: true,
                color: chartColor,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: chartColor.subtle),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (final _) => colorScheme.surface,
                // tooltipBorderRadius: context.radius(RadiusSize.small),
                tooltipPadding: EdgeInsets.all(context.spacing.itemSpacing),
                getTooltipItems: (final List<LineBarSpot> touchedSpots) =>
                    touchedSpots.map((final LineBarSpot spot) {
                      final int index = spot.x.toInt();
                      if (index >= 0 && index < dataPoints.length) {
                        final String dateKey = dataPoints.keys.elementAt(index);
                        final DateTime date = DateTime.parse(dateKey);
                        return LineTooltipItem(
                          '${_formatMonthDay.format(date)}\n${spot.y.toInt()} contributions',
                          TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }
                      return const LineTooltipItem('', TextStyle());
                    }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Aggregates contributions by day
  Map<String, int> _aggregateDaily() {
    final Map<String, int> dayMap = <String, int>{};

    for (final List<ContributionDay> week in weeks) {
      for (final ContributionDay day in week) {
        final String dateKey = _formatIso.format(day.date);
        dayMap[dateKey] = day.count;
      }
    }

    // Sort by date
    final List<MapEntry<String, int>> sortedEntries = dayMap.entries.toList()
      ..sort(
        (final MapEntry<String, int> a, final MapEntry<String, int> b) =>
            a.key.compareTo(b.key),
      );

    return Map.fromEntries(sortedEntries);
  }

  /// Aggregates contributions by week
  Map<String, int> _aggregateWeekly() {
    final Map<String, int> weekMap = <String, int>{};

    for (final List<ContributionDay> week in weeks) {
      if (week.isEmpty) continue;

      final DateTime firstDay = week.first.date;
      final String weekStart = _formatIso.format(firstDay);
      final int weekTotal = week.fold<int>(
        0,
        (final int sum, final ContributionDay day) => sum + day.count,
      );

      weekMap[weekStart] = weekTotal;
    }

    // Sort by date
    final List<MapEntry<String, int>> sortedEntries = weekMap.entries.toList()
      ..sort(
        (final MapEntry<String, int> a, final MapEntry<String, int> b) =>
            a.key.compareTo(b.key),
      );

    return Map.fromEntries(sortedEntries);
  }
}

/// How to group time series data
enum TimeGrouping { daily, weekly }
