import 'package:diohub/common/cards/issue_pull_card.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/database_providers.dart'
    show apiClientProvider;
import 'package:diohub/providers/compose/compose_draft_notifier.dart';
import 'package:diohub/providers/issue_pulls/issue_providers.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/common/pagination/item_patch.dart';
import 'package:diohub/providers/pagination/patch_providers.dart';
import 'package:diohub/view/issues_pulls/widgets/basic_event_card.dart';
import 'package:diohub/view/issues_pulls/widgets/discussion_comment.dart';
import 'package:diohub/view/issues_pulls/widgets/timeline/timeline_expandable_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Parameters passed to timeline event builders that need widget/context state.
class TimelineBuildParams {
  const TimelineBuildParams({
    required this.onQuote,
    required this.commentDraftKey,
    this.pullNodeID,
    this.pullRef,
    this.issueRef,
    this.repoRef,
    this.scrollToCommentId,
    this.timelineKey,
    this.issueCommentBuilder,
    this.reviewCardFooterBuilder,
  });

  final VoidCallback onQuote;
  final DraftKey commentDraftKey;
  final String? pullNodeID;
  final PullRequestRef? pullRef;
  final IssueRef? issueRef;
  final RepoRef? repoRef;
  final String? scrollToCommentId;
  final String? timelineKey;

  /// Optional premium override for rendering [IssueCommentEvent] cards.
  /// When null the OSS fallback (no minimize/unminimize) is used.
  final Widget Function(
    BuildContext,
    WidgetRef,
    TimelineBuildParams,
    IssueCommentEvent,
  )?
  issueCommentBuilder;

  /// Optional premium override for rendering the review card footer (dismiss button).
  /// When null the footer is omitted in free builds.
  final Widget? Function(
    BuildContext,
    WidgetRef,
    TimelineBuildParams,
    TimelinePullRequestReviewEvent,
  )?
  reviewCardFooterBuilder;
}

String getReviewState(final PullRequestReviewState state) => switch (state) {
  PullRequestReviewState.APPROVED => 'Approved this.',
  PullRequestReviewState.CHANGES_REQUESTED => 'Requested Changes.',
  PullRequestReviewState.COMMENTED => 'Reviewed this.',
  PullRequestReviewState.DISMISSED => 'Dismissed this.',
  PullRequestReviewState.PENDING => 'Review Pending.',
  PullRequestReviewState() => 'Reviewed.',
};

Color? issueTypeColor(final IssueTypeColor? color) {
  if (color == null) return null;
  return switch (color) {
    IssueTypeColor.BLUE => Colors.blue,
    IssueTypeColor.GRAY => Colors.grey,
    IssueTypeColor.GREEN => Colors.green,
    IssueTypeColor.ORANGE => Colors.orange,
    IssueTypeColor.PINK => Colors.pink,
    IssueTypeColor.PURPLE => Colors.purple,
    IssueTypeColor.RED => Colors.red,
    _ => null,
  };
}

BasicEventTextCard buildUnpinnedCard(final UnpinnedEvent item) =>
    BasicEventTextCard(
      user: item.actor,
      leading: MdiIcons.pinOff,
      date: item.createdAt,
      textContent: 'Unpinned this.',
    );

BasicEventTextCard buildUnmarkedAsDuplicateCard(
  final UnmarkedAsDuplicateEvent item,
) => BasicEventTextCard(
  textContent: 'Marked this as not a duplicate of',
  footer: Builder(
    builder: (final BuildContext context) {
      final Widget? cardWidget = item.canonical?.maybeWhen(
        issue: (final UnmarkedAsDuplicateCanonicalIssue card) =>
            BorderedContainer(
              ref: IssueRef.fromIssueCardFields(card),
              child: IssuePullCard.fromIssue(
                card,
                showDescription: false,
                useStateColor: false,
              ),
            ),
        pullRequest: (final UnmarkedAsDuplicateCanonicalPullRequest card) =>
            BorderedContainer(
              ref: PullRequestRef.fromPullCardFields(card),
              child: IssuePullCard.fromPullRequest(
                card,
                showDescription: false,
                useStateColor: false,
              ),
            ),
        orElse: () => null,
      );
      return cardWidget ?? const SizedBox.shrink();
    },
  ),
  user: item.actor,
  leading: Octicons.link_external,
  date: item.createdAt,
);

