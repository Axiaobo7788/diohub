import 'package:diohub/common/issues/issue_list_card.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/common/pulls/pull_list_card.dart';
import 'package:diohub/common/pulls/simple_pull_card.dart';
import 'package:diohub/common/utils/contribution_utils.dart';
import 'package:diohub/models/contributions/chip_detail_models.dart';
import 'package:diohub/models/contributions/contribution_chip_type.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/models/issues/issue_card_data_model.dart';
import 'package:diohub/models/pull_requests/pull_request_card_data_model.dart';
import 'package:diohub/models/repositories/repo_card_data_model.dart';
import 'package:diohub/providers/users/chip_details_provider.dart';
import 'package:diohub/services/users/chip_details_service.dart';
import 'package:diohub/style/surface_style_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheet for displaying chip-specific contribution details
class ChipDetailBottomSheet extends ConsumerStatefulWidget {
  const ChipDetailBottomSheet({
    required this.chipType,
    required this.queryKey,
    required this.contributionResult,
    super.key,
  });

  final ContributionChipType chipType;
  final ContributionQueryKey queryKey;
  final ContributionCollectionResult contributionResult;

  @override
  ConsumerState<ChipDetailBottomSheet> createState() =>
      _ChipDetailBottomSheetState();
}

class _ChipDetailBottomSheetState extends ConsumerState<ChipDetailBottomSheet> {
  String? _cursor;

  /// Gets border color based on chip type and action that occurred
  /// Uses occurredAt to determine the action, not current state
  /// Matches the color scheme used in ActivityTimelineItem
  Color? _getBorderColor({
    IssueCardDataModel? issueModel,
    PullRequestCardDataModel? prModel,
    DateTime? occurredAt,
  }) {
    switch (widget.chipType) {
      case ContributionChipType.commits:
        return const Color(0xFF2196F3); // Blue
      case ContributionChipType.issues:
        if (issueModel != null && occurredAt != null) {
          return getIssueActionColor(
            issue: issueModel,
            occurredAt: occurredAt,
          );
        }
        // Fallback to current state if occurredAt not available
        if (issueModel != null) {
          return issueModel.state == 'CLOSED' ? Colors.red : Colors.green;
        }
        return Colors.green;
      case ContributionChipType.pullRequests:
      case ContributionChipType.reviews:
        if (prModel != null && occurredAt != null) {
          return getPullRequestActionColor(
            pr: prModel,
            occurredAt: occurredAt,
          );
        }
        // Fallback to current state if occurredAt not available
        if (prModel != null) {
          if (prModel.merged) {
            return Colors.deepPurple;
          } else if (prModel.state == 'CLOSED') {
            return Colors.red;
          } else {
            return Colors.green;
          }
        }
        return Colors.green;
      case ContributionChipType.createdRepos:
        return const Color(0xFF009688); // Teal
      case ContributionChipType.private:
        return null; // No specific color for private
    }
  }

