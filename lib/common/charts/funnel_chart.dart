import 'package:flutter/material.dart';

/// A single stage in the funnel.
class FunnelStage {
  const FunnelStage({
    required this.label,
    required this.value,
    this.rate,
  });

  final String label;
  final int value;

  /// Conversion rate from the previous stage (e.g. 0.042 = 4.2%).
  /// Null for the first stage.
  final double? rate;
}

/// A simple funnel/stepped bar chart showing conversion between stages.
///
/// Each stage is rendered as a centered horizontal bar whose width is
/// proportional to its value. Labels show the value and conversion rate.
class FunnelChart extends StatelessWidget {
  const FunnelChart({
    required this.stages,
    this.height = 120,
    this.color,
    super.key,
  });

  /// Ordered list of funnel stages. First stage is the widest.
  final List<FunnelStage> stages;

  final double height;

  final Color? color;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color baseColor = color ?? colorScheme.primary;

    if (stages.isEmpty) {
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

    final int maxValue = stages.fold<int>(
        0, (final int a, final FunnelStage s) => a > s.value ? a : s.value);
    if (maxValue == 0) {
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

    final double stageHeight = height / stages.length;
    final TextStyle labelStyle = theme.textTheme.bodySmall ?? const TextStyle();
    final TextStyle valueStyle = theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ) ??
        const TextStyle();

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder:
            (final BuildContext context, final BoxConstraints constraints) {
          final double fullWidth = constraints.maxWidth;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 0; i < stages.length; i++) ...[
                SizedBox(
                  height: stageHeight,
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 80,
                        child: Text(
                          stages[i].label,
                          style: labelStyle.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Container(
                            height: stageHeight * 0.6,
                            width:
                                fullWidth * (stages[i].value / maxValue) * 0.6,
                            decoration: BoxDecoration(
                              color: baseColor.withOpacity(0.2 +
                                  0.2 * (stages.length - i) / stages.length),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${stages[i].value}',
                              style: valueStyle,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 56,
                        child: stages[i].rate != null
                            ? Text(
                                '${(stages[i].rate! * 100).toStringAsFixed(1)}%',
                                style: labelStyle.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                                textAlign: TextAlign.end,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
