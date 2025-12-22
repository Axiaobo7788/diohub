import 'package:diohub/common/animations/fade_animation_widget.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/view/profile/about/widgets/activity_overview_section.dart';
import 'package:diohub/view/profile/about/widgets/contribution_calendar_section.dart';
import 'package:diohub/view/profile/about/widgets/contribution_highlights_section.dart';
import 'package:flutter/material.dart';

/// Summary tab showing calendar, radar chart, badges, chips, and per-year highlights
class ContributionSummaryTab extends StatelessWidget {
  const ContributionSummaryTab({
    required this.contributionResult,
    required this.userName,
    required this.selectedYear,
    required this.customFromDate,
    required this.customToDate,
    required this.useCustomRange,
    required this.createdAt,
    super.key,
  });

  final ContributionCollectionResult contributionResult;
  final String userName;
  final int? selectedYear;
  final DateTime? customFromDate;
  final DateTime? customToDate;
  final bool useCustomRange;
  final DateTime? createdAt;

  @override
  Widget build(BuildContext context) {
    final viewModel = contributionResult.viewModel;
    final highlights = contributionResult.yearlyHighlights;

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // Calendar section
        SliverToBoxAdapter(
          child: FadeAnimationSection(
            duration: const Duration(milliseconds: 400),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ContributionCalendarSection(
                weeks: viewModel.weeks,
                totalContributions: viewModel.totalContributions,
                colors: viewModel.colors,
                availableYears: viewModel.contributionYears,
                selectedYear: selectedYear,
                customFromDate: customFromDate,
                customToDate: customToDate,
                useCustomRange: useCustomRange,
                createdAt: createdAt,
                commits: viewModel.totalCommitContributions,
                pullRequests: viewModel.totalPullRequestContributions,
                issues: viewModel.totalIssueContributions,
                reviews: viewModel.totalPullRequestReviewContributions,
                contributionResult: contributionResult,
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // Divider between calendar and activity overview
        SliverToBoxAdapter(
          child: Divider(),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // Activity overview (radar chart) section
        SliverToBoxAdapter(
          child: FadeAnimationSection(
            duration: const Duration(milliseconds: 400),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ActivityOverviewSection(
                repositories: viewModel.commitContributionsByRepository,
                commits: viewModel.totalCommitContributions,
                issues: viewModel.totalIssueContributions,
                pullRequests: viewModel.totalPullRequestContributions,
                reviews: viewModel.totalPullRequestReviewContributions,
              ),
            ),
          ),
        ),

        // Divider between activity overview and highlights
        if (highlights.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(
            child: Divider(),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
        ],

        // Per-year highlights section
        if (highlights.isNotEmpty)
          SliverToBoxAdapter(
            child: ContributionHighlightsSection(
              yearlyHighlights: highlights,
              userName: userName,
            ),
          ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 24),
        ),
      ],
    );
  }
}
