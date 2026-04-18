import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/cards/commit_card.dart';
import 'package:diohub/common/cards/issue_pull_card.dart';
import 'package:diohub/common/events/compound_annotation_chips.dart';
import 'package:diohub/common/cards/branch_refs.dart';
import 'package:diohub/common/issues/issue_label.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';

import 'package:diohub/models/commits/commit_list_item_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/timeline/timeline_compound_data.dart';
import 'package:diohub/utils/timeline/timeline_grouping_strategy.dart';
import 'package:diohub/view/issues_pulls/widgets/discussion.dart'
    show IssuePullTimeline;
import 'package:diohub/view/issues_pulls/widgets/timeline_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Builds the inner content widget for a non-comment timeline compound
/// using only [TimelineCompoundData]. Used by [IssuePullTimeline].
/// [repoRef] is passed for commit-push content so commits use [CommitCard].
Widget buildTimelineContextContent(
  final BuildContext context,
  final TimelineCompoundData data, {
  final RepoRef? repoRef,
}) {
  final IssueTimelineSemanticAction action = data.action;

  return switch (action) {
    IssueTimelineSemanticAction.labelChange =>
      _buildLabelChangeContent(context, data),
    IssueTimelineSemanticAction.stateChange =>
      _buildStateChangeContent(context, data, repoRef: repoRef),
    IssueTimelineSemanticAction.assigned =>
      _buildAssignedContent(context, data),
    IssueTimelineSemanticAction.unassigned =>
      _buildUnassignedContent(context, data),
    IssueTimelineSemanticAction.milestoneChange =>
      _buildMilestoneContent(context, data),
    IssueTimelineSemanticAction.review => _buildReviewContent(context, data),
    IssueTimelineSemanticAction.commitPush =>
      _buildCommitPushContent(context, data, repoRef: repoRef),
    IssueTimelineSemanticAction.crossReference =>
      _buildCrossReferenceContent(context, data),
    IssueTimelineSemanticAction.comment =>
      const SizedBox.shrink(), // Handled separately; never passed here
    IssueTimelineSemanticAction.other =>
      _buildOtherContent(context, data, repoRef: repoRef),
  };
}

Widget _buildLabelChangeContent(
  final BuildContext context,
  final TimelineCompoundData data,
) {
  final AppSpacing spacing = context.spacing;
  return Wrap(
    spacing: spacing.itemSpacing * 0.75,
    runSpacing: spacing.itemSpacing * 0.75,
    children: <Widget>[
      ...data.removedLabels.map(
        (final TimelineLabelInfo l) =>
            IssueLabel.fromNameColor(l.name, l.color, isRemoved: true),
      ),
      ...data.addedLabels.map(
        (final TimelineLabelInfo l) =>
            IssueLabel.fromNameColor(l.name, l.color),
      ),
    ],
  );
}