BasicEventTextCard buildUnlockedCard(final UnlockedEvent item) =>
    BasicEventTextCard(
      textContent: 'Unlocked this.',
      user: item.actor,
      date: item.createdAt,
      leading: MdiIcons.lockOff,
    );

BasicEventLabeledCard buildUnlabeledCard(final UnlabeledEvent item) =>
    BasicEventLabeledCard(
      actor: item.actor,
      content: item.label,
      added: false,
      date: item.createdAt,
    );

BasicEventAssignedCard buildUnassignedCard(final UnassignedEvent item) =>
    BasicEventAssignedCard(
      actor: item.actor,
      assignee: item.assignee as Actor?,
      createdAt: item.createdAt,
      isAssigned: false,
    );

BasicEventCard buildReviewRequestedCard(
  final TimelineReviewRequestedEvent item,
) => BasicEventCard(
  user: item.actor,
  date: item.createdAt,
  leading: Icons.remove_red_eye_rounded,
  headerText: <TextSpan>[
    const TextSpan(text: 'Requested a review from '),
    TextSpan(
      text: item.requestedReviewer!.when<String>(
        user: (final u) => u.login,
        team: (final TimelineReviewRequestedTeam p0) => p0.name,
        bot: (final b) => '(bot)',
        mannequin: (final m) => '(mannequin)',
        orElse: () =>
            throw UnimplementedError('Unexpected requestedReviewer type'),
      ),
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ],
  content: const SizedBox.shrink(),
);

BasicEventTextCard buildReopenedCard(final ReopenedEvent item) =>
    BasicEventTextCard(
      textContent: 'Reopened this.',
      user: item.actor,
      leading: Octicons.issue_reopened,
      iconColor: Colors.green,
      date: item.createdAt,
    );

BasicEventCard buildRenamedTitleCard(
  final RenamedTitleEvent item,
  final BuildContext context,
) => BasicEventCard(
  user: item.actor,
  leading: Octicons.pencil,
  date: item.createdAt,
  headerText: const <TextSpan>[TextSpan(text: 'Renamed this.')],
  content: Text.rich(
    TextSpan(
      children: <InlineSpan>[
        TextSpan(
          text: '${item.previousTitle}\n',
          style: const TextStyle(decoration: TextDecoration.lineThrough),
        ),
        TextSpan(text: item.currentTitle),
      ],
    ),
  ),
);

BasicEventTextCard buildReadForReviewCard(final ReadyForReviewEvent item) =>
    BasicEventTextCard(
      user: item.actor,
      date: item.createdAt,
      leading: Icons.mark_chat_read_rounded,
      textContent: 'Marked this as ready for review.',
    );

BaseComment buildPullRequestReviewCard(
  final TimelinePullRequestReviewEvent item,
  final BuildContext context,
  final WidgetRef ref,
  final TimelineBuildParams params,
) => BaseComment(
  resourceUri: Uri.parse('asdhbj'),
  commentDraftKey: params.commentDraftKey,
  description: getReviewState(item.state),
  onQuote: params.onQuote,
  leading: Icons.remove_red_eye_rounded,
  isMinimized: false,
  reactions: item.reactionGroups!.toList(),
  viewerCanDelete: item.viewerCanDelete,
  viewerCanMinimize: false,
  viewerCannotUpdateReasons: item.viewerCannotUpdateReasons.toList(),
  viewerCanReact: item.viewerCanReact,
  viewerCanUpdate: item.viewerCanUpdate,
  viewerDidAuthor: item.viewerDidAuthor,
  author: item.author,
  authorAssociation: item.authorAssociation,
  body: item.body,
  bodyHTML: item.bodyHTML,
  createdAt: item.createdAt,
  lastEditedAt: item.lastEditedAt,
  footer: params.reviewCardFooterBuilder?.call(context, ref, params, item),
  onEdit: item.viewerDidAuthor
      ? (final String newBody) async {
          await params.pullRef!
              .services(ref.read(apiClientProvider))
              .updatePullRequestReview(item.id, body: newBody);
          if (params.pullRef != null && context.mounted) {
            ref.invalidate(pullDetailProvider(params.pullRef!));
          }
        }
      : null,
);

Widget buildPullRequestCommitCard(
  final PullRequestCommitEvent item,
  final RepoRef? repoRef,
) {
  if (repoRef != null) {
    return SingleCommitExpandableCard(
      commit: item.commit,
      repoRef: repoRef,
      user: item.commit.author?.user,
      date: item.commit.authoredDate,
    );
  }
  return BasicEventTextCard(
    user: item.commit.author?.user,
    date: item.commit.authoredDate,
    leading: Octicons.git_commit,
    textContent: 'Made a commit.',
  );
}

BasicEventTextCard buildPinnedCard(final PinnedEvent item) =>
    BasicEventTextCard(
      user: item.actor,
      leading: MdiIcons.pin,
      date: item.createdAt,
      textContent: 'Pinned this.',
    );

BasicEventTextCard buildMilestonedCard(final MilestonedEvent item) =>
    BasicEventTextCard(
      textContent: 'Added this to milestone ${item.milestoneTitle}.',
      user: item.actor,
      leading: Icons.flag_rounded,
      date: item.createdAt,
    );

BasicEventTextCard buildMergedCard(final MergedEvent item) =>
    BasicEventTextCard(
      textContent: 'Merged this.',
      user: item.actor,
      leading: Octicons.git_merge,
      iconColor: Colors.purple,
      date: item.createdAt,
    );

BasicEventTextCard buildMarkedAsDuplicateCard(
  final MarkedAsDuplicateEvent item,
) => BasicEventTextCard(
  textContent: 'Marked this as a duplicate of',
  footer: Builder(
    builder: (final BuildContext context) {
      final Widget? cardWidget = item.canonical?.maybeWhen(
        issue: (final MarkedAsDuplicateCanonicalIssue card) =>
            BorderedContainer(
              ref: IssueRef.fromIssueCardFields(card),
              child: IssuePullCard.fromIssue(
                card,
                showDescription: false,
                useStateColor: false,
              ),
            ),
        pullRequest: (final MarkedAsDuplicateCanonicalPullRequest p0) =>
            BorderedContainer(
              ref: PullRequestRef.fromPullCardFields(p0),
              child: IssuePullCard.fromPullRequest(
                p0,
                showDescription: false,
                useStateColor: false,
              ),
            ),
        orElse: () => throw UnimplementedError(),
      );
      return cardWidget ?? const SizedBox.shrink();
    },
  ),
  user: item.actor,
  leading: Octicons.link_external,
  date: item.createdAt,
);

BasicEventTextCard buildLockedCard(
  final LockedEvent item,
) => BasicEventTextCard(
  textContent:
      'Locked this ${item.lockReason != null ? 'as ${item.lockReason} ' : ''}and limited conversation to collaborators',
  user: item.actor,
  date: item.createdAt,
  leading: MdiIcons.lock,
);

BasicEventLabeledCard buildLabeledItem(final LabeledEvent item) =>
    BasicEventLabeledCard(
      actor: item.actor,
      content: item.label,
      added: true,
      date: item.createdAt,
    );

BasicEventTextCard buildHeadRefRestoredCard(final HeadRefRestoredEvent item) =>
    BasicEventTextCard(
      textContent: 'Restored head ref.',
      user: item.actor,
      leading: Icons.delete_rounded,
      date: item.createdAt,
    );

Widget buildHeadRefForcePushedCard(
  final HeadRefForcePushedEvent item,
  final RepoRef? repoRef,
) {
  final String? beforeOid = item.beforeCommit?.oid;
  final String? afterOid = item.afterCommit?.oid;
  if (repoRef != null &&
      beforeOid != null &&
      afterOid != null &&
      beforeOid.isNotEmpty &&
      afterOid.isNotEmpty) {
    return ForcePushExpandableCard(
      repoRef: repoRef,
      beforeOid: beforeOid,
      afterOid: afterOid,
      refName: item.ref?.name ?? 'head',
      refLabel: 'head ref',
      user: item.actor,
      date: item.createdAt,
    );
  }
  return BasicEventTextCard(
    textContent:
        'Force pushed to head ref ${item.ref?.name}, from ${item.beforeCommit?.abbreviatedOid} to ${item.afterCommit?.abbreviatedOid}.',
    user: item.actor,
    leading: Octicons.repo_push,
    date: item.createdAt,
  );
}

BasicEventTextCard buildHeadRefDeletedCard(final HeadRefDeletedEvent item) =>
    BasicEventTextCard(
      textContent: 'Deleted head ref ${item.headRefName}.',
      user: item.actor,
      leading: Icons.delete_rounded,
      date: item.createdAt,
    );

BasicEventTextCard buildDemilestonedCard(final DemilestonedEvent item) =>
    BasicEventTextCard(
      textContent: 'Removed this from milestone ${item.milestoneTitle}.',
      user: item.actor,
      leading: Icons.delete_rounded,
      date: item.createdAt,
    );

BasicEventTextCard buildConvertedToDraftCard(
  final ConvertedToDraftEvent item,
) => BasicEventTextCard(
  textContent: 'Marked this as draft.',
  user: item.actor,
  leading: MdiIcons.pencilCircle,
  date: item.createdAt,
);

BasicEventTextCard buildClosedCard(final ClosedEvent item) =>
    BasicEventTextCard(
      textContent: 'Closed this.',
      user: item.actor,
      leading: Octicons.issue_closed,
      iconColor: Colors.red,
      date: item.createdAt,
    );

Widget buildForcePushedCard(
  final BaseRefForcePushedEvent item,
  final RepoRef? repoRef,
) {
  final String? beforeOid = item.beforeCommit?.oid;
  final String? afterOid = item.afterCommit?.oid;
  if (repoRef != null &&
      beforeOid != null &&
      afterOid != null &&
      beforeOid.isNotEmpty &&
      afterOid.isNotEmpty) {
    return ForcePushExpandableCard(
      repoRef: repoRef,
      beforeOid: beforeOid,
      afterOid: afterOid,
      refName: item.ref?.name ?? 'base',
      refLabel: 'base ref',
      user: item.actor,
      date: item.createdAt,
    );
  }
  return BasicEventTextCard(
    textContent:
        'Force pushed to base ref ${item.ref?.name}, from ${item.beforeCommit?.abbreviatedOid} to ${item.afterCommit?.abbreviatedOid}.',
    user: item.actor,
    leading: Octicons.repo_push,
    date: item.createdAt,
  );
}

BasicEventTextCard buildRefDeletedCard(final BaseRefDeletedEvent item) =>
    BasicEventTextCard(
      textContent: 'Deleted base ref ${item.baseRefName}.',
      user: item.actor,
      leading: Octicons.repo_push,
      date: item.createdAt,
    );

BasicEventTextCard buildBaseRefChangedCard(
  final BaseRefChangedEvent item,
) => BasicEventTextCard(
  textContent:
      'Changed base ref from ${item.previousRefName} to ${item.currentRefName}.',
  user: item.actor,
  leading: Octicons.git_branch,
  date: item.createdAt,
);

BasicEventAssignedCard buildBasicEventAssignedCard(final AssignedEvent item) =>
    BasicEventAssignedCard(
      actor: item.actor,
      assignee: item.assignee as Actor?,
      createdAt: item.createdAt,
      isAssigned: true,
    );

Widget buildIssueCommentWithPatches(
  final BuildContext context,
  final WidgetRef ref,
  final TimelineBuildParams params,
  final IssueCommentEvent item,
) {
  if (params.timelineKey == null) {
    return BaseComment(
      commentNodeId: item.id,
      isMinimized: item.isMinimized,
      onQuote: params.onQuote,
      commentDraftKey: params.commentDraftKey,
      resourceUri: item.url,
      reactions: item.reactionGroups!.toList(),
      minimizedReason: item.minimizedReason,
      viewerCanDelete: item.viewerCanDelete,
      viewerCanMinimize: item.viewerCanMinimize,
      viewerCannotUpdateReasons: item.viewerCannotUpdateReasons.toList(),
      viewerCanReact: item.viewerCanReact,
      viewerCanUpdate: item.viewerCanUpdate,
      viewerDidAuthor: item.viewerDidAuthor,
      author: item.author,
      authorAssociation: item.authorAssociation,
      body: item.body,
      bodyHTML: item.bodyHTML,
      createdAt: item.createdAt,
      lastEditedAt: item.lastEditedAt,
    );
  }
  return Consumer(
    builder: (final BuildContext context, final WidgetRef ref, final _) {
      final patches = ref.watch(timelinePatchesProvider(params.timelineKey!));
      final commentId = item.id;
      final patch = patches[commentId];
      if (patch is PatchDeleted) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Text(
            'Comment deleted',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }
      final PatchCommentEdit? edit = patch is PatchCommentEdit ? patch : null;
      final String? minimizedReasonFromPatch = patch is PatchMinimized
          ? patch.reason
          : null;
      final isMinimizedByPatch = patch is PatchMinimized;
      final isUnminimizedByPatch = patch is PatchUnminimized;
      final isMinimized = isUnminimizedByPatch
          ? false
          : (isMinimizedByPatch || item.isMinimized);
      return BaseComment(
        commentNodeId: item.id,
        isMinimized: isMinimized,
        onQuote: params.onQuote,
        commentDraftKey: params.commentDraftKey,
        resourceUri: item.url,
        reactions: item.reactionGroups!.toList(),
        minimizedReason: minimizedReasonFromPatch ?? item.minimizedReason,
        viewerCanDelete: item.viewerCanDelete,
        viewerCanMinimize: item.viewerCanMinimize,
        viewerCannotUpdateReasons: item.viewerCannotUpdateReasons.toList(),
        viewerCanReact: item.viewerCanReact,
        viewerCanUpdate: item.viewerCanUpdate,
        viewerDidAuthor: item.viewerDidAuthor,
        author: item.author,
        authorAssociation: item.authorAssociation,
        body: edit?.body ?? item.body,
        bodyHTML: edit?.bodyHTML ?? item.bodyHTML,
        createdAt: item.createdAt,
        lastEditedAt: edit?.lastEditedAt ?? item.lastEditedAt,
        onEdit: (final String newBody) {
          if (params.issueRef != null) {
            return ref
                .read(issueDetailProvider(params.issueRef!).notifier)
                .editComment(commentId, newBody);
          }
          return ref
              .read(pullDetailProvider(params.pullRef!).notifier)
              .editComment(commentId, newBody);
        },
        onDelete: () {
          if (params.issueRef != null) {
            return ref
                .read(issueDetailProvider(params.issueRef!).notifier)
                .deleteComment(commentId);
          }
          return ref
              .read(pullDetailProvider(params.pullRef!).notifier)
              .deleteComment(commentId);
        },
        repoRef: params.issueRef?.repo,
        commentDatabaseId: item.databaseId != null
            ? BigInt.from(item.databaseId!)
            : null,
      );
    },
  );
}

BasicEventTextCard buildCrossReferenceCard(final CrossReferenceEvent item) {
  final String repoNameWithOwner = item.source.maybeWhen(
    issue: (final CrossReferenceSourceIssue i) => i.repository.nameWithOwner,
    pullRequest: (final CrossReferenceSourcePullRequest p) =>
        p.repository.nameWithOwner,
    orElse: () => '',
  );
  final String str = item.isCrossRepository
      ? 'Referenced this in $repoNameWithOwner.'
      : 'Referenced this.';

  return BasicEventTextCard(
    textContent: str,
    footer: Builder(
      builder: (final BuildContext context) => item.source.maybeWhen(
        issue: (final CrossReferenceSourceIssue card) => BorderedContainer(
          ref: IssueRef.fromIssueCardFields(card),
          child: IssuePullCard.fromIssue(
            card,
            showDescription: false,
            useStateColor: false,
          ),
        ),
        pullRequest: (final CrossReferenceSourcePullRequest card) =>
            BorderedContainer(
              ref: PullRequestRef.fromPullCardFields(card),
              child: IssuePullCard.fromPullRequest(
                card,
                showDescription: false,
                useStateColor: false,
              ),
            ),
        orElse: () =>
            throw UnimplementedError('Timeline event not implemented'),
      ),
    ),
    user: item.actor,
    leading: Octicons.link_external,
    date: item.createdAt,
  );
}

BasicEventTextCard buildConnectedCard(final ConnectedEvent item) {
  final String repoName = item.source.maybeWhen(
    issue: (final i) => i.repository.nameWithOwner,
    pullRequest: (final p) => p.repository.nameWithOwner,
    orElse: () => '',
  );
  final String text = item.isCrossRepository
      ? 'Linked an issue from $repoName.'
      : 'Linked an issue.';

  return BasicEventTextCard(
    textContent: text,
    footer: Builder(
      builder: (final BuildContext context) => item.source.maybeWhen(
        issue: (final card) => BorderedContainer(
          ref: IssueRef.fromIssueCardFields(card),
          child: IssuePullCard.fromIssue(
            card,
            showDescription: false,
            useStateColor: false,
          ),
        ),
        pullRequest: (final card) => BorderedContainer(
          ref: PullRequestRef.fromPullCardFields(card),
          child: IssuePullCard.fromPullRequest(
            card,
            showDescription: false,
            useStateColor: false,
          ),
        ),
        orElse: () => const SizedBox.shrink(),
      ),
    ),
    user: item.actor,
    leading: Octicons.link,
    iconColor: Colors.green,
    date: item.createdAt,
  );
}

BasicEventTextCard buildDisconnectedCard(final DisconnectedEvent item) {
  final String repoName = item.source.maybeWhen(
    issue: (final i) => i.repository.nameWithOwner,
    pullRequest: (final p) => p.repository.nameWithOwner,
    orElse: () => '',
  );
  final String text = item.isCrossRepository
      ? 'Unlinked an issue from $repoName.'
      : 'Unlinked an issue.';

  return BasicEventTextCard(
    textContent: text,
    footer: Builder(
      builder: (final BuildContext context) => item.source.maybeWhen(
        issue: (final card) => BorderedContainer(
          ref: IssueRef.fromIssueCardFields(card),
          child: IssuePullCard.fromIssue(
            card,
            showDescription: false,
            useStateColor: false,
          ),
        ),
        pullRequest: (final card) => BorderedContainer(
          ref: PullRequestRef.fromPullCardFields(card),
          child: IssuePullCard.fromPullRequest(
            card,
            showDescription: false,
            useStateColor: false,
          ),
        ),
        orElse: () => const SizedBox.shrink(),
      ),
    ),
    user: item.actor,
    leading: Octicons.link_external,
    date: item.createdAt,
  );
}
