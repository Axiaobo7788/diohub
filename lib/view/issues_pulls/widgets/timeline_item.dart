import 'package:diohub/common/cards/issue_pull_card.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_graphql/fragments/common_exports.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/compose/compose_draft_notifier.dart';
import 'package:diohub/view/issues_pulls/widgets/basic_event_card.dart';
import 'package:diohub/view/issues_pulls/widgets/timeline/timeline_event_builders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class TimelineItem extends ConsumerWidget {
  const TimelineItem(
    this.timelineItem, {
    required this.onQuote,
    super.key,
    this.pullNodeID,
    this.pullRef,
    this.issueRef,
    required this.commentDraftKey,
    this.repoRef,
    this.scrollToCommentId,
    this.timelineKey,
    this.issueCommentBuilder,
    this.reviewCardFooterBuilder,
  });

  final dynamic timelineItem;
  final String? pullNodeID;

  /// When set with [pullNodeID], used to navigate to PR review (e.g. view review comments).
  final PullRequestRef? pullRef;

  /// When set, edit/delete comment calls [issueDetailProvider]. Not set when [pullRef] is set.
  final IssueRef? issueRef;

  final VoidCallback onQuote;
  final DraftKey commentDraftKey;

  /// Used for force-push "View commits" expand. When null, force-push shows text only.
  final RepoRef? repoRef;

  /// When set and this item is the matching comment (e.g. issuecomment-123), scroll into view.
  final String? scrollToCommentId;

  /// Key for [timelinePatchesProvider] (e.g. 'owner/name/number'). Enables edit/delete patch.
  final String? timelineKey;

  /// Premium override for rendering issue comment cards with minimize/unminimize support.
  final Widget Function(
    BuildContext,
    WidgetRef,
    TimelineBuildParams,
    IssueCommentEvent,
  )?
  issueCommentBuilder;

  /// Premium override for rendering the review card footer (dismiss button).
  final Widget? Function(
    BuildContext,
    WidgetRef,
    TimelineBuildParams,
    TimelinePullRequestReviewEvent,
  )?
  reviewCardFooterBuilder;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final params = TimelineBuildParams(
      onQuote: onQuote,
      commentDraftKey: commentDraftKey,
      pullNodeID: pullNodeID,
      pullRef: pullRef,
      issueRef: issueRef,
      repoRef: repoRef,
      scrollToCommentId: scrollToCommentId,
      timelineKey: timelineKey,
      issueCommentBuilder: issueCommentBuilder,
      reviewCardFooterBuilder: reviewCardFooterBuilder,
    );
    final dynamic item = timelineItem;
    final Widget child = switch (item) {
      final AssignedEvent item => buildBasicEventAssignedCard(item),
      final BaseRefChangedEvent item => buildBaseRefChangedCard(item),
      final BaseRefDeletedEvent item => buildRefDeletedCard(item),
      final BaseRefForcePushedEvent item => buildForcePushedCard(item, repoRef),
      final ClosedEvent item => buildClosedCard(item),
      final ConvertedToDraftEvent item => buildConvertedToDraftCard(item),
      final CrossReferenceEvent item => buildCrossReferenceCard(item),
      final DemilestonedEvent item => buildDemilestonedCard(item),
      final HeadRefDeletedEvent item => buildHeadRefDeletedCard(item),
      final HeadRefForcePushedEvent item => buildHeadRefForcePushedCard(
        item,
        repoRef,
      ),
      final HeadRefRestoredEvent item => buildHeadRefRestoredCard(item),
      final IssueCommentEvent item =>
        (params.issueCommentBuilder ?? buildIssueCommentWithPatches).call(
          context,
          ref,
          params,
          item,
        ),
      final LabeledEvent item => buildLabeledItem(item),
      final LockedEvent item => buildLockedCard(item),
      final MarkedAsDuplicateEvent item => buildMarkedAsDuplicateCard(item),
      final MergedEvent item => buildMergedCard(item),
      final MilestonedEvent item => buildMilestonedCard(item),
      final PinnedEvent item => buildPinnedCard(item),
      final PullRequestCommitEvent item => buildPullRequestCommitCard(
        item,
        repoRef,
      ),
      final TimelinePullRequestReviewEvent item => buildPullRequestReviewCard(
        item,
        context,
        ref,
        params,
      ),
      final ReadyForReviewEvent item => buildReadForReviewCard(item),
      final RenamedTitleEvent item => buildRenamedTitleCard(item, context),
      final ReopenedEvent item => buildReopenedCard(item),
      final TimelineReviewRequestedEvent item => buildReviewRequestedCard(item),
      final UnassignedEvent item => buildUnassignedCard(item),
      final UnlabeledEvent item => buildUnlabeledCard(item),
      final UnlockedEvent item => buildUnlockedCard(item),
      final UnmarkedAsDuplicateEvent item => buildUnmarkedAsDuplicateCard(item),
      final UnpinnedEvent item => buildUnpinnedCard(item),
      final AddedToMergeQueueEvent item => BasicEventTextCard(
        user: item.actor,
        leading: MdiIcons.sourceMerge,
        date: item.createdAt,
        textContent: 'Added to merge queue.',
        iconColor: Colors.deepPurple,
      ),
      final RemovedFromMergeQueueEvent item => BasicEventTextCard(
        user: item.actor,
        leading: MdiIcons.sourceMerge,
        date: item.createdAt,
        textContent: 'Removed from merge queue.',
      ),
      final AutoMergeEnabledEvent item => BasicEventTextCard(
        user: item.actor,
        leading: MdiIcons.robotHappy,
        date: item.createdAt,
        textContent: 'Enabled auto-merge.',
        iconColor: Colors.green,
      ),
      final AutoMergeDisabledEvent item => BasicEventTextCard(
        user: item.actor,
        leading: MdiIcons.robotHappy,
        date: item.createdAt,
        textContent: 'Disabled auto-merge.',
      ),
      final SubIssueAddedEvent item => BasicEventTextCard(
        user: item.actor,
        leading: Octicons.checklist,
        date: item.createdAt,
        textContent: 'Added a sub-issue.',
        iconColor: Colors.green,
        footer: item.subIssue != null
            ? BorderedContainer(
                ref: IssueRef.fromIssueCardFields(item.subIssue!),
                child: IssuePullCard.fromIssue(
                  item.subIssue!,
                  showDescription: false,
                  useStateColor: false,
                ),
              )
            : null,
      ),
      final SubIssueRemovedEvent item => BasicEventTextCard(
        user: item.actor,
        leading: Octicons.checklist,
        date: item.createdAt,
        textContent: 'Removed a sub-issue.',
        footer: item.subIssue != null
            ? BorderedContainer(
                ref: IssueRef.fromIssueCardFields(item.subIssue!),
                child: IssuePullCard.fromIssue(
                  item.subIssue!,
                  showDescription: false,
                  useStateColor: false,
                ),
              )
            : null,
      ),
      final ParentIssueAddedEvent item => BasicEventTextCard(
        user: item.actor,
        leading: Octicons.issue_opened,
        date: item.createdAt,
        textContent: 'Added a parent issue.',
        iconColor: Colors.blue,
      ),
      final ParentIssueRemovedEvent item => BasicEventTextCard(
        user: item.actor,
        leading: Octicons.issue_opened,
        date: item.createdAt,
        textContent: 'Removed parent issue.',
      ),
      final IssueTypeAddedEvent item => BasicEventTextCard(
        user: item.actor,
        leading: Octicons.issue_opened,
        date: item.createdAt,
        textContent: 'Set type to ${item.issueType?.name ?? 'unknown'}.',
        iconColor: issueTypeColor(item.issueType?.color),
      ),
      final IssueTypeChangedEvent item => BasicEventTextCard(
        user: item.actor,
        leading: Octicons.issue_opened,
        date: item.createdAt,
        textContent:
            'Changed type from ${item.prevIssueType?.name ?? '?'} to ${item.issueType?.name ?? '?'}.',
        iconColor: issueTypeColor(item.issueType?.color),
      ),
      final IssueTypeRemovedEvent item => BasicEventTextCard(
        user: item.actor,
        leading: Octicons.issue_opened,
        date: item.createdAt,
        textContent: 'Removed type ${item.issueType?.name ?? ''}.',
      ),
      final AddedToProjectV2Event item => BasicEventTextCard(
        user: item.actor,
        leading: Octicons.project,
        date: item.createdAt,
        textContent: 'Added to project ${item.project?.title ?? ''}.',
      ),
      final RemovedFromProjectV2Event item => BasicEventTextCard(
        user: item.actor,
        leading: Octicons.project,
        date: item.createdAt,
        textContent: 'Removed from project ${item.project?.title ?? ''}.',
      ),
      final ProjectV2ItemStatusChangedEvent item => BasicEventTextCard(
        user: item.actor,
        leading: Octicons.project,
        date: item.createdAt,
        textContent:
            'Changed status from "${item.previousStatus}" to "${item.status}" in ${item.project?.title ?? 'project'}.',
      ),
      final DeploymentEnvironmentChangedEvent item => BasicEventTextCard(
        user: item.actor,
        leading: Octicons.rocket,
        date: item.createdAt,
        textContent:
            'Deployed to ${item.deploymentStatus.environment ?? 'environment'}.',
        iconColor: Colors.teal,
      ),
      final ConvertedToDiscussionEvent item => BasicEventTextCard(
        user: item.actor,
        leading: Octicons.comment_discussion,
        date: item.createdAt,
        textContent:
            'Converted this to discussion #${item.discussion?.number ?? ''}.',
        iconColor: Colors.purple,
      ),
      final BlockingAddedEvent item => BasicEventTextCard(
        user: item.actor,
        leading: Octicons.blocked,
        date: item.createdAt,
        textContent: 'Marked as blocking.',
        iconColor: Colors.orange,
        footer: item.blockedIssue != null
            ? BorderedContainer(
                ref: IssueRef.fromIssueCardFields(item.blockedIssue!),
                child: IssuePullCard.fromIssue(
                  item.blockedIssue!,
                  showDescription: false,
                  useStateColor: false,
                ),
              )
            : null,
      ),
      final BlockingRemovedEvent item => BasicEventTextCard(
        user: item.actor,
        leading: Octicons.blocked,
        date: item.createdAt,
        textContent: 'Removed blocking.',
        footer: item.blockedIssue != null
            ? BorderedContainer(
                ref: IssueRef.fromIssueCardFields(item.blockedIssue!),
                child: IssuePullCard.fromIssue(
                  item.blockedIssue!,
                  showDescription: false,
                  useStateColor: false,
                ),
              )
            : null,
      ),
      final BlockedByAddedEvent item => BasicEventTextCard(
        user: item.actor,
        leading: Octicons.blocked,
        date: item.createdAt,
        textContent: 'Blocked by.',
        iconColor: Colors.red,
        footer: item.blockingIssue != null
            ? BorderedContainer(
                ref: IssueRef.fromIssueCardFields(item.blockingIssue!),
                child: IssuePullCard.fromIssue(
                  item.blockingIssue!,
                  showDescription: false,
                  useStateColor: false,
                ),
              )
            : null,
      ),
      final BlockedByRemovedEvent item => BasicEventTextCard(
        user: item.actor,
        leading: Octicons.blocked,
        date: item.createdAt,
        textContent: 'Removed blocked-by.',
        footer: item.blockingIssue != null
            ? BorderedContainer(
                ref: IssueRef.fromIssueCardFields(item.blockingIssue!),
                child: IssuePullCard.fromIssue(
                  item.blockingIssue!,
                  showDescription: false,
                  useStateColor: false,
                ),
              )
            : null,
      ),
      final ConnectedEvent item => buildConnectedCard(item),
      final DisconnectedEvent item => buildDisconnectedCard(item),
      _ => Text('Unimplemented.', style: Theme.of(context).textTheme.bodySmall),
    };

    return child;
  }
}
