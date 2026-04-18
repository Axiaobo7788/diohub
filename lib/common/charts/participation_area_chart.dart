import 'package:diohub/common/animations/chart_entrance.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stacked area chart showing owner contributions vs community contributions.
///
/// Replaces the previous sparkline painter with a proper fl_chart
/// area chart that supports touch tooltips and colored fill regions.
class ParticipationAreaChart extends ConsumerWidget {
  const ParticipationAreaChart({
    required this.all,
    required this.owner,
    this.height = 160,
    this.ownerColor,
    this.communityColor,
    super.key,
  });

  /// 52 weekly commit counts (all contributors).
  final List<int> all;

  /// 52 weekly commit counts (owner only).
  final List<int> owner;

  final double height;

  final Color? ownerColor;

  final Color? communityColor;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color ownerC = ownerColor ?? colorScheme.primary;
    final Color communityC = communityColor ?? colorScheme.tertiary;

    final int len = all.length > owner.length ? all.length : owner.length;
    if (len == 0) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No participation data',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final List<FlSpot> allSpots = <FlSpot>[
      for (int i = 0; i < all.length; i++)
        FlSpot(i.toDouble(), all[i].toDouble()),
    ];
    final List<FlSpot> ownerSpots = <FlSpot>[
      for (int i = 0; i < owner.length; i++)
        FlSpot(i.toDouble(), owner[i].toDouble()),
    ];
    final int maxAll = all.isEmpty
        ? 1
        : all.reduce((final int a, final int b) => a > b ? a : b);
    final double maxY = maxAll.toDouble();

    return ChartEntrance(
      child: SizedBox(
        height: height,
        child: LineChart(
          LineChartData(
            lineBarsData: <LineChartBarData>[
              LineChartBarData(
                spots: allSpots,
                isCurved: true,
                color: communityC,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: communityC.withOpacity(0.3),
                ),
              ),
              LineChartBarData(
                spots: ownerSpots,
                isCurved: true,
                color: ownerC,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: ownerC.withOpacity(0.4),
                ),
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
                  interval: 12,
                  getTitlesWidget: (final double value, final TitleMeta meta) {
                    final int idx = value.toInt();
                    if (idx < 0 || idx >= len) return const Text('');
                    return Text(
                      'W$idx',
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
                getTooltipItems: (final List<LineBarSpot> touchedSpots) {
                  if (touchedSpots.isEmpty) return <LineTooltipItem>[];
                  final int idx = touchedSpots.first.x.toInt();
                  final int ownerVal = idx < owner.length ? owner[idx] : 0;
                  final int allVal = idx < all.length ? all[idx] : 0;
                  final int communityVal = allVal - ownerVal;
                  return <LineTooltipItem>[
                    LineTooltipItem(
                      'Week $idx: Owner $ownerVal / Community $communityVal / Total $allVal',
                      TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ];
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
