import 'package:diohub/common/issues/issue_label.dart';
import 'package:diohub/common/utils/github_visual_styles.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/l10n/relative_time.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart' as gql;
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/search/issue_or_pull.dart';
import 'package:diohub_models/models/visual_state.dart';
import 'package:flutter/material.dart';

@immutable
class RepositoryIssuePullLabelData {
  const RepositoryIssuePullLabelData({required this.name, required this.color});

  final String name;
  final String color;
}

/// Presentation-only data for the compact Repository Issues/PR list.
///
/// Keeping this independent of generated GraphQL classes makes the row cheap to
/// test and lets a future public REST fallback reuse the same UI.
@immutable
class RepositoryIssuePullRowData {
  const RepositoryIssuePullRowData({
    required this.ref,
    required this.title,
    required this.number,
    required this.author,
    required this.timestamp,
    required this.commentsCount,
    required this.visualState,
    required this.labels,
  });

  factory RepositoryIssuePullRowData.fromSearchResult(
    final IssueOrPull result,
  ) {
    return switch (result) {
      IssueResult(:final data) => RepositoryIssuePullRowData(
        ref: IssueRef.fromIssueCardFields(data),
        title: data.title,
        number: data.number,
        author: data.author?.login,
        timestamp: data.closedAt ?? data.createdAt,
        commentsCount: data.comments.totalCount,
        visualState: IssueVisualState.fromNames(
          data.issueState.name,
          reasonName: data.stateReason?.name,
        ),
        labels:
            data.labels?.nodes
                ?.whereType<gql.IssueCardLabelNode>()
                .map(
                  (final gql.IssueCardLabelNode label) =>
                      RepositoryIssuePullLabelData(
                        name: label.name,
                        color: label.color,
                      ),
                )
                .toList(growable: false) ??
            const <RepositoryIssuePullLabelData>[],
      ),
      PullResult(:final data) => RepositoryIssuePullRowData(
        ref: PullRequestRef.fromPullCardFields(data),
        title: data.title,
        number: data.number,
        author: data.author?.login,
        timestamp: data.mergedAt ?? data.closedAt ?? data.createdAt,
        commentsCount: data.comments.totalCount,
        visualState: PrVisualState.fromNames(
          data.pullRequestState.name,
          merged: data.merged,
          isDraft: data.isDraft,
        ),
        labels:
            data.labels?.nodes
                ?.whereType<gql.PullCardLabelNode>()
                .map(
                  (final gql.PullCardLabelNode label) =>
                      RepositoryIssuePullLabelData(
                        name: label.name,
                        color: label.color,
                      ),
                )
                .toList(growable: false) ??
            const <RepositoryIssuePullLabelData>[],
      ),
    };
  }

  final EntityRef ref;
  final String title;
  final int number;
  final String? author;
  final DateTime timestamp;
  final int commentsCount;
  final VisualState visualState;
  final List<RepositoryIssuePullLabelData> labels;
}

class RepositoryIssuePullRow extends StatelessWidget {
  const RepositoryIssuePullRow({
    required this.data,
    required this.onTap,
    super.key,
  });

  final RepositoryIssuePullRowData data;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final GitHubActionVisual visual = GitHubVisualStyles.fromVisualState(
      data.visualState,
    );
    final String author = data.author?.trim().isNotEmpty == true
        ? data.author!
        : context.l10n.repoUnknownAuthor;
    final String action = switch (data.visualState) {
      IssueVisualState.open ||
      PrVisualState.open => context.l10n.repoListOpened,
      IssueVisualState.closed ||
      IssueVisualState.closedNotPlanned ||
      IssueVisualState.closedDuplicate ||
      PrVisualState.closed => context.l10n.repoListClosed,
      PrVisualState.draft => context.l10n.repoListDraft,
      PrVisualState.merged => context.l10n.repoListMerged,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey<String>(
          'repository-list-row-${data.ref.dbType}-${data.number}',
        ),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: colorScheme.outlineVariant),
              right: BorderSide(color: colorScheme.outlineVariant),
              bottom: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Tooltip(
                message: action,
                child: Icon(visual.icon, size: 20, color: visual.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Text(
                          data.title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        for (final RepositoryIssuePullLabelData label
                            in data.labels.take(5))
                          IssueLabel.fromNameColor(label.name, label.color),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.repoIssuePullListMetadata(
                        data.number,
                        author,
                        action,
                        formatRelativeTime(context, data.timestamp),
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (data.commentsCount > 0) ...<Widget>[
                const SizedBox(width: 12),
                Tooltip(
                  message: context.l10n.repoCommentsCount(data.commentsCount),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.mode_comment_outlined,
                        size: 17,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${data.commentsCount}',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
