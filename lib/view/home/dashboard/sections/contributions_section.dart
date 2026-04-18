import 'package:diohub/common/charts/contribution_calendar_widget.dart';
import 'package:diohub/common/widgets/dashboard_section_header.dart';
import 'package:diohub_models/models/contributions/contribution_day.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub_graphql/queries/viewer/viewer_typedefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Dashboard contributions section showing recent contribution calendar.
class DashboardContributionsSection extends ConsumerWidget {
  const DashboardContributionsSection({required this.data, super.key});

  final DashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.spacing;
    final contributions = data.viewer.contributionsCollection;
    final calendar = contributions.contributionCalendar;

    if (calendar.totalContributions == 0) {
      return const SizedBox.shrink();
    }

    final weeks = calendar.weeks
        .map(
          (week) => week.contributionDays
              .map(
                (day) => ContributionDay(
                  date: day.date,
                  count: day.contributionCount,
                ),
              )
              .toList(),
        )
        .toList();

    return Padding(
      padding: spacing.screenPadding.copyWith(top: spacing.sectionSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardSectionHeader(
            title: 'Contributions (Last 7 Days)',
            icon: Octicons.calendar,
            count: calendar.totalContributions,
          ),
          spacing.itemGap,
          ContributionCalendarWidget(weeks: weeks),
        ],
      ),
    );
  }
}
