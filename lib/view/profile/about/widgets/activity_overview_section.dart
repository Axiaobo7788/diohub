import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/charts/chart_carousel_widget.dart';
import 'package:diohub/common/charts/contribution_calendar_widget.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/common/misc/shimmer_widget.dart';
import 'package:diohub/models/repositories/repo_card_data_model.dart';
import 'package:diohub/style/surface_style_theme.dart';
import 'package:flutter/material.dart';

import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';

/// Data for a repository in the "Contributed to" section
/// Stores the full GraphQL repository object to avoid data loss
class ContributedRepository {
  const ContributedRepository({
    required this.graphQLRepository,
    required this.contributionCount,
    this.commitCount,
    this.reviewCount,
    this.issueCount,
    this.pullRequestCount,
  });

  /// Full GraphQL repository object (uses repositoryFields fragment)
  final GrepositoryFields graphQLRepository;

  /// Total contribution count (sum of all contribution types)
  final int contributionCount;

  /// Number of commits contributed
  final int? commitCount;

  /// Number of PR reviews contributed
  final int? reviewCount;

  /// Number of issues contributed
  final int? issueCount;

  /// Number of pull requests contributed
  final int? pullRequestCount;

  // Convenience getters for commonly used fields
  String get name => graphQLRepository.name;
  String get owner => graphQLRepository.owner.login;
  String get url => graphQLRepository.url.toString();
  String? get description => graphQLRepository.description;
  int? get stargazersCount => graphQLRepository.stargazerCount;
  bool? get isPrivate => graphQLRepository.isPrivate;
  bool? get isFork => graphQLRepository.isFork;

  /// Get primary language name
  String? get language => graphQLRepository.primaryLanguage?.name;

  /// Get primary language color
  String? get languageColor => graphQLRepository.primaryLanguage?.color;
}

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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // On smaller screens, stack vertically
          if (constraints.maxWidth < 600) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContributedTo(context),
                const SizedBox(height: 16),
                _buildCodeReviewChart(context),
              ],
            );
          }
          // On larger screens, side by side
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildContributedTo(context)),
              const SizedBox(width: 16),
              Expanded(child: _buildCodeReviewChart(context)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContributedTo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (repositories.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contributed to',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No contributions yet',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final hasMoreThanTwo = repositories.length > 2;
    final displayRepos = repositories.take(2).toList();
    final remainingCount = repositories.length - displayRepos.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contributed to',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        ...displayRepos.map((repo) {
          final repoCardData = RepoCardDataModel.fromGraphQL(repo.graphQLRepository);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: BorderedContainer(
              // borderColor: Colors.blue,
              borderSide: BorderSideType.bottom,
              // size: BorderRadiusSize.small,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: RepositoryCard(
                  repoCardData,
                  contributionCount: repo.commitCount,
                  reviewCount: repo.reviewCount,
                  issueCount: repo.issueCount,
                  pullRequestCount: repo.pullRequestCount,
                ),
              ),
            ),
          );
        }),
        if (hasMoreThanTwo)
          InkWell(
            onTap: () => _showAllRepositoriesSheet(context),
            borderRadius: Theme.of(context)
                .surfaceStyle
                .borderRadius(size: BorderRadiusSize.small),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Show ${remainingCount} more ${remainingCount == 1 ? 'repository' : 'repositories'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.expand_more,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCodeReviewChart(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Code review',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        ChartCarousel(
          repositories: repositories,
          commits: commits,
          issues: issues,
          pullRequests: pullRequests,
          reviews: reviews,
          weeks: weeks,
          height: 150,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  void _showAllRepositoriesSheet(BuildContext context) {
    showScrollableBottomSheet(
      context,
      headerBuilder: (context, setState) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Contributed Repositories',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
      scrollableBodyBuilder: (context, setState, scrollController) =>
          ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: repositories.length,
        itemBuilder: (context, index) {
          final repo = repositories[index];
          final repoCardData = RepoCardDataModel.fromGraphQL(repo.graphQLRepository);
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < repositories.length - 1 ? 12 : 0,
            ),
            child: BorderedContainer(
              borderColor:
                  Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
              borderSide: BorderSideType.bottom,
              size: BorderRadiusSize.small,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: RepositoryCard(
                  repoCardData,
                  contributionCount: repo.commitCount,
                  reviewCount: repo.reviewCount,
                  issueCount: repo.issueCount,
                  pullRequestCount: repo.pullRequestCount,
                ),
              ),
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
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contributed to section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerWidget.container(
                      height: 16,
                      width: 120,
                      borderRadius: Theme.of(context)
                          .surfaceStyle
                          .borderRadius(size: BorderRadiusSize.small),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(
                        4,
                        (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  ShimmerWidget.container(
                                    height: 14,
                                    width: 14,
                                    borderRadius: Theme.of(context)
                                        .surfaceStyle
                                        .borderRadius(
                                            size: BorderRadiusSize.small,),
                                  ),
                                  const SizedBox(width: 6),
                                  ShimmerWidget.container(
                                    height: 14,
                                    width: 150,
                                    borderRadius: Theme.of(context)
                                        .surfaceStyle
                                        .borderRadius(
                                            size: BorderRadiusSize.small,),
                                  ),
                                ],
                              ),
                            ),),
                  ],
                ),
                const SizedBox(height: 16),
                // Radar chart shimmer
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerWidget.container(
                      height: 16,
                      width: 100,
                      borderRadius: Theme.of(context)
                          .surfaceStyle
                          .borderRadius(size: BorderRadiusSize.small),
                    ),
                    const SizedBox(height: 12),
                    ShimmerWidget.container(
                      height: 150,
                      borderRadius: Theme.of(context)
                          .surfaceStyle
                          .borderRadius(size: BorderRadiusSize.small),
                    ),
                  ],
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerWidget.container(
                      height: 16,
                      width: 120,
                      borderRadius:
                          Theme.of(context).surfaceStyle.borderRadiusSmall(),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(
                        4,
                        (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  ShimmerWidget.container(
                                    height: 14,
                                    width: 14,
                                    borderRadius: Theme.of(context)
                                        .surfaceStyle
                                        .borderRadius(
                                            size: BorderRadiusSize.small,),
                                  ),
                                  const SizedBox(width: 6),
                                  ShimmerWidget.container(
                                    height: 14,
                                    width: 150,
                                    borderRadius: Theme.of(context)
                                        .surfaceStyle
                                        .borderRadius(
                                            size: BorderRadiusSize.small,),
                                  ),
                                ],
                              ),
                            ),),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerWidget.container(
                      height: 16,
                      width: 100,
                      borderRadius: Theme.of(context)
                          .surfaceStyle
                          .borderRadius(size: BorderRadiusSize.small),
                    ),
                    const SizedBox(height: 12),
                    ShimmerWidget.container(
                      height: 150,
                      borderRadius: Theme.of(context)
                          .surfaceStyle
                          .borderRadius(size: BorderRadiusSize.small),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
}
