import 'package:diohub/common/charts/contribution_calendar_widget.dart';
import 'package:diohub_models/models/contributions/contribution_day.dart';
import 'package:diohub/common/charts/stat_card_widget.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Displays current and longest contribution streak from calendar weeks.
class ContributionStreakSection extends StatelessWidget {
  const ContributionStreakSection({required this.weeks, super.key});

  final List<List<ContributionDay>> weeks;

  @override
  Widget build(BuildContext context) {
    final streak = _computeStreak(weeks);
    if (streak.current == 0 && streak.longest == 0) {
      return const SizedBox.shrink();
    }

    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.all(spacing.itemSpacing),
      child: Row(
        children: <Widget>[
          Expanded(
            child: StatCardWidget(
              icon: Icons.local_fire_department_rounded,
              value: '${streak.current}',
              label: 'Current streak',
              color: streak.current > 0 ? Colors.orange : null,
            ),
          ),
          SizedBox(width: spacing.itemSpacing),
          Expanded(
            child: StatCardWidget(
              icon: Icons.emoji_events_rounded,
              value: '${streak.longest}',
              label: 'Longest streak',
              color: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }
}

({int current, int longest}) _computeStreak(List<List<ContributionDay>> weeks) {
  final List<ContributionDay> flat = <ContributionDay>[];
  for (final week in weeks) {
    for (final day in week) {
      flat.add(day);
    }
  }
  if (flat.isEmpty) return (current: 0, longest: 0);
  flat.sort((a, b) => a.date.compareTo(b.date));

  int longest = 0;
  int current = 0;
  int run = 0;
  final DateTime today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  for (final day in flat) {
    final dayStart = DateTime(day.date.year, day.date.month, day.date.day);
    if (day.count > 0) {
      run++;
      if (run > longest) longest = run;
    } else {
      run = 0;
    }
  }

  run = 0;
  for (int i = flat.length - 1; i >= 0; i--) {
    final day = flat[i];
    final dayStart = DateTime(day.date.year, day.date.month, day.date.day);
    if (dayStart.isAfter(today)) continue;
    if (dayStart.isBefore(today) && run > 0) break;
    if (day.count > 0) {
      run++;
    } else {
      break;
    }
  }
  current = run;

  return (current: current, longest: longest);
}