Widget _buildStateChangeContent(
  final BuildContext context,
  final TimelineCompoundData data, {
  final RepoRef? repoRef,
}) {
  final AppSpacing spacing = context.spacing;
  final ThemeData theme = Theme.of(context);
  final List<Widget> children = <Widget>[
    Row(
      children: <Widget>[
        Text(
          _capitalize(data.stateVerb ?? 'Changed'),
          style: theme.textTheme.bodySmall,
        ),
        if (data.stateReason != null) ...<Widget>[
          SizedBox(width: spacing.itemSpacing),
          StateReasonBadge(reason: data.stateReason!),
        ],
      ],
    ),
  ];
  if (data.closer != null) {
    final TimelineCloserInfo c = data.closer!;
    if (c.abbreviatedOid != null && c.commitUrl != null) {
      children.add(
        Padding(
          padding: EdgeInsets.only(top: spacing.itemSpacing * 0.75),
          child: repoRef != null
              ? InteractiveCommitChip(
                  abbreviatedOid: c.abbreviatedOid!,
                  fullOid: c.abbreviatedOid!,
                  repoRef: repoRef,
                )
              : CommitOidChip(
                  abbreviatedOid: c.abbreviatedOid!,
                  commitUrl: c.commitUrl!,
                ),
        ),
      );
    } else if (c.pullRequest != null) {
      children.add(
        Padding(
          padding: EdgeInsets.only(top: spacing.itemSpacing * 0.75),
          child: _issuePullCardFromData(context, pullData: c.pullRequest),
        ),
      );
    } else if (c.mergeRefName != null || c.mergeCommitOid != null) {
      children.add(
        Padding(
          padding: EdgeInsets.only(top: spacing.itemSpacing * 0.75),
          child: Wrap(
            spacing: spacing.itemSpacing,
            runSpacing: spacing.itemSpacing * 0.75,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              if (c.mergeRefName != null)
                repoRef != null
                    ? InteractiveBranchPill(
                        branchName: c.mergeRefName!,
                        repoRef: repoRef,
                      )
                    : BranchRefPill(branchName: c.mergeRefName!),
              if (c.mergeCommitOid != null && c.mergeCommitUrl != null)
                repoRef != null
                    ? InteractiveCommitChip(
                        abbreviatedOid: c.mergeCommitOid!,
                        fullOid: c.mergeCommitOid!,
                        repoRef: repoRef,
                      )
                    : CommitOidChip(
                        abbreviatedOid: c.mergeCommitOid!,
                        commitUrl: c.mergeCommitUrl!,
                      ),
            ],
          ),
        ),
      );
    }
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: children,
  );
}

Widget _buildAssignedContent(
    final BuildContext context, final TimelineCompoundData data) {
  final List<String> logins = data.assigneeLogins;
  if (logins.isEmpty) {
    return Text('Assigned', style: Theme.of(context).textTheme.bodySmall);
  }
  return Text(
    'Assigned to ${logins.join(', ')}',
    style: Theme.of(context).textTheme.bodySmall,
  );
}

Widget _buildUnassignedContent(
  final BuildContext context,
  final TimelineCompoundData data,
) {
  final List<String> logins = data.assigneeLogins;
  if (logins.isEmpty) {
    return Text('Unassigned', style: Theme.of(context).textTheme.bodySmall);
  }
  return Text(
    'Unassigned from ${logins.join(', ')}',
    style: Theme.of(context).textTheme.bodySmall,
  );
}

