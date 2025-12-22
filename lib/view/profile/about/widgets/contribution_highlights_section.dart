import 'package:diohub/common/issues/issue_list_card.dart';
import 'package:diohub/common/misc/contribution_info_chip.dart';
import 'package:diohub/common/misc/surface_shape_resolver.dart';
import 'package:diohub/common/pulls/pull_list_card.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/models/issues/issue_card_data_model.dart';
import 'package:diohub/models/issues/issue_model.dart';
import 'package:diohub/models/pull_requests/pull_request_model.dart';
import 'package:diohub/models/repositories/repo_card_data_model.dart';
import 'package:diohub/style/surface_style_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Displays per-year contribution highlights
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
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: theme.surfaceStyle.borderRadiusMedium(),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                  isLast: entry.key == yearlyHighlights.length - 1,
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

class _YearHighlightItem extends StatelessWidget {
  const _YearHighlightItem({
    required this.highlight,
    required this.isLast,
  });

  final YearlyContributionHighlights highlight;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Year header
          Row(
            children: [
              Text(
                '${highlight.year}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDateRange(highlight.fromDate, highlight.toDate),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Per-year chips
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Restricted contributions
              if (highlight.restrictedContributionsCount > 0)
                ContributionInfoChip(
                  icon: Octicons.lock,
                  count: highlight.restrictedContributionsCount,
                  repoCount: null,
                  color: theme.colorScheme.tertiary,
                ),

              // Repo counts
              if (highlight.totalRepositoriesWithContributedCommits > 0)
                ContributionInfoChip(
                  icon: Octicons.git_commit,
                  count: highlight.totalRepositoriesWithContributedCommits,
                  repoCount: null,
                  color: const Color(0xFF2196F3),
                ),

              if (highlight.totalRepositoriesWithContributedIssues > 0)
                ContributionInfoChip(
                  icon: Octicons.issue_opened,
                  count: highlight.totalRepositoriesWithContributedIssues,
                  repoCount: null,
                  color: const Color(0xFF4CAF50),
                ),

              if (highlight.totalRepositoriesWithContributedPullRequests > 0)
                ContributionInfoChip(
                  icon: Octicons.git_pull_request,
                  count: highlight.totalRepositoriesWithContributedPullRequests,
                  repoCount: null,
                  color: const Color(0xFF9C27B0),
                ),

              // Month count
              if (highlight.calendarMonths.isNotEmpty)
                ContributionInfoChip(
                  icon: Octicons.calendar,
                  count: highlight.calendarMonths.length,
                  repoCount: null,
                  color: theme.colorScheme.secondary,
                ),
            ],
          ),

          // Highlight cards (first/popular/joined)
          if (highlight.firstIssue != null ||
              highlight.firstPullRequest != null ||
              highlight.firstRepository != null ||
              highlight.popularIssue != null ||
              highlight.popularPullRequest != null ||
              highlight.joinedGitHub != null) ...[
            const SizedBox(height: 12),
            _buildHighlightCards(context, highlight),
          ],

          // Divider (except for last item)
          if (!isLast)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
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
      cards.add(_buildHighlightSection(
        context,
        title: 'First issue',
        item: highlight.firstIssue!,
      ));
    }

    // First pull request
    if (highlight.firstPullRequest != null) {
      cards.add(_buildHighlightSection(
        context,
        title: 'First pull request',
        item: highlight.firstPullRequest!,
      ));
    }

    // First repository
    if (highlight.firstRepository != null) {
      cards.add(_buildHighlightSection(
        context,
        title: 'First repository',
        item: highlight.firstRepository!,
      ));
    }

    // Popular issue
    if (highlight.popularIssue != null) {
      cards.add(_buildHighlightSection(
        context,
        title: 'Most commented issue',
        item: highlight.popularIssue!,
      ));
    }

    // Popular pull request
    if (highlight.popularPullRequest != null) {
      cards.add(_buildHighlightSection(
        context,
        title: 'Most commented pull request',
        item: highlight.popularPullRequest!,
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
        return IssueListCard(
          _convertToIssueCardData(item),
          showRepoName: true,
          showDescription: false,
        );
      case ContributionHighlightType.pullRequest:
        return PullListCard(
          _convertToPullRequestModel(item),
          showRepoName: true,
        );
      case ContributionHighlightType.repository:
        // For repositories, use a simple card (could use RepositoryCard later)
        return _buildRepositoryCard(item, context);
      default:
        return const SizedBox.shrink();
    }
  }

  IssueCardDataModel _convertToIssueCardData(ContributionHighlightItem item) {
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

  PullRequestModel _convertToPullRequestModel(ContributionHighlightItem item) {
    return PullRequestModel(
      title: item.title,
      number: item.number,
      state: item.state == 'OPEN' ? IssueState.OPEN : IssueState.CLOSED,
      url: item.url,
      body: item.body,
      createdAt: item.createdAt,
      mergedAt: item.mergedAt,
      closedAt: item.state == 'CLOSED' ? item.createdAt : null,
      comments: item.commentCount,
    );
  }

  Widget _buildRepositoryCard(
      ContributionHighlightItem item, BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: SurfaceShapeResolver.boxDecoration(
        context,
        size: BorderRadiusSize.small,
        color: const Color(0xFF2196F3).withOpacity(0.05),
        border: Border.all(
          color: const Color(0xFF2196F3).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Octicons.repo,
                size: 16,
                color: const Color(0xFF2196F3),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.repositoryFullName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (item.stargazerCount != null && item.stargazerCount! > 0) ...[
                Icon(
                  Octicons.star,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${item.stargazerCount}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (item.isPrivate)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Octicons.lock,
                    size: 14,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
            ],
          ),
        ],
      ),
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