  String _getTitle() {
    switch (widget.chipType) {
      case ContributionChipType.commits:
        return 'Commits';
      case ContributionChipType.pullRequests:
        return 'Pull Requests';
      case ContributionChipType.issues:
        return 'Issues';
      case ContributionChipType.reviews:
        return 'Reviews';
      case ContributionChipType.createdRepos:
        return 'Created Repositories';
      case ContributionChipType.private:
        return 'Private Contributions';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _getTitle(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            Expanded(
              child: _buildContent(scrollController),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(ScrollController scrollController) {
    // Handle commits separately (no API call needed, use existing data)
    if (widget.chipType == ContributionChipType.commits) {
      return _buildCommitsContent(scrollController);
    }

    // Handle private contributions (no details available)
    if (widget.chipType == ContributionChipType.private) {
      return _buildPrivateContent();
    }

    // For other types, use providers
    final detailsKey = ChipDetailsKey(
      chipType: widget.chipType,
      queryKey: widget.queryKey,
      cursor: _cursor,
    );

    return _buildPaginatedContent(detailsKey, scrollController);
  }

  Widget _buildCommitsContent(ScrollController scrollController) {
    // Use existing data from contributionResult
    final commitDetails = ChipDetailsService.fetchCommitContributions(
      contributionResult: widget.contributionResult,
    );

    return FutureBuilder<CommitChipDetails>(
      future: commitDetails,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LoadingIndicator());
        }

        if (snapshot.hasError) {
          return _buildError(snapshot.error.toString());
        }

        final details = snapshot.data;
        if (details == null || details.repositories.isEmpty) {
          return _buildEmpty();
        }

        return ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: details.repositories.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final repoItem = details.repositories[index];
            final repoModel = RepoCardDataModel.fromGraphQL(
              repoItem.repository,
            );

            return BorderedContainer(
              size: BorderRadiusSize.medium,
              borderColor: _getBorderColor(),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: RepositoryCard(
                  repoModel,
                  contributionCount: repoItem.commitCount,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPrivateContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Private Contributions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Details for private contributions are not available.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginatedContent(
    ChipDetailsKey detailsKey,
    ScrollController scrollController,
  ) {
    switch (widget.chipType) {
      case ContributionChipType.issues:
        return _buildIssuesContent(detailsKey, scrollController);
      case ContributionChipType.pullRequests:
        return _buildPullRequestsContent(detailsKey, scrollController);
      case ContributionChipType.reviews:
        return _buildReviewsContent(detailsKey, scrollController);
      case ContributionChipType.createdRepos:
        return _buildCreatedReposContent(detailsKey, scrollController);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIssuesContent(
    ChipDetailsKey detailsKey,
    ScrollController scrollController,
  ) {
    final issuesAsync = ref.watch(issueChipDetailsProvider(detailsKey));

    return issuesAsync.when(
      data: (details) {
        if (details.issues.isEmpty) {
          return _buildEmpty();
        }

        return ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: details.issues.length + (details.hasNextPage ? 1 : 0),
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == details.issues.length) {
              return _buildLoadMoreButton(() {
                setState(() {
                  _cursor = details.endCursor;
                });
              });
            }

            final issueItem = details.issues[index];
            final issueModel = IssueCardDataModel.fromGraphQLTimeline(
              issueItem.issue,
            );

            return BorderedContainer(
              size: BorderRadiusSize.medium,
              borderColor: _getBorderColor(
                issueModel: issueModel,
                occurredAt: issueItem.occurredAt,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: IssueListCard(
                  issueModel,
                  showRepoName: true,
                  showDescription: true,
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, stack) => _buildError(error.toString()),
    );
  }

  Widget _buildPullRequestsContent(
    ChipDetailsKey detailsKey,
    ScrollController scrollController,
  ) {
    final prsAsync = ref.watch(pullRequestChipDetailsProvider(detailsKey));

    return prsAsync.when(
      data: (details) {
        if (details.pullRequests.isEmpty) {
          return _buildEmpty();
        }

        return ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          itemCount:
              details.pullRequests.length + (details.hasNextPage ? 1 : 0),
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == details.pullRequests.length) {
              return _buildLoadMoreButton(() {
                setState(() {
                  _cursor = details.endCursor;
                });
              });
            }

            final prItem = details.pullRequests[index];
            final prModel = PullRequestCardDataModel.fromGraphQLTimeline(
              prItem.pullRequest,
            );

            return BorderedContainer(
              size: BorderRadiusSize.medium,
              borderColor: _getBorderColor(prModel: prModel),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SimplePullCard(prModel),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, stack) => _buildError(error.toString()),
    );
  }

  Widget _buildReviewsContent(
    ChipDetailsKey detailsKey,
    ScrollController scrollController,
  ) {
    final reviewsAsync = ref.watch(reviewChipDetailsProvider(detailsKey));

    return reviewsAsync.when(
      data: (details) {
        if (details.reviews.isEmpty) {
          return _buildEmpty();
        }

        return ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: details.reviews.length + (details.hasNextPage ? 1 : 0),
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == details.reviews.length) {
              return _buildLoadMoreButton(() {
                setState(() {
                  _cursor = details.endCursor;
                });
              });
            }

            final reviewItem = details.reviews[index];
            final prModel = PullRequestCardDataModel.fromGraphQLTimeline(
              reviewItem.pullRequest,
            );

            return BorderedContainer(
              size: BorderRadiusSize.medium,
              borderColor: _getBorderColor(
                prModel: prModel,
                occurredAt: reviewItem.occurredAt,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: PullListCard(prModel.toPullRequestModel()),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, stack) => _buildError(error.toString()),
    );
  }

  Widget _buildCreatedReposContent(
    ChipDetailsKey detailsKey,
    ScrollController scrollController,
  ) {
    final reposAsync = ref.watch(createdRepoChipDetailsProvider(detailsKey));

    return reposAsync.when(
      data: (details) {
        if (details.repositories.isEmpty) {
          return _buildEmpty();
        }

        return ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          itemCount:
              details.repositories.length + (details.hasNextPage ? 1 : 0),
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == details.repositories.length) {
              return _buildLoadMoreButton(() {
                setState(() {
                  _cursor = details.endCursor;
                });
              });
            }

            final repoItem = details.repositories[index];
            final repoModel = RepoCardDataModel.fromGraphQL(
              repoItem.repository,
            );

            return BorderedContainer(
              size: BorderRadiusSize.medium,
              borderColor: _getBorderColor(),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: RepositoryCard(repoModel),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, stack) => _buildError(error.toString()),
    );
  }

  Widget _buildLoadMoreButton(VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.refresh),
          label: const Text('Load More'),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No items found',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading data',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
