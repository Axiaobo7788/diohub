import 'package:diohub/common/issues/issue_list_card.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/contribution_info_chip.dart';
import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/common/misc/surface_shape_resolver.dart';
import 'package:diohub/common/pulls/simple_pull_card.dart';
import 'package:diohub/common/timeline/left_right_timeline_item.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/models/issues/issue_card_data_model.dart';
import 'package:diohub/models/pull_requests/pull_request_card_data_model.dart';
import 'package:diohub/models/repositories/repo_card_data_model.dart';
import 'package:diohub/style/surface_style_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Displays per-year contribution highlights in a timeline view
class ContributionHighlightsSection extends StatelessWidget {
  const ContributionHighlightsSection({
    required this.yearlyHighlights,
    required this.userName,
    super.key,
  });

  final List<YearlyContributionHighlights> yearlyHighlights;
  final String userName;

  @override
  Widget build(BuildContext context) {
    // Only show if we have multi-year data or interesting single-year data
    if (yearlyHighlights.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Highlights by year',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...yearlyHighlights.asMap().entries.map((entry) {
            return _YearHighlightItem(
              highlight: entry.value,
              isFirst: entry.key == 0,
              isLast: entry.key == yearlyHighlights.length - 1,
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _YearHighlightItem extends StatelessWidget {
  const _YearHighlightItem({
    required this.highlight,
    required this.isFirst,
    required this.isLast,
  });

  final YearlyContributionHighlights highlight;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LeftRightTimelineItem(
      isFirst: isFirst,
      isLast: isLast,
      leftChild: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Year
          Text(
            '${highlight.year}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          // Total contributions count
          Text(
            '${highlight.totalContributions}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            highlight.totalContributions == 1
                ? 'contribution'
                : 'contributions',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
      rightChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Date range
          Text(
            _formatDateRange(highlight.fromDate, highlight.toDate),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),

          // Show "No activity" for empty years
          if (highlight.totalContributions == 0 &&
              highlight.firstIssue == null &&
              highlight.firstPullRequest == null &&
              highlight.firstRepository == null &&
              highlight.popularIssue == null &&
              highlight.popularPullRequest == null &&
              highlight.mostReviewedRepository == null &&
              highlight.joinedGitHub == null &&
              highlight.restrictedContributionsCount == 0)
            Text(
              'No activity',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
            )
          else ...[
            // Per-year chips
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Commits with repo count
                if (highlight.totalCommitContributions > 0)
                  ContributionInfoChip(
                    icon: Octicons.git_commit,
                    count: highlight.totalCommitContributions,
                    label: highlight.totalRepositoriesWithContributedCommits > 0
                        ? 'in ${highlight.totalRepositoriesWithContributedCommits} ${highlight.totalRepositoriesWithContributedCommits == 1 ? 'repo' : 'repos'}'
                        : null,
                    color: const Color(0xFF2196F3),
                  ),

                // Issues with repo count
                if (highlight.totalIssueContributions > 0)
                  ContributionInfoChip(
                    icon: Octicons.issue_opened,
                    count: highlight.totalIssueContributions,
                    label: highlight.totalRepositoriesWithContributedIssues > 0
                        ? 'in ${highlight.totalRepositoriesWithContributedIssues} ${highlight.totalRepositoriesWithContributedIssues == 1 ? 'repo' : 'repos'}'
                        : null,
                    color: const Color(0xFF4CAF50),
                  ),

                // Pull requests with repo count
                if (highlight.totalPullRequestContributions > 0)
                  ContributionInfoChip(
                    icon: Octicons.git_pull_request,
                    count: highlight.totalPullRequestContributions,
                    label: highlight
                                .totalRepositoriesWithContributedPullRequests >
                            0
                        ? 'in ${highlight.totalRepositoriesWithContributedPullRequests} ${highlight.totalRepositoriesWithContributedPullRequests == 1 ? 'repo' : 'repos'}'
                        : null,
                    color: const Color(0xFF9C27B0),
                  ),

                // Reviews with repo count
                if (highlight.totalPullRequestReviewContributions > 0)
                  ContributionInfoChip(
                    icon: Octicons.code_review,
                    count: highlight.totalPullRequestReviewContributions,
                    label: highlight
                                .totalRepositoriesWithContributedPullRequestReviews >
                            0
                        ? 'reviews in ${highlight.totalRepositoriesWithContributedPullRequestReviews} ${highlight.totalRepositoriesWithContributedPullRequestReviews == 1 ? 'repo' : 'repos'}'
                        : 'reviews',
                    color: const Color(0xFFFF9800),
                  ),

                // Repository contributions
                if (highlight.totalRepositoryContributions > 0)
                  ContributionInfoChip(
                    icon: Octicons.repo,
                    count: highlight.totalRepositoryContributions,
                    label: highlight.totalRepositoryContributions == 1
                        ? 'repo created'
                        : 'repos created',
                    color: const Color(0xFF795548),
                  ),

                // Restricted contributions
                if (highlight.restrictedContributionsCount > 0)
                  ContributionInfoChip(
                    icon: Octicons.lock,
                    count: highlight.restrictedContributionsCount,
                    label: 'private',
                    color: theme.colorScheme.tertiary,
                  ),
              ],
            ),

            // Highlight cards (first/popular/joined)
            if (highlight.firstIssue != null ||
                highlight.firstPullRequest != null ||
                highlight.firstRepository != null ||
                highlight.popularIssue != null ||
                highlight.popularPullRequest != null ||
                highlight.mostReviewedRepository != null ||
                highlight.joinedGitHub != null) ...[
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  if (kDebugMode) {
                    debugPrint(
                        '[ContributionHighlights] Year ${highlight.year}:');
                    debugPrint(
                        '  - firstIssue: ${highlight.firstIssue?.title ?? "null"}');
                    debugPrint(
                        '  - firstPullRequest: ${highlight.firstPullRequest?.title ?? "null"}');
                    debugPrint(
                        '  - firstRepository: ${highlight.firstRepository?.title ?? "null"}');
                    debugPrint(
                        '  - popularIssue: ${highlight.popularIssue?.title ?? "null"} (commentCount: ${highlight.popularIssue?.commentCount ?? "null"})');
                    debugPrint(
                        '  - popularPullRequest: ${highlight.popularPullRequest?.title ?? "null"} (commentCount: ${highlight.popularPullRequest?.commentCount ?? "null"})');
                    debugPrint(
                        '  - joinedGitHub: ${highlight.joinedGitHub ?? "null"}');
                  }
                  return _buildHighlightCards(context, highlight);
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildHighlightCards(
    BuildContext context,
    YearlyContributionHighlights highlight,
  ) {
    final cards = <Widget>[];

    // First issue
    if (highlight.firstIssue != null) {
      if (kDebugMode) {
        debugPrint('[ContributionHighlights] Adding First issue card');
      }
      cards.add(_buildHighlightSection(
        context,
        title: 'First issue',
        item: highlight.firstIssue!,
      ));
    }

    // First pull request
    if (highlight.firstPullRequest != null) {
      if (kDebugMode) {
        debugPrint('[ContributionHighlights] Adding First pull request card');
      }
      cards.add(_buildHighlightSection(
        context,
        title: 'First pull request',
        item: highlight.firstPullRequest!,
      ));
    }

    // First repository
    if (highlight.firstRepository != null) {
      if (kDebugMode) {
        debugPrint('[ContributionHighlights] Adding First repository card');
      }
      cards.add(_buildHighlightSection(
        context,
        title: 'First repository',
        item: highlight.firstRepository!,
      ));
    }

    // Popular issue
    if (highlight.popularIssue != null) {
      if (kDebugMode) {
        debugPrint(
            '[ContributionHighlights] Adding Popular issue card: ${highlight.popularIssue!.title} (${highlight.popularIssue!.commentCount} comments)');
      }
      cards.add(_buildHighlightSection(
        context,
        title: 'Most commented issue',
        item: highlight.popularIssue!,
      ));
    } else if (kDebugMode) {
      debugPrint(
          '[ContributionHighlights] Popular issue is NULL - not adding card');
    }

    // Popular pull request
    if (highlight.popularPullRequest != null) {
      if (kDebugMode) {
        debugPrint(
            '[ContributionHighlights] Adding Popular pull request card: ${highlight.popularPullRequest!.title} (${highlight.popularPullRequest!.commentCount} comments)');
      }
      cards.add(_buildHighlightSection(
        context,
        title: 'Most commented pull request',
        item: highlight.popularPullRequest!,
      ));
    } else if (kDebugMode) {
      debugPrint(
          '[ContributionHighlights] Popular pull request is NULL - not adding card');
    }

    // Most reviewed repository
    if (highlight.mostReviewedRepository != null) {
      if (kDebugMode) {
        debugPrint(
            '[ContributionHighlights] Adding Most reviewed repository card');
      }
      cards.add(_buildHighlightSection(
        context,
        title: 'Most reviewed repository',
        item: highlight.mostReviewedRepository!,
      ));
    }

    // Joined GitHub
    if (highlight.joinedGitHub != null) {
      cards.add(_buildJoinedCard(context, highlight.joinedGitHub!));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: cards,
    );
  }

  Widget _buildHighlightSection(
    BuildContext context, {
    required String title,
    required ContributionHighlightItem item,
  }) {
    final theme = Theme.of(context);

    // Handle restricted items
    if (item.isRestricted) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                title,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: SurfaceShapeResolver.boxDecoration(
                context,
                size: BorderRadiusSize.small,
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(Octicons.lock,
                      size: 16, color: theme.colorScheme.tertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Private contribution',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Build the proper card based on type
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              title,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 4),
          _buildCard(item, context),
        ],
      ),
    );
  }

  Widget _buildCard(ContributionHighlightItem item, BuildContext context) {
    switch (item.type) {
      case ContributionHighlightType.issue:
        return BorderedContainer(
          size: BorderRadiusSize.small,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: IssueListCard(
              _convertToIssueCardData(item),
              showRepoName: true,
              showDescription: true,
            ),
          ),
        );
      case ContributionHighlightType.pullRequest:
        return BorderedContainer(
          size: BorderRadiusSize.small,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SimplePullCard(
              _convertToPullRequestCardData(item),
              showRepoName: true,
              showDescription: true,
            ),
          ),
        );
      case ContributionHighlightType.repository:
        return BorderedContainer(
          size: BorderRadiusSize.small,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: RepositoryCard(
              _convertToRepoCardData(item),
              reviewCount: item.commentCount,
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  IssueCardDataModel _convertToIssueCardData(ContributionHighlightItem item) {
    // Use GraphQL factory method if available
    if (item.graphQLIssue != null) {
      return IssueCardDataModel.fromGraphQLTimeline(item.graphQLIssue);
    }
    // Fallback to manual construction
    return IssueCardDataModel(
      title: item.title,
      number: item.number ?? 0,
      state: item.state ?? 'OPEN',
      url: item.url,
      repositoryOwner: item.repositoryOwner,
      repositoryName: item.repositoryName,
      repositoryUrl: item.repositoryUrl,
      body: item.body,
      bodyHtml: null,
      commentCount: item.commentCount ?? 0,
      createdAt: item.createdAt,
      updatedAt: null,
      closedAt: item.state == 'CLOSED' ? item.createdAt : null,
      author: null,
      labels: null,
      assignees: null,
      repositoryData: RepoCardDataModel(
        name: item.repositoryName,
        url: item.repositoryUrl,
        description: null,
        language: null,
      ),
    );
  }

  PullRequestCardDataModel _convertToPullRequestCardData(
      ContributionHighlightItem item) {
    // Use GraphQL factory method if available
    if (item.graphQLPullRequest != null) {
      return PullRequestCardDataModel.fromGraphQLTimeline(
        item.graphQLPullRequest,
      );
    }
    // Fallback to manual construction
    return PullRequestCardDataModel(
      title: item.title,
      number: item.number ?? 0,
      state: item.state ?? 'OPEN',
      url: item.url,
      repositoryOwner: item.repositoryOwner,
      repositoryName: item.repositoryName,
      repositoryUrl: item.repositoryUrl,
      body: item.body,
      bodyHtml: null,
      merged: item.mergedAt != null,
      mergedAt: item.mergedAt,
      createdAt: item.createdAt,
      updatedAt: null,
      closedAt: item.state == 'CLOSED' ? item.createdAt : null,
      author: null,
      labels: null,
      assignees: null,
      repositoryData: RepoCardDataModel(
        name: item.repositoryName,
        url: item.repositoryUrl,
        description: null,
        language: null,
      ),
    );
  }

  RepoCardDataModel _convertToRepoCardData(ContributionHighlightItem item) {
    // Use GraphQL factory method if available
    if (item.graphQLRepository != null) {
      return RepoCardDataModel.fromGraphQL(item.graphQLRepository);
    }
    // Fallback to manual construction
    return RepoCardDataModel(
      name: item.repositoryName,
      url: item.repositoryUrl,
      description: null,
      language: null,
      stargazersCount: item.stargazerCount ?? 0,
      private: item.isPrivate,
      fork: false,
    );
  }

  Widget _buildJoinedCard(BuildContext context, DateTime joinedDate) {
    final theme = Theme.of(context);
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: SurfaceShapeResolver.boxDecoration(
          context,
          size: BorderRadiusSize.small,
          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Octicons.heart,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Joined GitHub',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${monthNames[joinedDate.month - 1]} ${joinedDate.day}, ${joinedDate.year}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateRange(DateTime from, DateTime to) {
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    if (from.year == to.year && from.month == to.month) {
      return '${monthNames[from.month - 1]} ${from.day}-${to.day}';
    } else if (from.year == to.year) {
      return '${monthNames[from.month - 1]} ${from.day} - ${monthNames[to.month - 1]} ${to.day}';
    } else {
      return '${monthNames[from.month - 1]} ${from.day}, ${from.year} - ${monthNames[to.month - 1]} ${to.day}, ${to.year}';
    }
  }
}
