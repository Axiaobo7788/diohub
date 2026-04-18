import 'package:diohub/common/animations/chart_entrance.dart';
import 'package:diohub_models/models/repositories/commit_activity_entry.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bar chart showing weekly commit totals over 52 weeks.
///
/// Tooltip on tap shows the per-day breakdown (Sun–Sat) for the selected week.
class CommitActivityBarChart extends ConsumerWidget {
  const CommitActivityBarChart({
    required this.weeks,
    this.height = 200,
    this.color,
    this.anomalyIndices,
    super.key,
  });

  /// 52 weeks of commit activity, oldest first.
  final List<CommitActivityEntry> weeks;

  final double height;

  final Color? color;

  /// Indices of bars to highlight as anomalies (>2σ above mean).
  final List<int>? anomalyIndices;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color barColor = color ?? colorScheme.primary;
    final Color anomalyColor = colorScheme.error.withOpacity(0.8);
    final Set<int> anomalySet =
        anomalyIndices != null ? anomalyIndices!.toSet() : <int>{};

    if (weeks.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No commit activity',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final int maxTotal = weeks.fold<int>(
        0,
        (final int a, final CommitActivityEntry w) =>
            a > w.total ? a : w.total);
    final double maxY = maxTotal.toDouble();

    return ChartEntrance(
      child: LayoutBuilder(
        builder:
            (final BuildContext context, final BoxConstraints constraints) {
          final double barWidth = constraints.maxWidth / weeks.length * 0.7;
          return SizedBox(
            height: height,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY * 1.1,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (final _) => colorScheme.surface,
                    tooltipPadding: EdgeInsets.all(context.spacing.itemSpacing),
                    tooltipMargin: 8,
                    getTooltipItem: (final BarChartGroupData group,
                        final int groupIndex,
                        final BarChartRodData rod,
                        final int rodIndex) {
                      if (groupIndex < 0 || groupIndex >= weeks.length) {
                        return BarTooltipItem(
                            '', TextStyle(color: colorScheme.onSurface));
                      }
                      final CommitActivityEntry w = weeks[groupIndex];
                      final DateTime weekStart =
                          DateTime.fromMillisecondsSinceEpoch(w.week * 1000);
                      final List<String> dayNames = <String>[
                        'Sun',
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat'
                      ];
                      final StringBuffer sb = StringBuffer();
                      sb.writeln(
                          '${weekStart.month}/${weekStart.day} – ${weekStart.month}/${weekStart.day + 6}');
                      for (int d = 0; d < w.days.length && d < 7; d++) {
                        sb.write('${dayNames[d]}: ${w.days[d]}  ');
                      }
                      sb.write('\nTotal: ${w.total}');
                      return BarTooltipItem(
                        sb.toString(),
                        TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 12,
                      getTitlesWidget:
                          (final double value, final TitleMeta meta) {
                        final int idx = value.toInt();
                        if (idx < 0 || idx >= weeks.length)
                          return const Text('');
                        final DateTime weekStart =
                            DateTime.fromMillisecondsSinceEpoch(
                                weeks[idx].week * 1000);
                        return Text(
                          '${weekStart.month}',
                          style:
                              theme.textTheme.labelSmall?.copyWith(fontSize: 9),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget:
                          (final double value, final TitleMeta meta) {
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
                barGroups: weeks
                    .asMap()
                    .entries
                    .map((final MapEntry<int, CommitActivityEntry> e) {
                  final int i = e.key;
                  final CommitActivityEntry w = e.value;
                  return BarChartGroupData(
                    x: i,
                    barRods: <BarChartRodData>[
                      BarChartRodData(
                        toY: w.total.toDouble(),
                        width: barWidth,
                        color: anomalySet.contains(i) ? anomalyColor : barColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2),
                        ),
                      ),
                    ],
                    showingTooltipIndicators: <int>[],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
