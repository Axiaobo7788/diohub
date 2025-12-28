import 'package:diohub/common/charts/contribution_calendar_widget.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

/// A line chart widget showing contribution trends over time.
///
/// Displays daily or weekly contribution counts as a line chart.
class TimeSeriesLineChart extends StatelessWidget {
  const TimeSeriesLineChart({
    required this.weeks,
    this.groupBy = TimeGrouping.daily,
    this.height = 200,
    this.width,
    this.color,
    super.key,
  });

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Aggregate data based on grouping
    final dataPoints = groupBy == TimeGrouping.daily
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

    final maxValue = dataPoints.values.reduce((a, b) => a > b ? a : b).toDouble();
    final chartColor = color ?? colorScheme.primary;

    return SizedBox(
      height: height,
      width: width,
      child: LineChart(
        LineChartData(
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
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < dataPoints.length) {
                    final dateKey = dataPoints.keys.elementAt(index);
                    // Show abbreviated date
                    if (groupBy == TimeGrouping.daily) {
                      final date = DateTime.parse(dateKey);
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
                      final date = DateTime.parse(dateKey);
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
          minX: 0,
          maxX: (dataPoints.length - 1).toDouble(),
          minY: 0,
          maxY: maxValue * 1.1,
          lineBarsData: [
            LineChartBarData(
              spots: dataPoints.entries.toList().asMap().entries.map((entry) {
                final index = entry.key;
                final dateEntry = entry.value; // MapEntry<String, int>
                final value = dateEntry.value; // int
                return FlSpot(index.toDouble(), value.toDouble());
              }).toList(),
              isCurved: true,
              color: chartColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: false,
              ),
              belowBarData: BarAreaData(
                show: true,
                color: chartColor.withOpacity(0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => colorScheme.surface,
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  if (index >= 0 && index < dataPoints.length) {
                    final dateKey = dataPoints.keys.elementAt(index);
                    final date = DateTime.parse(dateKey);
                    return LineTooltipItem(
                      '${DateFormat('MMM d').format(date)}\n${spot.y.toInt()} contributions',
                      TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  }
                  return const LineTooltipItem('', TextStyle());
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Aggregates contributions by day
  Map<String, int> _aggregateDaily() {
    final dayMap = <String, int>{};

    for (final week in weeks) {
      for (final day in week) {
        final dateKey = DateFormat('yyyy-MM-dd').format(day.date);
        dayMap[dateKey] = day.count;
      }
    }

    // Sort by date
    final sortedEntries = dayMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Map.fromEntries(sortedEntries);
  }

  /// Aggregates contributions by week
  Map<String, int> _aggregateWeekly() {
    final weekMap = <String, int>{};

    for (final week in weeks) {
      if (week.isEmpty) continue;
      
      final firstDay = week.first.date;
      final weekStart = DateFormat('yyyy-MM-dd').format(firstDay);
      final weekTotal = week.fold<int>(0, (sum, day) => sum + day.count);
      
      weekMap[weekStart] = weekTotal;
    }

    // Sort by date
    final sortedEntries = weekMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Map.fromEntries(sortedEntries);
  }
}

/// How to group time series data
enum TimeGrouping {
  daily,
  weekly,
}

