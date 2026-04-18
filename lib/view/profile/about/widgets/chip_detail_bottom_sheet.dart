import 'package:diohub/common/bottom_sheet/paginated_list_sheet.dart';
import 'package:diohub/common/cards/issue_pull_card.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/common/utils/contribution_utils.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';

import 'package:diohub/models/contributions/chip_detail_models.dart';
import 'package:diohub_models/models/contributions/contribution_chip_type.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/providers/users/chip_details_provider.dart';
import 'package:diohub/view/profile/about/widgets/contribution_breakdown_row.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheet for displaying chip-specific contribution details.
/// Callers must pass [scrollController] from [AppSheet.scrollable] and provide
/// a header (e.g. [AppSheetHeader.text]([titleForChipType])).
class ChipDetailBottomSheet extends ConsumerStatefulWidget {
  const ChipDetailBottomSheet({
    required this.chipType,
    required this.queryKey,
    required this.contributionResult,
    required this.scrollController,
    super.key,
  });

  final ContributionChipType chipType;
  final ContributionQueryKey queryKey;
  final ContributionCollectionResult contributionResult;
  final ScrollController scrollController;

  /// Title string for use in the sheet header.
  static String titleForChipType(ContributionChipType chipType) {
    switch (chipType) {
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
  ConsumerState<ChipDetailBottomSheet> createState() =>
      _ChipDetailBottomSheetState();
}

class _ChipDetailBottomSheetState extends ConsumerState<ChipDetailBottomSheet> {
  /// Gets border color based on chip type and action that occurred
  /// Uses occurredAt to determine the action, not current state
  /// Matches the color scheme used in ActivityTimelineItem
  Color? _getBorderColor({
    final IssueCardData? issueModel,
    final PullCardData? prModel,
    final DateTime? occurredAt,
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
        if (issueModel != null) {
          return issueModel.issueState == IssueState.CLOSED
              ? Colors.red
              : Colors.green;
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
        if (prModel != null) {
          if (prModel.merged) {
            return Colors.deepPurple;
          } else if (prModel.pullRequestState == PullRequestState.CLOSED) {
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

  @override
  Widget build(final BuildContext context) {
    return _buildContent(widget.scrollController);
  }

  Widget _buildContent(final ScrollController scrollController) {
    // Handle commits separately (no API call needed, use existing data)
    if (widget.chipType == ContributionChipType.commits) {
      return _buildCommitsContent(scrollController);
    }

    // Handle private contributions (no details available)
    if (widget.chipType == ContributionChipType.private) {
      return _buildPrivateContent();
    }

    final ChipDetailsKey detailsKey = ChipDetailsKey(
      chipType: widget.chipType,
      queryKey: widget.queryKey,
    );
    return _buildPaginatedContent(detailsKey, scrollController);
  }

  Widget _buildCommitsContent(final ScrollController scrollController) {
    return ProviderScope(
      overrides: [
        contributionResultForCommitDetailsProvider.overrideWithValue(
          widget.contributionResult,
        ),
      ],
      child: Consumer(
        builder: (final BuildContext context, final WidgetRef ref, _) {
          final asyncDetails = ref.watch(commitChipDetailsProvider);
          return asyncDetails.when(
            loading: () => const Center(child: LoadingIndicator()),
            error: (final Object err, _) => _buildError(err.toString()),
            data: (final CommitChipDetails details) {
              if (details.repositories.isEmpty) return _buildEmpty();
              return ListView.separated(
                controller: scrollController,
                padding: context.spacing.pagePadding,
                itemCount: details.repositories.length,
                separatorBuilder:
                    (final BuildContext context, final int index) =>
                        context.spacing.contentGap,
                itemBuilder: (final BuildContext context, final int index) {
                  final CommitRepoItem repoItem = details.repositories[index];
                  // No cast needed: repoItem.repository is already RepoCardData
                  final RepoCardData repoData = repoItem.repository;

                  return BorderedContainer(
                    borderColor: _getBorderColor(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        RepositoryCard(repoData),
                        if (repoItem.commitCount > 0)
                          ContributionBreakdownRow(
                            commits: repoItem.commitCount,
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPrivateContent() => Center(
        child: Padding(
          padding: context.spacing.spaciousPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              context.spacing.sectionGap,
              Text(
                'Private Contributions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              context.spacing.itemGap,
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

  Widget _buildPaginatedContent(
    final ChipDetailsKey detailsKey,
    final ScrollController scrollController,
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
    final ChipDetailsKey detailsKey,
    final ScrollController scrollController,
  ) {
    return PaginatedListSheetBody<IssueChipItem>(
      scrollController: scrollController,
      createController: () =>
          ref.read(issueChipDetailsControllerProvider(detailsKey))(),
      itemBuilder: (final BuildContext context, final WidgetRef ref,
          final IssueChipItem item, final int index, final _) {
        // No cast needed: item.issue is already Fragment$issueCardFields (IssueCardData)
        final IssueCardData issueData = item.issue;
        return BorderedContainer(
          borderColor: _getBorderColor(
            issueModel: issueData,
            occurredAt: item.occurredAt,
          ),
          child: Padding(
            padding: context.spacing.contentPadding,
            child: IssuePullCard.fromIssue(issueData),
          ),
        );
      },
      emptyBuilder: (final BuildContext context) => _buildEmpty(),
    );
  }

  Widget _buildPullRequestsContent(
    final ChipDetailsKey detailsKey,
    final ScrollController scrollController,
  ) {
    return PaginatedListSheetBody<PullRequestChipItem>(
      scrollController: scrollController,
      createController: () =>
          ref.read(pullRequestChipDetailsControllerProvider(detailsKey))(),
      itemBuilder: (final BuildContext context, final WidgetRef ref,
          final PullRequestChipItem item, final int index, final _) {
        // No cast needed: item.pullRequest is already Fragment$pullCardFields (PullCardData)
        final PullCardData prData = item.pullRequest;
        return BorderedContainer(
          borderColor: _getBorderColor(prModel: prData),
          child: IssuePullCard.fromPullRequest(prData),
        );
      },
      emptyBuilder: (final BuildContext context) => _buildEmpty(),
    );
  }

  Widget _buildReviewsContent(
    final ChipDetailsKey detailsKey,
    final ScrollController scrollController,
  ) {
    return PaginatedListSheetBody<ReviewChipItem>(
      scrollController: scrollController,
      createController: () =>
          ref.read(reviewChipDetailsControllerProvider(detailsKey))(),
      itemBuilder: (final BuildContext context, final WidgetRef ref,
          final ReviewChipItem item, final int index, final _) {
        // No cast needed: item.pullRequest is already Fragment$pullCardFields (PullCardData)
        final PullCardData prData = item.pullRequest;
        return BorderedContainer(
          borderColor: _getBorderColor(
            prModel: prData,
            occurredAt: item.occurredAt,
          ),
          child: IssuePullCard.fromPullRequest(prData),
        );
      },
      emptyBuilder: (final BuildContext context) => _buildEmpty(),
    );
  }

  Widget _buildCreatedReposContent(
    final ChipDetailsKey detailsKey,
    final ScrollController scrollController,
  ) {
    return PaginatedListSheetBody<CreatedRepoChipItem>(
      scrollController: scrollController,
      createController: () =>
          ref.read(createdRepoChipDetailsControllerProvider(detailsKey))(),
      itemBuilder: (final BuildContext context, final WidgetRef ref,
          final CreatedRepoChipItem item, final int index, final _) {
        // Cast needed: item.repository is Fragment$repositoryFields but RepositoryCard expects RepoCardData.
        // The fragments have different fields, but at runtime the minimal repositoryFields works for display.
        // TODO(architecture): Align GraphQL fragments or create adapter for proper type safety.
        final RepoCardData repoData = item.repository as RepoCardData;
        return BorderedContainer(
          borderColor: _getBorderColor(),
          child: RepositoryCard(repoData),
        );
      },
      emptyBuilder: (final BuildContext context) => _buildEmpty(),
    );
  }

  Widget _buildEmpty() => Center(
        child: Padding(
          padding: context.spacing.spaciousPadding,
          child: Text(
            'No items found',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );

  Widget _buildError(final String error) => Center(
        child: Padding(
          padding: context.spacing.spaciousPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              context.spacing.sectionGap,
              Text(
                'Error loading data',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              context.spacing.itemGap,
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
