import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/cards/metadata_chips.dart';
import 'package:diohub/common/charts/chart_carousel_widget.dart';
import 'package:diohub/common/charts/contribution_calendar_widget.dart';
import 'package:diohub_models/models/contributions/contribution_day.dart';
import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/common/misc/shimmer_bone.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/view/profile/about/widgets/contribution_breakdown_row.dart';
import 'package:flutter/material.dart';

/// A section widget that displays activity overview with repositories and radar chart.
///
/// This matches GitHub's "Activity overview" section with:
/// - Left: List of contributed repositories
/// - Right: Radar chart showing contribution distribution
class ActivityOverviewSection extends StatelessWidget {
  const ActivityOverviewSection({
    required this.repositories,
    required this.commits,
    required this.issues,
    required this.pullRequests,
    required this.weeks,
    this.reviews,
    this.onRepositoryTap,
    super.key,
  });

  /// List of repositories user contributed to
  final List<ContributedRepository> repositories;

  /// Number of commits
  final int commits;

  /// Number of issues
  final int issues;

  /// Number of pull requests
  final int pullRequests;

  /// Optional number of reviews
  final int? reviews;

  /// List of weeks containing daily contribution data
  final List<List<ContributionDay>> weeks;

  /// Callback when a repository is tapped
  final void Function(ContributedRepository repo)? onRepositoryTap;

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.itemSpacing,
        vertical: spacing.itemSpacing,
      ),
      child: LayoutBuilder(
        builder:
            (final BuildContext context, final BoxConstraints constraints) {
              // On smaller screens, stack vertically
              if (constraints.maxWidth < 600) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildContributedTo(context),
                    spacing.sectionGap,
                    _buildCodeReviewChart(context),
                  ],
                );
              }
              // On larger screens, side by side
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: _buildContributedTo(context)),
                  spacing.itemGap,
                  Expanded(child: _buildCodeReviewChart(context)),
                ],
              );
            },
      ),
    );
  }

  Widget _buildContributedTo(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    if (repositories.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Contributed to',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          context.spacing.itemGap,
          Text(
            'No contributions yet',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final bool hasMoreThanTwo = repositories.length > 2;
    final List<ContributedRepository> displayRepos = repositories
        .take(2)
        .toList();
    final int remainingCount = repositories.length - displayRepos.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Contributed to',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        context.spacing.itemGap,
        ...displayRepos.asMap().entries.map((
          final MapEntry<int, ContributedRepository> entry,
        ) {
          final ContributedRepository repo = entry.value;
          final RepoCardData repoData = repo.graphQLRepository;
          return Padding(
            padding: EdgeInsets.only(bottom: context.spacing.itemSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                BorderedContainer(
                  ref: RepoRef.fromRepoCardFields(repoData),
                  child: RepositoryCard(repoData),
                ),
                ContributionBreakdownRow(
                  commits: repo.commitCount,
                  reviews: repo.reviewCount,
                  issues: repo.issueCount,
                  pullRequests: repo.pullRequestCount,
                ),
              ],
            ),
          );
        }),
        if (hasMoreThanTwo)
          Padding(
            padding: EdgeInsets.only(top: context.spacing.tightSpacing),
            child: ShowMoreChip(
              remainingCount: remainingCount,
              entityLabel: remainingCount == 1 ? 'repository' : 'repositories',
              onTap: () => _showAllRepositoriesSheet(context),
            ),
          ),
      ],
    );
  }

  Widget _buildCodeReviewChart(final BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Code review',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        SizedBox(height: context.spacing.compactSpacing * 2),
        ChartCarousel(
          repositories: repositories,
          commits: commits,
          issues: issues,
          pullRequests: pullRequests,
          reviews: reviews,
          weeks: weeks,
          height: 150,
        ),
        SizedBox(height: context.spacing.compactSpacing * 2),
      ],
    );
  }

  void _showAllRepositoriesSheet(final BuildContext context) {
    AppSheet.scrollable(
      context,
      header: AppSheetHeader.text(
        'Contributed Repositories',
        trailing: CloseButton(onPressed: () => Navigator.of(context).pop()),
      ),
      bodyBuilder:
          (
            final BuildContext context,
            final setState,
            final ScrollController scrollController,
          ) => ListView.builder(
            controller: scrollController,
            padding: context.spacing.pagePadding,
            itemCount: repositories.length,
            itemBuilder: (final BuildContext context, final int index) {
              final ContributedRepository repo = repositories[index];
              final RepoCardData repoData = repo.graphQLRepository;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < repositories.length - 1
                      ? context.spacing.compactSpacing * 2
                      : 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    BorderedContainer(
                      ref: RepoRef.fromRepoCardFields(repoData),
                      child: RepositoryCard(repoData),
                    ),
                    ContributionBreakdownRow(
                      commits: repo.commitCount,
                      reviews: repo.reviewCount,
                      issues: repo.issueCount,
                      pullRequests: repo.pullRequestCount,
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}

/// Loading state for activity overview section
class ActivityOverviewSectionLoading extends StatelessWidget {
  const ActivityOverviewSectionLoading({super.key});

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.itemSpacing,
        vertical: spacing.itemSpacing,
      ),
      child: ShimmerScope(
        child: LayoutBuilder(
          builder:
              (final BuildContext context, final BoxConstraints constraints) {
                if (constraints.maxWidth < 600) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const ShimmerBone.text(width: 120),
                          spacing.itemGap,
                          ...List.generate(
                            2,
                            (final int index) => Padding(
                              padding: EdgeInsets.only(
                                bottom: spacing.itemSpacing,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const ShimmerBone.icon(size: 16),
                                  spacing.itemGap,
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        const ShimmerBone.text(),
                                        spacing.tightGap,
                                        const ShimmerBone.label(width: 80),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      spacing.sectionGap,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const ShimmerBone.text(width: 100),
                          SizedBox(height: spacing.compactSpacing * 2),
                          ShimmerBone.block(
                            height: 150,
                            radiusSize: RadiusSize.small,
                          ),
                        ],
                      ),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const ShimmerBone.text(width: 120),
                          spacing.itemGap,
                          ...List.generate(
                            2,
                            (final int index) => Padding(
                              padding: EdgeInsets.only(
                                bottom: spacing.itemSpacing,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const ShimmerBone.icon(size: 16),
                                  spacing.itemGap,
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        const ShimmerBone.text(),
                                        spacing.tightGap,
                                        const ShimmerBone.label(width: 80),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    spacing.itemGap,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const ShimmerBone.text(width: 100),
                          SizedBox(height: spacing.compactSpacing * 2),
                          ShimmerBone.block(
                            height: 150,
                            radiusSize: RadiusSize.small,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
        ),
      ),
    );
  }
}
