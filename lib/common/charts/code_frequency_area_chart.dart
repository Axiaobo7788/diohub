import 'package:diohub/common/animations/chart_entrance.dart';
import 'package:diohub_models/models/repositories/code_frequency_entry.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/view/repository/widgets/config/repo_entity_config.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dual-area chart showing code additions (above axis) and deletions
/// (below axis) over the repository's lifetime.
class CodeFrequencyAreaChart extends ConsumerWidget {
  const CodeFrequencyAreaChart({
    required this.entries,
    this.height = 200,
    this.additionsColor,
    this.deletionsColor,
    this.maxEntries,
    super.key,
  });

  /// Weekly code frequency entries, oldest first.
  final List<CodeFrequencyEntry> entries;

  final double height;

  final Color? additionsColor;

  final Color? deletionsColor;

  /// When non-null, only the last [maxEntries] entries are shown.
  final int? maxEntries;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color addColor = additionsColor ?? colorScheme.primary;
    final Color delColor = deletionsColor ?? colorScheme.error;

    final List<CodeFrequencyEntry> shown =
        maxEntries != null && entries.length > maxEntries!
            ? entries.sublist(entries.length - maxEntries!)
            : entries;

    if (shown.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No code frequency data',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final List<FlSpot> addSpots = <FlSpot>[
      for (int i = 0; i < shown.length; i++)
        FlSpot(i.toDouble(), shown[i].additions.toDouble()),
    ];
    final List<FlSpot> delSpots = <FlSpot>[
      for (int i = 0; i < shown.length; i++)
        FlSpot(i.toDouble(), shown[i].deletions.toDouble()),
    ];

    final int maxAdd = shown.fold<int>(
        0,
        (final int a, final CodeFrequencyEntry e) =>
            a > e.additions ? a : e.additions);
    final int minDel = shown.fold<int>(
        0,
        (final int a, final CodeFrequencyEntry e) =>
            e.deletions < a ? e.deletions : a);
    final double maxY = maxAdd.toDouble();
    final double minY = minDel.toDouble();

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          lineBarsData: <LineChartBarData>[
            LineChartBarData(
              spots: addSpots,
              isCurved: true,
              color: addColor,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: addColor.withOpacity(0.2),
              ),
            ),
            LineChartBarData(
              spots: delSpots,
              isCurved: true,
              color: delColor,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: delColor.withOpacity(0.2),
              ),
            ),
          ],
          gridData: FlGridData(
            drawVerticalLine: false,
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
                interval: (shown.length / 4).ceilToDouble().clamp(1, 52),
                getTitlesWidget: (final double value, final TitleMeta meta) {
                  final int idx = value.toInt();
                  if (idx < 0 || idx >= shown.length) return const Text('');
                  final DateTime weekStart =
                      DateTime.fromMillisecondsSinceEpoch(
                          shown[idx].weekTimestamp * 1000);
                  if (weekStart.month == 1 && weekStart.day <= 7) {
                    return Text(
                      '${weekStart.year}',
                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
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
                getTitlesWidget: (final double value, final TitleMeta meta) {
                  if (value == meta.min || value == meta.max || value == 0) {
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
          minY: minY * 1.1,
          maxY: maxY * 1.1,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (final _) => colorScheme.surface,
              tooltipPadding: EdgeInsets.all(context.spacing.itemSpacing),
            ),
          ),
        ),
      ),
    );
  }
}
