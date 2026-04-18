import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/widgets/section_header.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_models/models/contributions/contribution_chip_type.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/view/profile/about/widgets/contribution_calendar_section.dart';
import 'package:diohub/view/profile/about/widgets/contribution_statistics_section.dart';
import 'package:diohub/view/profile/about/widgets/contribution_streak_section.dart';
import 'package:diohub/view/profile/about/widgets/top_languages_section.dart';
import 'package:diohub/common/misc/repository_card.dart';
import 'package:flutter/material.dart';

/// Summary tab showing calendar, radar chart, badges, chips, and per-year highlights
class ContributionSummaryTab extends StatelessWidget {
  const ContributionSummaryTab({
    required this.contributionResult,
    required this.userRef,
    required this.createdAt,
    required this.providerKey,
    this.pinnedItems = const <RepoCardData>[],
    this.onChipTap,
    super.key,
  });

  final ContributionCollectionResult contributionResult;
  final UserRef userRef;
  final DateTime? createdAt;
  final ContributionQueryKey providerKey;
  final List<RepoCardData> pinnedItems;
  final void Function(ContributionChipType chipType)? onChipTap;

  /// Extract display values from providerKey
  int? get selectedYear => providerKey.dateRange.displayYear;
  DateTime? get customFromDate => providerKey.dateRange.displayFromDate;
  DateTime? get customToDate => providerKey.dateRange.displayToDate;
  bool get useCustomRange => providerKey.dateRange.isCustomRange;

  @override
  Widget build(final BuildContext context) {
    final ContributionViewModel viewModel = contributionResult.viewModel;
    final AppSpacing spacing = context.spacing;

    return Column(
      children: <Widget>[
        // Pinned Repos section (conditional)
        if (pinnedItems.isNotEmpty) ...<Widget>[
          SectionHeader(
            title: 'Pinned',
            style: SectionHeaderStyle.medium,
            child: SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: pinnedItems.length,
                itemExtent: 280,
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.itemSpacing,
                  vertical: spacing.itemSpacing,
                ),
                itemBuilder: (final BuildContext context, final int index) {
                  final RepoCardData repo = pinnedItems[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < pinnedItems.length - 1
                          ? spacing.itemSpacing
                          : 0,
                    ),
                    child: BorderedContainer(
                      ref: RepoRef.fromRepoCardFields(repo),
                      child: RepositoryCard(
                        repo,
                        showOwner: false,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],

        // Contribution streak
        ContributionStreakSection(weeks: viewModel.weeks),

        // Calendar section
        Padding(
          padding: EdgeInsets.all(spacing.itemSpacing),
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
            userRef: userRef,
          ),
        ),

        // Contribution statistics (commits, PRs, issues, reviews)
        ContributionStatisticsSection(
          commits: viewModel.totalCommitContributions,
          pullRequests: viewModel.totalPullRequestContributions,
          issues: viewModel.totalIssueContributions,
          reviews: viewModel.totalPullRequestReviewContributions,
          onStatTap: onChipTap != null
              ? (final String statType) {
                  final ContributionChipType? chipType =
                      ContributionChipType.fromStatType(statType);
                  if (chipType != null) onChipTap!(chipType);
                }
              : null,
        ),

        // Top Languages
        if (viewModel.commitContributionsByRepository.isNotEmpty)
          TopLanguagesSection(
            repositories: viewModel.commitContributionsByRepository,
          ),

        // Focus Areas (top repos by commit count)
        if (viewModel.commitContributionsByRepository.isNotEmpty)
          SectionHeader(
            title: 'Focus Areas',
            showDivider: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: viewModel.commitContributionsByRepository
                  .take(5)
                  .map(
                    (repo) => BorderedContainer(
                      ref: RepoRef(
                        owner: repo.owner,
                        name: repo.name,
                      ),
                      child: ListTile(
                        title: Text(repo.graphQLRepository.nameWithOwner),
                        subtitle: Text(
                          '${repo.contributionCount} contributions',
                        ),
                        dense: true,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

        SizedBox(height: spacing.listPaddingBottom),
      ],
    );
  }
}
