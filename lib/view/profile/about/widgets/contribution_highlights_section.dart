import 'package:diohub/common/cards/issue_pull_card.dart';
import 'package:diohub/common/cards/state_chip.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/contribution_info_chip.dart';
import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/common/timeline/left_right_timeline_item.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';

import 'package:diohub_models/models/contributions/contribution_chip_type.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/navigable.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub_models/models/visual_state.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/view/profile/about/widgets/contribution_breakdown_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Displays per-year contribution highlights in a timeline view
class ContributionHighlightsSection extends StatelessWidget {
  const ContributionHighlightsSection({
    required this.yearlyHighlights,
    required this.userName,
    this.onChipTap,
    super.key,
  });

  final List<YearlyContributionHighlights> yearlyHighlights;
  final String userName;
  final void Function(ContributionChipType chipType)? onChipTap;

  @override
  Widget build(final BuildContext context) {
    // Only show if we have multi-year data or interesting single-year data
    if (yearlyHighlights.isEmpty) {
      return const SizedBox.shrink();
    }

    final AppSpacing spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.itemSpacing,
        vertical: spacing.itemSpacing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ...yearlyHighlights.asMap().entries.map(
                (final MapEntry<int, YearlyContributionHighlights> entry) =>
                    _YearHighlightItem(
                  highlight: entry.value,
                  isFirst: entry.key == 0,
                  isLast: entry.key == yearlyHighlights.length - 1,
                  onChipTap: onChipTap,
                ),
              ),
        ],
      ),
    );
  }
}

class _YearHighlightItem extends ConsumerWidget {
  const _YearHighlightItem({
    required this.highlight,
    required this.isFirst,
    required this.isLast,
    this.onChipTap,
  });

  final YearlyContributionHighlights highlight;
  final bool isFirst;
  final bool isLast;
  final void Function(ContributionChipType chipType)? onChipTap;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppSpacing spacing = context.spacing;

