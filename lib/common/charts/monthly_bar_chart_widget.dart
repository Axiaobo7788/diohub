import 'package:diohub/common/animations/chart_entrance.dart';
import 'package:diohub/common/charts/contribution_calendar_widget.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub_models/models/contributions/contribution_day.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// A bar chart widget showing contributions per month.
///
/// Aggregates daily contribution data by month to show monthly trends.
class MonthlyBarChart extends ConsumerWidget {
  const MonthlyBarChart({
    required this.weeks,
    this.height = 200,
    this.width,
    this.color,
    super.key,
  });

  static final DateFormat _formatMonthFull = DateFormat('MMMM');
  static final DateFormat _formatMonthAbbr = DateFormat('MMM');

  /// List of weeks containing daily contribution data
  final List<List<ContributionDay>> weeks;

  /// Height of the chart
  final double height;

  /// Width of the chart (null = full width)
  final double? width;

  /// Primary color for bars
  final Color? color;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    // Aggregate contributions by month
    final Map<String, int> monthlyData = _aggregateByMonth();

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

    final double maxValue = monthlyData.values
        .reduce((final int a, final int b) => a > b ? a : b)
        .toDouble();
    final Color chartColor = color ?? colorScheme.primary;

    return ChartEntrance(
      child: SizedBox(
        height: height,
        width: width,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxValue * 1.1,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (final _) => colorScheme.surface,
                // tooltipBorderRadius: context.radius(RadiusSize.small),
                tooltipPadding: EdgeInsets.all(context.spacing.itemSpacing),
                tooltipMargin: 8,
                getTooltipItem:
                    (
                      final BarChartGroupData group,
                      final int groupIndex,
                      final BarChartRodData rod,
                      final int rodIndex,
                    ) {
                      final String monthKey = monthlyData.keys.elementAt(
                        groupIndex,
                      );
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
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (final double value, final TitleMeta meta) {
                    final int index = value.toInt();
                    if (index >= 0 && index < monthlyData.length) {
                      final String monthKey = monthlyData.keys.elementAt(index);
                      // Show abbreviated month name
                      final List<String> parts = monthKey.split(' ');
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
              getDrawingHorizontalLine: (final double value) =>
                  FlLine(color: colorScheme.outline.subtle, strokeWidth: 1),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(color: colorScheme.outline.tintStrong),
                left: BorderSide(color: colorScheme.outline.tintStrong),
              ),
            ),
            barGroups: monthlyData.entries.toList().asMap().entries.map((
              final MapEntry<int, MapEntry<String, int>> entry,
            ) {
              final int index = entry.key;
              final MapEntry<String, int> monthEntry =
                  entry.value; // MapEntry<String, int>
              final int monthData = monthEntry.value; // int
              return BarChartGroupData(
                x: index,
                barRods: <BarChartRodData>[
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
      ),
    );
  }

  /// Aggregates daily contributions by month
  Map<String, int> _aggregateByMonth() {
    final Map<String, int> monthMap = <String, int>{};

    for (final List<ContributionDay> week in weeks) {
      for (final ContributionDay day in week) {
        final String monthKey =
            '${_getMonthName(day.date.month)} ${day.date.year}';
        monthMap[monthKey] = (monthMap[monthKey] ?? 0) + day.count;
      }
    }

    // Sort by date
    final List<MapEntry<String, int>> sortedEntries = monthMap.entries.toList()
      ..sort((final MapEntry<String, int> a, final MapEntry<String, int> b) {
        final List<String> aParts = a.key.split(' ');
        final List<String> bParts = b.key.split(' ');
        if (aParts.length != 2 || bParts.length != 2) return 0;

        final int aYear = int.tryParse(aParts[1]) ?? 0;
        final int bYear = int.tryParse(bParts[1]) ?? 0;
        if (aYear != bYear) return aYear.compareTo(bYear);

        final int aMonth = _getMonthNumber(aParts[0]);
        final int bMonth = _getMonthNumber(bParts[0]);
        return aMonth.compareTo(bMonth);
      });

    return Map.fromEntries(sortedEntries);
  }

  String _getMonthName(final int month) =>
      _formatMonthFull.format(DateTime(2000, month));

  String _getMonthAbbreviation(final String monthName) {
    final int monthNumber = _getMonthNumber(monthName);
    return _formatMonthAbbr.format(DateTime(2000, monthNumber));
  }

  int _getMonthNumber(final String monthName) {
    final List<String> months = <String>[
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
      'December',
    ];
    return months.indexOf(monthName) + 1;
  }
}
