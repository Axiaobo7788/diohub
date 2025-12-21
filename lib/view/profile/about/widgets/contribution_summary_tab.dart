import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/view/profile/about/widgets/activity_overview_section.dart';
import 'package:diohub/view/profile/about/widgets/contribution_calendar_section.dart';
import 'package:diohub/view/profile/about/widgets/contribution_highlights_section.dart';
import 'package:diohub/view/profile/about/widgets/contribution_meta_chips.dart';
import 'package:flutter/material.dart';

/// Summary tab showing calendar, badges, chips, and per-year highlights
class ContributionSummaryTab extends StatelessWidget {
  const ContributionSummaryTab({
    required this.contributionResult,
    required this.selectedYear,
    required this.customFromDate,
    required this.customToDate,
    required this.useCustomRange,
    required this.createdAt,
    super.key,
  });

  final ContributionCollectionResult contributionResult;
  final int? selectedYear;
  final DateTime? customFromDate;
  final DateTime? customToDate;
  final bool useCustomRange;
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    final viewModel = contributionResult.viewModel;
    final highlights = contributionResult.yearlyHighlights;

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        
        // Calendar section
        SliverToBoxAdapter(
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
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // Meta chips (private/restricted badge + repo counts)
        SliverToBoxAdapter(
          child: ContributionMetaChips(
            contributionResult: contributionResult,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // Activity overview
        SliverToBoxAdapter(
          child: ActivityOverviewSection(
            repositories: viewModel.commitContributionsByRepository,
            commits: viewModel.totalCommitContributions,
            issues: viewModel.totalIssueContributions,
            pullRequests: viewModel.totalPullRequestContributions,
            reviews: viewModel.totalPullRequestReviewContributions,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // Per-year highlights section
        if (highlights.isNotEmpty)
          SliverToBoxAdapter(
            child: ContributionHighlightsSection(
              yearlyHighlights: highlights,
            ),
          ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 24),
        ),
      ],
    );
  }
}