    return LeftRightTimelineItem(
      isFirst: isFirst,
      isLast: isLast,
      leftChild: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Year
          Text(
            '${highlight.year}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          spacing.tightGap,
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
              color: theme.colorScheme.onSurfaceVariant.secondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
      rightChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Date range
          Text(
            _formatDateRange(highlight.fromDate, highlight.toDate),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.secondary,
            ),
          ),
          SizedBox(height: spacing.compactSpacing * 2),

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
                color: theme.colorScheme.onSurfaceVariant.muted,
                fontStyle: FontStyle.italic,
              ),
            )
          else ...<Widget>[
            // Per-year chips
            Wrap(
              spacing: spacing.compactSpacing * 2,
              runSpacing: spacing.itemSpacing,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                if (highlight.totalCommitContributions > 0)
                  ContributionInfoChip.commits(
                    count: highlight.totalCommitContributions,
                    repoCount:
                        highlight.totalRepositoriesWithContributedCommits,
                    onTap: onChipTap != null
                        ? () => onChipTap!(ContributionChipType.commits)
                        : null,
                  ),
                if (highlight.totalIssueContributions > 0)
                  ContributionInfoChip.issues(
                    count: highlight.totalIssueContributions,
                    repoCount: highlight.totalRepositoriesWithContributedIssues,
                    onTap: onChipTap != null
                        ? () => onChipTap!(ContributionChipType.issues)
                        : null,
                  ),
                if (highlight.totalPullRequestContributions > 0)
                  ContributionInfoChip.pullRequests(
                    count: highlight.totalPullRequestContributions,
                    repoCount:
                        highlight.totalRepositoriesWithContributedPullRequests,
                    onTap: onChipTap != null
                        ? () => onChipTap!(ContributionChipType.pullRequests)
                        : null,
                  ),
                if (highlight.totalPullRequestReviewContributions > 0)
                  ContributionInfoChip.reviews(
                    count: highlight.totalPullRequestReviewContributions,
                    repoCount: highlight
                        .totalRepositoriesWithContributedPullRequestReviews,
                    onTap: onChipTap != null
                        ? () => onChipTap!(ContributionChipType.reviews)
                        : null,
                  ),
                if (highlight.totalRepositoryContributions > 0)
                  ContributionInfoChip.repositories(
                    count: highlight.totalRepositoryContributions,
                    onTap: onChipTap != null
                        ? () => onChipTap!(ContributionChipType.createdRepos)
                        : null,
                  ),
                if (highlight.restrictedContributionsCount > 0)
                  ContributionInfoChip.private(
                    count: highlight.restrictedContributionsCount,
                    colorScheme: theme.colorScheme,
                    onTap: onChipTap != null
                        ? () => onChipTap!(ContributionChipType.private)
                        : null,
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
                highlight.joinedGitHub != null) ...<Widget>[
              SizedBox(height: spacing.compactSpacing * 2),
              _buildHighlightCards(context, ref, highlight),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildHighlightCards(
    final BuildContext context,
    final WidgetRef ref,
    final YearlyContributionHighlights highlight,
  ) {
    final List<Widget> cards = <Widget>[];

    // First issue
    if (highlight.firstIssue != null) {
      cards.add(
        _buildHighlightSection(
          context,
          ref,
          title: 'First issue',
          item: highlight.firstIssue!,
        ),
      );
    }

    // First pull request
    if (highlight.firstPullRequest != null) {
      cards.add(
        _buildHighlightSection(
          context,
          ref,
          title: 'First pull request',
          item: highlight.firstPullRequest!,
        ),
      );
    }

    // First repository
    if (highlight.firstRepository != null) {
      cards.add(
        _buildHighlightSection(
          context,
          ref,
          title: 'First repository',
          item: highlight.firstRepository!,
        ),
      );
    }

    // Popular issue
    if (highlight.popularIssue != null) {
      cards.add(
        _buildHighlightSection(
          context,
          ref,
          title: 'Most commented issue',
          item: highlight.popularIssue!,
        ),
      );
    }

    // Popular pull request
    if (highlight.popularPullRequest != null) {
      cards.add(
        _buildHighlightSection(
          context,
          ref,
          title: 'Most commented pull request',
          item: highlight.popularPullRequest!,
        ),
      );
    }

    // Most reviewed repository
    if (highlight.mostReviewedRepository != null) {
      cards.add(
        _buildHighlightSection(
          context,
          ref,
          title: 'Most reviewed repository',
          item: highlight.mostReviewedRepository!,
        ),
      );
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
    final BuildContext context,
    final WidgetRef ref, {
    required final String title,
    required final ContributionHighlightItem item,
  }) {
    final ThemeData theme = Theme.of(context);

    final AppSpacing spacing = context.spacing;

    // Handle restricted items
    if (item.isRestricted) {
      return Padding(
        padding: EdgeInsets.only(bottom: spacing.compactSpacing * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.tightSpacing,
                vertical: spacing.tightSpacing,
              ),
              child: Text(
                title,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
            spacing.tightGap,
            Container(
              padding: context.spacing.contentPadding,
              decoration: context.surfaceDecoration(
                RadiusSize.small,
                color: theme.colorScheme.surfaceContainerHighest.borderO,
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.hinted,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    Octicons.lock,
                    size: 16,
                    color: theme.colorScheme.tertiary,
                  ),
                  spacing.itemGap,
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
      padding: EdgeInsets.only(bottom: spacing.compactSpacing * 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.tightSpacing,
              vertical: spacing.tightSpacing,
            ),
            child: Text(
              title,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
          spacing.tightGap,
          _buildCard(item, context, ref),
        ],
      ),
    );
  }

  Widget _buildCard(
    final ContributionHighlightItem item,
    final BuildContext context,
    final WidgetRef ref,
  ) {
    switch (item.type) {
      case ContributionHighlightType.issue:
        if (item.graphQLIssue != null) {
          final IssueCardData data = item.graphQLIssue! as IssueCardData;
          return BorderedContainer(
            ref: IssueRef.fromIssueCardFields(data),
            child: IssuePullCard.fromIssue(data),
          );
        }
        return _buildMinimalIssueCard(context, ref, item);
      case ContributionHighlightType.pullRequest:
        if (item.graphQLPullRequest != null) {
          final PullCardData data =
              item.graphQLPullRequest! as PullCardData;
          return BorderedContainer(
            ref: PullRequestRef.fromPullCardFields(data),
            child: IssuePullCard.fromPullRequest(data),
          );
        }
        return _buildMinimalPullRequestCard(context, ref, item);
      case ContributionHighlightType.repository:
        if (item.graphQLRepository != null) {
          final RepoCardData repoData =
              item.graphQLRepository! as RepoCardData;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              BorderedContainer(
                ref: RepoRef.fromRepoCardFields(repoData),
                child: RepositoryCard(repoData),
              ),
              if ((item.commentCount ?? 0) > 0)
                ContributionBreakdownRow(reviews: item.commentCount),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildMinimalRepoCard(context, ref, item),
            if ((item.commentCount ?? 0) > 0)
              ContributionBreakdownRow(reviews: item.commentCount),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMinimalIssueCard(final BuildContext context,
      final WidgetRef widgetRef, final ContributionHighlightItem item) {
    final IssueRef issueRef = IssueRef(
      repo: RepoRef(owner: item.repositoryOwner, name: item.repositoryName),
      number: item.number ?? 0,
    );
    final VisualState state = item.state ?? IssueVisualState.open;
    return BorderedContainer(
      ref: issueRef,
      child: Row(
        children: <Widget>[
          StateChip(number: item.number ?? 0, state: state),
          context.spacing.itemGap,
          Expanded(child: Text(item.title)),
        ],
      ),
    );
  }

  Widget _buildMinimalPullRequestCard(final BuildContext context,
      final WidgetRef widgetRef, final ContributionHighlightItem item) {
    final PullRequestRef prRef = PullRequestRef(
      repo: RepoRef(owner: item.repositoryOwner, name: item.repositoryName),
      number: item.number ?? 0,
    );
    final VisualState state = item.state ?? PrVisualState.open;
    return BorderedContainer(
      ref: prRef,
      child: Row(
        children: <Widget>[
          StateChip(number: item.number ?? 0, state: state),
          context.spacing.itemGap,
          Expanded(child: Text(item.title)),
        ],
      ),
    );
  }

  Widget _buildMinimalRepoCard(final BuildContext context,
      final WidgetRef widgetRef, final ContributionHighlightItem item) {
    final RepoRef repoRef = RepoRef(
      owner: item.repositoryOwner,
      name: item.repositoryName,
    );
    return BorderedContainer(
      ref: repoRef,
      child: Text(item.repositoryFullName),
    );
  }

  Widget _buildJoinedCard(
      final BuildContext context, final DateTime joinedDate) {
    final ThemeData theme = Theme.of(context);
    final List<String> monthNames = <String>[
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

    final AppSpacing spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.itemSpacing),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.compactSpacing + spacing.tightSpacing,
          vertical: spacing.compactSpacing,
        ),
        decoration: context.surfaceDecoration(
          RadiusSize.small,
          color: theme.colorScheme.primaryContainer.borderO,
          border: Border.all(
            color: theme.colorScheme.primary.borderO,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Octicons.heart,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            spacing.itemGap,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Joined GitHub',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  spacing.tightGap,
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

  String _formatDateRange(final DateTime from, final DateTime to) {
    final List<String> monthNames = <String>[
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
