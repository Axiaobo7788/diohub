import 'package:diohub/common/charts/contribution_calendar_widget.dart';
import 'package:diohub_models/models/contributions/contribution_day.dart';
import 'package:diohub/common/charts/monthly_bar_chart_widget.dart';
import 'package:diohub/common/charts/radar_chart_widget.dart';
import 'package:diohub/common/charts/stat_card_widget.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/common/widgets/section_header.dart';
import 'package:diohub/view/profile/about/widgets/contribution_highlights_section.dart';
import 'package:diohub/view/profile/about/widgets/contribution_patterns_section.dart';
import 'package:flutter/material.dart';

/// Deep Dive tab: patterns, radar, monthly trend, consistency, highlights.
class ContributionDeepDiveTab extends StatelessWidget {
  const ContributionDeepDiveTab({
    required this.contributionResult,
    required this.userRef,
    required this.providerKey,
    super.key,
  });

  final ContributionCollectionResult contributionResult;
  final UserRef userRef;
  final ContributionQueryKey providerKey;

  @override
  Widget build(BuildContext context) {
    final viewModel = contributionResult.viewModel;
    final highlights = contributionResult.yearlyHighlights;
    final spacing = context.spacing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ContributionPatternsSection(weeks: viewModel.weeks),
        spacing.sectionGap,
        SectionHeader(
          title: 'Contribution Radar',
          showDivider: true,
          child: Padding(
            padding: EdgeInsets.all(spacing.itemSpacing),
            child: RadarChartWidget(
              data: <double>[
                viewModel.totalCommitContributions.toDouble(),
                viewModel.totalPullRequestContributions.toDouble(),
                viewModel.totalIssueContributions.toDouble(),
                (viewModel.totalPullRequestReviewContributions ?? 0).toDouble(),
                viewModel.commitContributionsByRepository.length.toDouble(),
              ],
              labels: const <String>[
                'Commits',
                'PRs',
                'Issues',
                'Reviews',
                'Repos',
              ],
            ),
          ),
        ),
        spacing.sectionGap,
        SectionHeader(
          title: 'Monthly Trend',
          showDivider: true,
          child: Padding(
            padding: EdgeInsets.all(spacing.itemSpacing),
            child: SizedBox(
              height: 200,
              child: MonthlyBarChart(weeks: viewModel.weeks),
            ),
          ),
        ),
        spacing.sectionGap,
        _ConsistencyScore(weeks: viewModel.weeks),
        spacing.sectionGap,
        if (highlights.isNotEmpty)
          SectionHeader(
            title: 'Highlights',
            showDivider: true,
            child: ContributionHighlightsSection(
              yearlyHighlights: highlights,
              userName: userRef.login,
            ),
          ),
        SizedBox(height: spacing.listPaddingBottom),
      ],
    );
  }
}

class _ConsistencyScore extends StatelessWidget {
  const _ConsistencyScore({required this.weeks});
  final List<List<ContributionDay>> weeks;

  @override
  Widget build(BuildContext context) {
    int totalDays = 0;
    int activeDays = 0;
    int activeWeeks = 0;
    for (final week in weeks) {
      bool weekActive = false;
      for (final day in week) {
        totalDays++;
        if (day.count > 0) {
          activeDays++;
          weekActive = true;
        }
      }
      if (weekActive) activeWeeks++;
    }

    final dayPct = totalDays > 0 ? ((activeDays / totalDays) * 100).round() : 0;
    final spacing = context.spacing;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing.itemSpacing),
      child: Row(
        children: <Widget>[
          Expanded(
            child: StatCardWidget(
              icon: Icons.calendar_today_rounded,
              value: '$activeWeeks/${weeks.length}',
              label: 'Active weeks',
            ),
          ),
          SizedBox(width: spacing.itemSpacing),
          Expanded(
            child: StatCardWidget(
              icon: Icons.percent_rounded,
              value: '$dayPct%',
              label: 'Days active',
            ),
          ),
        ],
      ),
    );
  }
}
