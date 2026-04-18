import 'package:diohub/common/charts/contribution_calendar_widget.dart';
import 'package:diohub/common/widgets/section_header.dart';
import 'package:diohub_models/models/contributions/contribution_day.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// Day-of-week contribution intensity (bars + summary).
class ContributionPatternsSection extends StatelessWidget {
  const ContributionPatternsSection({required this.weeks, super.key});

  final List<List<ContributionDay>> weeks;

  @override
  Widget build(BuildContext context) {
    final dayTotals = _aggregateByDayOfWeek(weeks);
    final maxDay = dayTotals.isEmpty
        ? 0
        : dayTotals.reduce((int a, int b) => a > b ? a : b);
    if (maxDay == 0) return const SizedBox.shrink();

    const dayLabels = <String>['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final peakDayIndex = dayTotals.indexOf(maxDay);
    final weekdayTotal = dayTotals
        .sublist(1, 6)
        .fold<int>(0, (int a, int b) => a + b);
    final weekendTotal = dayTotals[0] + dayTotals[6];
    final total = weekdayTotal + weekendTotal;
    final weekendPct = total > 0 ? ((weekendTotal / total) * 100).round() : 0;

    final theme = Theme.of(context);
    final spacing = context.spacing;

    return SectionHeader(
      title: 'Contribution Patterns',
      showDivider: true,
      child: Padding(
        padding: EdgeInsets.all(spacing.itemSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < 7; i++) ...[
              _DayBar(
                label: dayLabels[i],
                value: dayTotals[i],
                fraction: maxDay > 0 ? dayTotals[i] / maxDay : 0.0,
                isPeak: i == peakDayIndex,
              ),
            ],
            spacing.contentGap,
            Text(
              'Most active: ${dayLabels[peakDayIndex]} · Weekend: $weekendPct%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<int> _aggregateByDayOfWeek(List<List<ContributionDay>> weeks) {
  final totals = List<int>.filled(7, 0);
  for (final week in weeks) {
    for (final day in week) {
      final idx = day.date.weekday % 7;
      totals[idx] += day.count;
    }
  }
  return totals;
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.label,
    required this.value,
    required this.fraction,
    required this.isPeak,
  });
  final String label;
  final int value;
  final double fraction;
  final bool isPeak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.tightSpacing),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: spacing.itemSpacing * 4,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isPeak ? FontWeight.w600 : null,
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = (constraints.maxWidth * fraction.clamp(0.0, 1.0))
                    .clamp(0.0, constraints.maxWidth);
                return Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: isPeak
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withOpacity(0.5),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(width: spacing.tightSpacing),
          Text(
            '$value',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
