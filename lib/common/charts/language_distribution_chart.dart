import 'package:diohub/common/animations/chart_entrance.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Data for a single language or directory in a distribution chart.
class LanguageData {
  const LanguageData({
    required this.name,
    required this.percentage,
    this.color,
    this.size,
  });

  final String name;
  final double percentage;
  final Color? color;
  final int? size;
}

/// Horizontal bar chart for language or directory distribution.
///
/// Reused for both "Directories" and "Languages" in diff insights.
class LanguageDistributionChart extends ConsumerWidget {
  const LanguageDistributionChart({
    required this.languages,
    this.maxLanguages = 10,
    this.showPercentage = true,
    this.showSize = false,
    this.onLanguageTap,
    super.key,
  });

  final List<LanguageData> languages;
  final int maxLanguages;
  final bool showPercentage;
  final bool showSize;
  final void Function(LanguageData data)? onLanguageTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final displayed = languages.take(maxLanguages).toList();
    if (displayed.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(spacing.itemSpacing),
        child: Text(
          'No data',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ChartEntrance(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: spacing.tightSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: displayed.map((data) {
            final barColor = data.color ?? theme.colorScheme.primary;
            return Padding(
              padding: EdgeInsets.only(bottom: spacing.tightSpacing),
              child: InkWell(
                onTap:
                    onLanguageTap != null ? () => onLanguageTap!(data) : null,
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: spacing.itemSpacing * 6,
                      child: Text(
                        data.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: spacing.tightSpacing),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width =
                              (data.percentage / 100).clamp(0.0, 1.0) *
                                  constraints.maxWidth;
                          return Row(
                            children: <Widget>[
                              Container(
                                height: 8,
                                width: width.clamp(0.0, constraints.maxWidth),
                                decoration: BoxDecoration(
                                  color: barColor.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    if (showPercentage || showSize) ...[
                      SizedBox(width: spacing.tightSpacing),
                      Text(
                        [
                          if (showPercentage)
                            '${data.percentage.toStringAsFixed(1)}%',
                          if (showSize && data.size != null) '${data.size}',
                        ].join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
