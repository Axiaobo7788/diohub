import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Compact 40×16px line chart for dock pill and inline summaries.
///
/// Takes [values] (e.g. weekly counts or run outcomes) and draws a single
/// line with no grid, titles, or touch. Use in [SparklineAmbient] or
/// Repo Insights/Actions summaries.
class MiniSparkline extends StatelessWidget {
  const MiniSparkline({
    required this.values,
    this.width = 40,
    this.height = 16,
    this.color,
    super.key,
  });

  final List<double> values;
  final double width;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return SizedBox(width: width, height: height);

    final theme = Theme.of(context);
    final lineColor = color ?? theme.colorScheme.primary;

    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final range = (maxY - minY).clamp(0.001, double.infinity);

    final spots = <FlSpot>[
      for (int i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];

    return SizedBox(
      width: width,
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (values.length - 1).toDouble(),
          minY: minY - range * 0.1,
          maxY: maxY + range * 0.1,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: <LineChartBarData>[
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: lineColor,
              barWidth: 1.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
