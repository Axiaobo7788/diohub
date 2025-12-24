import 'package:diohub/common/animations/fade_animation_widget.dart';
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
    required this.selectedYear,
    required this.customFromDate,
    required this.customToDate,
    required this.useCustomRange,
    required this.createdAt,
    this.onChipTap,
    super.key,
  });

  final ContributionCollectionResult contributionResult;
  final String userName;
  final int? selectedYear;
  final DateTime? customFromDate;
  final DateTime? customToDate;
  final bool useCustomRange;
  final DateTime? createdAt;
  final void Function(ContributionChipType chipType)? onChipTap;

  /// Builds a styled section divider with gradient effect
  Widget _buildSectionDivider(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              colorScheme.outlineVariant.withOpacity(0.3),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a consistent section header
  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

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
              onChipTap: onChipTap,
              userLogin: userName,
            ),
          ),
        ),

        // Activity Overview section with header
        _buildSectionDivider(context),

        _buildSectionHeader(context, 'Activity Overview'),

        FadeAnimationSection(
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

        // Highlights section
        if (highlights.isNotEmpty) ...[
          _buildSectionDivider(context),
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
