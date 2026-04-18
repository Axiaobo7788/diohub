import 'package:diohub/common/animations/chart_entrance.dart';
import 'package:diohub/style/opacities.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:diohub/style/app_spacing.dart';

/// A cumulative line chart showing star history over time.
///
/// Takes a list of DateTime timestamps (when each star was added) and
/// displays them as a cumulative count chart.
class CumulativeStarChart extends StatelessWidget {
  const CumulativeStarChart({
    required this.timestamps,
    this.height = 200,
    this.width,
    this.color,
    super.key,
  });

  static final DateFormat _formatMonthDay = DateFormat('MMM d');

  /// List of star timestamps, sorted chronologically
  final List<DateTime> timestamps;

  /// Height of the chart
  final double height;

  /// Width of the chart (null = full width)
  final double? width;

  /// Primary color for the line
  final Color? color;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    if (timestamps.isEmpty) {
      return SizedBox(
        height: height,
        width: width,
        child: Center(
          child: Text(
            'No stars yet',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // Create cumulative data points
    final List<FlSpot> spots = [];
    for (int i = 0; i < timestamps.length; i++) {
      spots.add(FlSpot(i.toDouble(), (i + 1).toDouble()));
    }

    final double maxCount = timestamps.length.toDouble();
    final Color chartColor = color ?? colorScheme.primary;

    return ChartEntrance(
      child: SizedBox(
        height: height,
        width: width,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: maxCount > 10 ? (maxCount / 5) : 1,
              getDrawingHorizontalLine: (final double value) => FlLine(
                color: colorScheme.outline.subtle,
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (final double value, final TitleMeta meta) {
                    final int index = value.toInt();
                    if (index >= 0 && index < timestamps.length) {
                      // Show dates at intervals
                      final int interval = (timestamps.length / 5).ceil();
                      if (index % interval == 0 || index == timestamps.length - 1) {
                        final DateTime date = timestamps[index];
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
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (final double value, final TitleMeta meta) {
                    if (value == meta.min || value == meta.max || value == maxCount / 2) {
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
                bottom: BorderSide(
                  color: colorScheme.outline.tintStrong,
                ),
                left: BorderSide(
                  color: colorScheme.outline.tintStrong,
                ),
              ),
            ),
            minX: 0,
            maxX: (timestamps.length - 1).toDouble(),
            minY: 0,
            maxY: maxCount * 1.1,
            lineBarsData: <LineChartBarData>[
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: chartColor,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(
                  show: false,
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: chartColor.subtle,
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (final _) => colorScheme.surface,
                tooltipPadding: EdgeInsets.all(context.spacing.itemSpacing),
                getTooltipItems: (final List<LineBarSpot> touchedSpots) =>
                    touchedSpots.map((final LineBarSpot spot) {
                  final int index = spot.x.toInt();
                  if (index >= 0 && index < timestamps.length) {
                    final DateTime date = timestamps[index];
                    final int starCount = index + 1;
                    return LineTooltipItem(
                      '${_formatMonthDay.format(date)}\n$starCount stars',
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
}
