import 'package:diohub/common/animations/chart_entrance.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dual-line traffic chart showing total count and unique visitors/cloners.
///
/// Used for both Traffic Views and Traffic Clones — the caller passes the
/// appropriate entries list.
class TrafficLineChart extends ConsumerWidget {
  const TrafficLineChart({
    required this.timestamps,
    required this.counts,
    required this.uniques,
    this.height = 200,
    this.countColor,
    this.uniquesColor,
    super.key,
  });

  /// ISO-8601 timestamp strings from [TrafficViewEntry.timestamp] /
  /// [TrafficCloneEntry.timestamp].
  final List<String?> timestamps;

  /// Total count values (parallel to [timestamps]).
  final List<int> counts;

  /// Unique count values (parallel to [timestamps]).
  final List<int> uniques;

  final double height;

  /// Color for the total count line. Defaults to [ColorScheme.primary].
  final Color? countColor;

  /// Color for the uniques line. Defaults to [ColorScheme.tertiary].
  final Color? uniquesColor;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color cColor = countColor ?? colorScheme.primary;
    final Color uColor = uniquesColor ?? colorScheme.tertiary;

    if (counts.isEmpty && uniques.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No data',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final List<FlSpot> countSpots = <FlSpot>[
      for (int i = 0; i < counts.length; i++)
        FlSpot(i.toDouble(), counts[i].toDouble()),
    ];
    final List<FlSpot> uniqueSpots = <FlSpot>[
      for (int i = 0; i < uniques.length; i++)
        FlSpot(i.toDouble(), uniques[i].toDouble()),
    ];

    final int maxVal = <int>[...counts, ...uniques]
        .fold<int>(0, (final int a, final int b) => a > b ? a : b);
    final double maxY = maxVal.toDouble();

    return ChartEntrance(
      child: SizedBox(
        height: height,
        child: LineChart(
          LineChartData(
            lineBarsData: <LineChartBarData>[
              LineChartBarData(
                spots: countSpots,
                isCurved: true,
                color: cColor,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: cColor.withOpacity(0.1),
                ),
              ),
              LineChartBarData(
                spots: uniqueSpots,
                isCurved: true,
                color: uColor,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                dashArray: <int>[5, 3],
              ),
            ],
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: maxY > 0 ? (maxY / 4) : 1,
              getDrawingHorizontalLine: (final double value) => FlLine(
                color: colorScheme.outline.withOpacity(0.2),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 3,
                  getTitlesWidget: (final double value, final TitleMeta meta) {
                    final int idx = value.toInt();
                    if (idx < 0 || idx >= timestamps.length) {
                      return const Text('');
                    }
                    final String? ts = timestamps[idx];
                    if (ts == null) return const Text('');
                    final DateTime? date = DateTime.tryParse(ts);
                    if (date == null) return const Text('');
                    return Text(
                      '${date.month}/${date.day}',
                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
                    );
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
                        style: theme.textTheme.labelSmall,
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
                bottom: BorderSide(color: colorScheme.outline),
                left: BorderSide(color: colorScheme.outline),
              ),
            ),
            minY: 0,
            maxY: maxY * 1.1,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (final _) => colorScheme.surface,
                tooltipPadding: EdgeInsets.all(context.spacing.itemSpacing),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
