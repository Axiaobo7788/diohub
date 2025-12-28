import 'package:diohub/common/charts/contribution_calendar_widget.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

/// A bar chart widget showing contributions per month.
///
/// Aggregates daily contribution data by month to show monthly trends.
class MonthlyBarChart extends StatelessWidget {
  const MonthlyBarChart({
    required this.weeks,
    this.height = 200,
    this.width,
    this.color,
    super.key,
  });

  /// List of weeks containing daily contribution data
  final List<List<ContributionDay>> weeks;

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

    // Aggregate contributions by month
    final monthlyData = _aggregateByMonth();

    if (monthlyData.isEmpty) {
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

    final maxValue = monthlyData.values.reduce((a, b) => a > b ? a : b).toDouble();
    final chartColor = color ?? colorScheme.primary;

    return SizedBox(
      height: height,
      width: width,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue * 1.1,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => colorScheme.surface,
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final monthKey = monthlyData.keys.elementAt(groupIndex);
                return BarTooltipItem(
                  '$monthKey\n${rod.toY.toInt()} contributions',
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
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < monthlyData.length) {
                    final monthKey = monthlyData.keys.elementAt(index);
                    // Show abbreviated month name
                    final parts = monthKey.split(' ');
                    if (parts.length == 2) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _getMonthAbbreviation(parts[0]),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }
                  }
                  return const Text('');
                },
                reservedSize: 30,
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
          barGroups: monthlyData.entries.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final monthEntry = entry.value; // MapEntry<String, int>
            final monthData = monthEntry.value; // int
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: monthData.toDouble(),
                  color: chartColor,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Aggregates daily contributions by month
  Map<String, int> _aggregateByMonth() {
    final monthMap = <String, int>{};

    for (final week in weeks) {
      for (final day in week) {
        final monthKey = '${_getMonthName(day.date.month)} ${day.date.year}';
        monthMap[monthKey] = (monthMap[monthKey] ?? 0) + day.count;
      }
    }

    // Sort by date
    final sortedEntries = monthMap.entries.toList()
      ..sort((a, b) {
        final aParts = a.key.split(' ');
        final bParts = b.key.split(' ');
        if (aParts.length != 2 || bParts.length != 2) return 0;
        
        final aYear = int.tryParse(aParts[1]) ?? 0;
        final bYear = int.tryParse(bParts[1]) ?? 0;
        if (aYear != bYear) return aYear.compareTo(bYear);
        
        final aMonth = _getMonthNumber(aParts[0]);
        final bMonth = _getMonthNumber(bParts[0]);
        return aMonth.compareTo(bMonth);
      });

    return Map.fromEntries(sortedEntries);
  }

  String _getMonthName(int month) {
    return DateFormat('MMMM').format(DateTime(2000, month, 1));
  }

  String _getMonthAbbreviation(String monthName) {
    final monthNumber = _getMonthNumber(monthName);
    return DateFormat('MMM').format(DateTime(2000, monthNumber, 1));
  }

  int _getMonthNumber(String monthName) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months.indexOf(monthName) + 1;
  }
}