Widget _buildMilestoneContent(
    final BuildContext context, final TimelineCompoundData data) {
  final List<String> added = data.addedMilestoneTitles;
  final List<String> removed = data.removedMilestoneTitles;
  if (added.isNotEmpty && removed.isEmpty) {
    return Text(
      'Added to milestone: ${added.join(', ')}',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
  if (removed.isNotEmpty && added.isEmpty) {
    return Text(
      'Removed from milestone: ${removed.join(', ')}',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
  return Text(
    'Updated milestones',
    style: Theme.of(context).textTheme.bodySmall,
  );
}

Widget _buildReviewContent(
    final BuildContext context, final TimelineCompoundData data) {
  final TimelineReviewContext? rc = data.reviewContext;
  if (rc == null) return const SizedBox.shrink();
  final AppSpacing spacing = context.spacing;
  final List<Widget> children = <Widget>[
    Row(
      children: <Widget>[
        ReviewStateLabelBadge(label: rc.stateLabel),
        if (rc.commentCount > 0) ...<Widget>[
          SizedBox(width: spacing.itemSpacing),
          Text(
            '${rc.commentCount} ${rc.commentCount == 1 ? 'comment' : 'comments'}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    ),
  ];
  if (rc.body.trim().isNotEmpty) {
    children.add(
      Padding(
        padding: EdgeInsets.only(top: spacing.itemSpacing),
        child: InlineComment(body: rc.body),
      ),
    );
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: children,
  );
}

Widget _buildCommitPushContent(
  final BuildContext context,
  final TimelineCompoundData data, {
  final RepoRef? repoRef,
}) {
  final List<TimelineCommitSummary> commits = data.commits;
  if (commits.isEmpty) return const SizedBox.shrink();
  final AppSpacing spacing = context.spacing;

  if (repoRef != null) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: commits.map((final TimelineCommitSummary c) {
        final CommitListItemModel model = CommitListItemModel(
          messageHeadline: c.messageHeadline,
          committedDate: DateTime.now(),
          sha: c.oid,
          commitUrl: c.commitUrl,
          repoOwner: repoRef.owner,
          repoName: repoRef.name,
        );
        return Padding(
          padding: EdgeInsets.only(
            bottom: commits.indexOf(c) < commits.length - 1
                ? spacing.itemSpacing
                : 0,
          ),
          child: BorderedContainer(
            ref: CommitRef(repo: repoRef, oid: c.oid),
            child: CommitCard(data: model),
          ),
        );
      }).toList(),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: commits.map((final TimelineCommitSummary c) {
      final String? headline =
          c.messageHeadline.isNotEmpty ? c.messageHeadline : null;
      return Padding(
        padding: EdgeInsets.only(
          bottom:
              commits.indexOf(c) < commits.length - 1 ? spacing.itemSpacing : 0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                CommitOidChip(
                  abbreviatedOid: c.abbreviatedOid,
                  commitUrl: c.commitUrl,
                ),
                if (c.additions != null || c.deletions != null) ...<Widget>[
                  SizedBox(width: spacing.itemSpacing),
                  AdditionsDeletionsText(
                    additions: c.additions ?? 0,
                    deletions: c.deletions ?? 0,
                  ),
                ],
              ],
            ),
            if (headline != null)
              Padding(
                padding: EdgeInsets.only(top: spacing.itemSpacing / 2),
                child: Text(
                  headline,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      );
    }).toList(),
  );
}

Widget _buildCrossReferenceContent(
  final BuildContext context,
  final TimelineCompoundData data,
) {
  final AppSpacing spacing = context.spacing;
  final List<Widget> children = <Widget>[];
  if (data.willCloseTarget) {
    children.add(
      Padding(
        padding: EdgeInsets.only(bottom: spacing.itemSpacing * 0.75),
        child: const ClosesTargetBadge(),
      ),
    );
  }
  if (data.sourceIssue != null) {
    children.add(_issuePullCardFromData(context, issueData: data.sourceIssue));
  } else if (data.sourcePullRequest != null) {
    children
        .add(_issuePullCardFromData(context, pullData: data.sourcePullRequest));
  }
  if (data.sourceLabels.isNotEmpty) {
    children.add(
      Padding(
        padding: EdgeInsets.only(top: spacing.itemSpacing),
        child: Wrap(
          spacing: spacing.itemSpacing * 0.75,
          runSpacing: spacing.itemSpacing * 0.75,
          children: data.sourceLabels
              .map((final TimelineLabelInfo l) =>
                  IssueLabel.fromNameColor(l.name, l.color))
              .toList(),
        ),
      ),
    );
  }
  if (data.sourceBody != null && data.sourceBody!.trim().isNotEmpty) {
    children.add(
      Padding(
        padding: EdgeInsets.only(top: spacing.itemSpacing),
        child: InlineComment(body: data.sourceBody!),
      ),
    );
  }
  if (children.isEmpty) return const SizedBox.shrink();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: children,
  );
}

Widget _buildOtherContent(
  final BuildContext context,
  final TimelineCompoundData data, {
  final RepoRef? repoRef,
}) {
  final ThemeData theme = Theme.of(context);
  final AppSpacing spacing = context.spacing;
  final ColorScheme cs = theme.colorScheme;

  if (data.previousTitle != null && data.currentTitle != null) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          data.previousTitle!,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            decoration: TextDecoration.lineThrough,
            decorationThickness: 1.5,
            fontSize: 11,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Padding(
          padding: EdgeInsets.only(top: spacing.itemSpacing / 2),
          child: Text(data.currentTitle!, style: theme.textTheme.bodySmall),
        ),
      ],
    );
  }
  if (data.lockReason != null) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('Locked conversation', style: theme.textTheme.bodySmall),
        Padding(
          padding: EdgeInsets.only(top: spacing.itemSpacing * 0.75),
          child: LockReasonChip(reason: data.lockReason!),
        ),
      ],
    );
  }
  if (data.isPinned) {
    return Text('Pinned this', style: theme.textTheme.bodySmall);
  }
  if (data.isUnpinned) {
    return Text('Unpinned this', style: theme.textTheme.bodySmall);
  }
  if (data.duplicateCanonicalIssue != null) {
    return _issuePullCardFromData(
      context,
      issueData: data.duplicateCanonicalIssue,
    );
  }
  if (data.duplicateCanonicalPullRequest != null) {
    return _issuePullCardFromData(
      context,
      pullData: data.duplicateCanonicalPullRequest,
    );
  }
  if (data.isUnmarkedAsDuplicate) {
    if (data.unmarkedDuplicateCanonicalIssue != null) {
      return _issuePullCardFromData(
        context,
        issueData: data.unmarkedDuplicateCanonicalIssue,
      );
    }
    if (data.unmarkedDuplicateCanonicalPullRequest != null) {
      return _issuePullCardFromData(
        context,
        pullData: data.unmarkedDuplicateCanonicalPullRequest,
      );
    }
    return Text('Marked as not a duplicate', style: theme.textTheme.bodySmall);
  }
  if (data.baseRefPreviousName != null && data.baseRefCurrentName != null) {
    return Text(
      'Changed base ref from ${data.baseRefPreviousName} to ${data.baseRefCurrentName}',
      style: theme.textTheme.bodySmall,
    );
  }
  if (data.forcePushRefName != null &&
      data.forcePushBeforeOid != null &&
      data.forcePushAfterOid != null) {
    final String beforeOid = data.forcePushBeforeOid!;
    final String afterOid = data.forcePushAfterOid!;
    if (repoRef != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          InteractiveCommitChip(
            abbreviatedOid: beforeOid,
            fullOid: beforeOid,
            repoRef: repoRef,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing.tightSpacing),
            child: Text('→', style: theme.textTheme.bodySmall),
          ),
          InteractiveCommitChip(
            abbreviatedOid: afterOid,
            fullOid: afterOid,
            repoRef: repoRef,
          ),
          spacing.tightGap,
          TapFeedback(
            onTap: () => context.router.push(CompareViewRoute(
              repoRef: repoRef,
              base: beforeOid,
              head: afterOid,
            )),
            child: Icon(Octicons.git_compare, size: 14, color: cs.primary),
          ),
        ],
      );
    }
    final String label = data.forcePushRefLabel ?? 'ref';
    return Text(
      'Force pushed to $label ${data.forcePushRefName}, from $beforeOid to $afterOid',
      style: theme.textTheme.bodySmall,
    );
  }
  if (data.baseRefDeletedName != null) {
    return Text(
      'Deleted base ref ${data.baseRefDeletedName}',
      style: theme.textTheme.bodySmall,
    );
  }
  if (data.headRefDeletedName != null) {
    return Text(
      'Deleted head ref ${data.headRefDeletedName}',
      style: theme.textTheme.bodySmall,
    );
  }
  if (data.isHeadRefRestored) {
    return Text('Restored head ref', style: theme.textTheme.bodySmall);
  }
  if (data.isConvertedToDraft) {
    return Text('Marked as draft', style: theme.textTheme.bodySmall);
  }
  if (data.isReadyForReview) {
    return Text('Marked as ready for review', style: theme.textTheme.bodySmall);
  }
  return const SizedBox.shrink();
}

Widget _issuePullCardFromData(
  final BuildContext context, {
  final IssueCardData? issueData,
  final PullCardData? pullData,
}) {
  if (issueData != null) {
    return BorderedContainer(
      ref: IssueRef.fromIssueCardFields(issueData),
      child: IssuePullCard.fromIssue(
        issueData,
        showDescription: false,
        useStateColor: false,
      ),
    );
  }
  if (pullData != null) {
    return BorderedContainer(
      ref: PullRequestRef.fromPullCardFields(pullData),
      child: IssuePullCard.fromPullRequest(
        pullData,
        showDescription: false,
        useStateColor: false,
      ),
    );
  }
  return const SizedBox.shrink();
}

String _capitalize(final String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1).toLowerCase();
}
