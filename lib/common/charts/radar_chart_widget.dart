import 'package:diohub/style/opacities.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Generic radar (spider) chart with a single dataset.
/// Used for contribution radar (Commits, PRs, Issues, Reviews, Repos).
class RadarChartWidget extends StatelessWidget {
  const RadarChartWidget({
    required this.data,
    required this.labels,
    this.maxValue,
    this.fillColor,
    this.height = 200,
    super.key,
  });

  final List<double> data;
  final List<String> labels;
  final double? maxValue;
  final Color? fillColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveMax = maxValue ??
        (data.isEmpty ? 1.0 : data.reduce((a, b) => a > b ? a : b) * 1.1);
    final color = fillColor ?? colorScheme.primary;

    final dataEntries =
        data.map((v) => RadarEntry(value: v.clamp(0.0, effectiveMax))).toList();
    final maxEntries = List.generate(
      data.length.clamp(1, 10),
      (_) => RadarEntry(value: effectiveMax),
    );

    return SizedBox(
      height: height,
      child: RadarChart(
        RadarChartData(
          dataSets: <RadarDataSet>[
            RadarDataSet(
              dataEntries: maxEntries,
              fillColor: Colors.transparent,
              borderColor: Colors.transparent,
              borderWidth: 1,
            ),
            RadarDataSet(
              dataEntries: dataEntries,
              fillColor: color.tintStrong,
              borderColor: color,
              borderWidth: 2,
              entryRadius: 3,
            ),
          ],
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: colorScheme.outline.tintStrong,
            ),
          ),
          radarBorderData: BorderSide(
            color: colorScheme.primary.borderO,
          ),
          titlePositionPercentageOffset: 0.2,
          getTitle: (int index, double angle) {
            if (index >= labels.length) {
              return const RadarChartTitle(text: '');
            }
            return RadarChartTitle(text: labels[index]);
          },
          titleTextStyle: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
          tickCount: 5,
          ticksTextStyle: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant.muted,
            fontSize: 9,
          ),
          tickBorderData: BorderSide(
            color: colorScheme.outline.tintStrong,
          ),
        ),
      ),
    );
  }
}
