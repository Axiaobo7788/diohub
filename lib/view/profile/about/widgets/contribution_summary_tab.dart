import 'package:diohub/common/animations/fade_animation_widget.dart';
import 'package:diohub/common/widgets/section_header.dart';
import 'package:diohub/common/widgets/styled_divider.dart';
import 'package:diohub/models/contributions/contribution_chip_type.dart';
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
    required this.createdAt,
    required this.providerKey,
    this.onChipTap,
    super.key,
  });

  final ContributionCollectionResult contributionResult;
  final String userName;
  final DateTime? createdAt;
  final ContributionQueryKey providerKey;
  final void Function(ContributionChipType chipType)? onChipTap;

  /// Extract display values from providerKey
  int? get selectedYear => providerKey.dateRange.displayYear;
  DateTime? get customFromDate => providerKey.dateRange.displayFromDate;
  DateTime? get customToDate => providerKey.dateRange.displayToDate;
  bool get useCustomRange => providerKey.dateRange.isCustomRange;

  @override
  Widget build(BuildContext context) {
    final viewModel = contributionResult.viewModel;
    final highlights = contributionResult.yearlyHighlights;

    return Column(
      children: [
        // Calendar section
        FadeAnimationSection(
          duration: const Duration(milliseconds: 400),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ContributionCalendarSection(
              weeks: viewModel.weeks,
              totalContributions: viewModel.totalContributions,
              colors: viewModel.colors,
              providerKey: providerKey,
              createdAt: createdAt,
              commits: viewModel.totalCommitContributions,
              pullRequests: viewModel.totalPullRequestContributions,
              issues: viewModel.totalIssueContributions,
              reviews: viewModel.totalPullRequestReviewContributions,
              contributionResult: contributionResult,
              onChipTap: onChipTap,
              userLogin: userName,
            ),
          ),
        ),

        // Activity Overview section with header
        SectionHeader(
          title: 'Activity Overview',
          showDivider: true,
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

        // Highlights section
        if (highlights.isNotEmpty) ...[
          StyledDivider(),
          ContributionHighlightsSection(
            yearlyHighlights: highlights,
            userName: userName,
            onChipTap: onChipTap,
          ),
        ],

        const SizedBox(height: 32),
      ],
    );
  }
}
