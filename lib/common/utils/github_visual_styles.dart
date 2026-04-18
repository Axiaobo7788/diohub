import 'package:diohub_graphql/schema_typedefs.dart' as gql;
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_models/models/events/events_model.dart';
import 'package:diohub_models/models/issues/issue_model.dart';
import 'package:diohub_models/models/visual_state.dart';
import 'package:diohub/utils/pagination/event_grouping_reducer.dart';
import 'package:diohub/utils/timeline/timeline_compound_data.dart'
    show TimelineCompoundData;
import 'package:diohub/utils/timeline/timeline_grouping_strategy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// A resolved visual style for any GitHub action/state.
/// Single source of truth for icon, color, and label across the app.
@immutable
class GitHubActionVisual {
  const GitHubActionVisual({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;
}

/// Centralized visual style resolution for GitHub entities.
/// Replaces scattered icon/color logic across events, cards, discussions, etc.
abstract final class GitHubVisualStyles {
  // ── Issue actions ──
  static const GitHubActionVisual issueOpened = GitHubActionVisual(
    icon: Octicons.issue_opened,
    color: Color(0xFF4CAF50),
    label: 'Open',
  );
  static const GitHubActionVisual issueClosed = GitHubActionVisual(
    icon: Octicons.issue_closed,
    color: Color(0xFF9C27B0),
    label: 'Closed',
  );
  static const GitHubActionVisual issueClosedNotPlanned = GitHubActionVisual(
    icon: Octicons.skip,
    color: Color(0xFF8B949E),
    label: 'Not planned',
  );
  static const GitHubActionVisual issueClosedDuplicate = GitHubActionVisual(
    icon: Octicons.issue_closed,
    color: Color(0xFF8B949E),
    label: 'Duplicate',
  );
  static const GitHubActionVisual issueReopened = GitHubActionVisual(
    icon: Octicons.issue_reopened,
    color: Color(0xFF4CAF50),
    label: 'Reopened',
  );

  // ── PR actions ──
  static const GitHubActionVisual prOpened = GitHubActionVisual(
    icon: Octicons.git_pull_request,
    color: Color(0xFF4CAF50),
    label: 'Open',
  );
  static const GitHubActionVisual prClosed = GitHubActionVisual(
    icon: Octicons.git_pull_request_closed,
    color: Color(0xFFF44336),
    label: 'Closed',
  );
  static const GitHubActionVisual prMerged = GitHubActionVisual(
    icon: Octicons.git_merge,
    color: Color(0xFF9C27B0),
    label: 'Merged',
  );
  static const GitHubActionVisual prDraft = GitHubActionVisual(
    icon: Octicons.git_pull_request_draft,
    color: Color(0xFF9E9E9E),
    label: 'Draft',
  );

  // ── Event-type actions ──
  static const GitHubActionVisual push = GitHubActionVisual(
    icon: Octicons.git_commit,
    color: Color(0xFF2196F3),
    label: 'Pushed',
  );
  static const GitHubActionVisual comment = GitHubActionVisual(
    icon: Octicons.comment,
    color: Color(0xFF00ACC1),
    label: 'Commented',
  );
  static const GitHubActionVisual watch = GitHubActionVisual(
    icon: Octicons.star,
    color: Color(0xFFFFC107),
    label: 'Starred',
  );
  static const GitHubActionVisual fork = GitHubActionVisual(
    icon: Octicons.repo_forked,
    color: Color(0xFF00BCD4),
    label: 'Forked',
  );
  static const GitHubActionVisual createRef = GitHubActionVisual(
    icon: Octicons.plus,
    color: Color(0xFF009688),
    label: 'Created',
  );
  static const GitHubActionVisual deleteRef = GitHubActionVisual(
    icon: Octicons.trash,
    color: Color(0xFFF44336),
    label: 'Deleted',
  );
  static const GitHubActionVisual publicEvent = GitHubActionVisual(
    icon: Octicons.globe,
    color: Color(0xFF3F51B5),
    label: 'Made public',
  );
  static const GitHubActionVisual memberEvent = GitHubActionVisual(
    icon: Octicons.person_add,
    color: Color(0xFFFF9800),
    label: 'Member',
  );
  static const GitHubActionVisual release = GitHubActionVisual(
    icon: Octicons.tag,
    color: Color(0xFF009688),
    label: 'Released',
  );

  // ── Timeline-specific (discussion) ──
  static const GitHubActionVisual assigned = GitHubActionVisual(
    icon: Octicons.person_add,
    color: Color(0xFFFF9800),
    label: 'Assigned',
  );
  static const GitHubActionVisual unassigned = GitHubActionVisual(
    icon: Octicons.person,
    color: Color(0xFFF44336),
    label: 'Unassigned',
  );
  static const GitHubActionVisual labeled = GitHubActionVisual(
    icon: Octicons.tag,
    color: Color(0xFF00ACC1),
    label: 'Labeled',
  );
  static const GitHubActionVisual unlabeled = GitHubActionVisual(
    icon: Octicons.tag,
    color: Color(0xFF00ACC1),
    label: 'Unlabeled',
  );
  static const GitHubActionVisual review = GitHubActionVisual(
    icon: Icons.remove_red_eye_rounded,
    color: Color(0xFF00ACC1),
    label: 'Reviewed',
  );
  static const GitHubActionVisual milestone = GitHubActionVisual(
    icon: Icons.delete_rounded,
    color: Color(0xFF9C27B0),
    label: 'Milestone',
  );
  static const GitHubActionVisual crossReference = GitHubActionVisual(
    icon: Octicons.link_external,
    color: Color(0xFF00BCD4),
    label: 'Referenced',
  );
  static const GitHubActionVisual convertedToDraft = GitHubActionVisual(
    icon: MdiIcons.pencilCircle,
    color: Color(0xFF9E9E9E),
    label: 'Converted to draft',
  );
  static const GitHubActionVisual readyForReview = GitHubActionVisual(
    icon: Icons.mark_chat_read_rounded,
    color: Color(0xFF2196F3),
    label: 'Ready for review',
  );
  static const GitHubActionVisual locked = GitHubActionVisual(
    icon: MdiIcons.lock,
    color: Color(0xFF9E9E9E),
    label: 'Locked',
  );
  static const GitHubActionVisual unlocked = GitHubActionVisual(
    icon: MdiIcons.lockOpen,
    color: Color(0xFF9E9E9E),
    label: 'Unlocked',
  );
  static const GitHubActionVisual pinned = GitHubActionVisual(
    icon: MdiIcons.pin,
    color: Color(0xFF9E9E9E),
    label: 'Pinned',
  );
  static const GitHubActionVisual unpinned = GitHubActionVisual(
    icon: MdiIcons.pinOff,
    color: Color(0xFF9E9E9E),
    label: 'Unpinned',
  );
  static const GitHubActionVisual renamed = GitHubActionVisual(
    icon: Octicons.pencil,
    color: Color(0xFF9E9E9E),
    label: 'Renamed',
  );
  static const GitHubActionVisual refChanged = GitHubActionVisual(
    icon: Octicons.repo_push,
    color: Color(0xFF9E9E9E),
    label: 'Ref changed',
  );
  static const GitHubActionVisual repository = GitHubActionVisual(
    icon: Octicons.repo,
    color: Color(0xFF009688),
    label: 'Repository',
  );

  /// Fallback for unknown actions.
  static GitHubActionVisual fallback(final Color onSurfaceVariant) =>
      GitHubActionVisual(
        icon: Octicons.circle,
        color: onSurfaceVariant,
        label: '',
      );

  /// Resolve from SemanticAction + payload action enum.
  static GitHubActionVisual fromSemanticAction(
    final SemanticAction action, {
    final PayloadAction? payloadAction,
    final IssueStateReason? stateReason,
  }) =>
      switch (action) {
        SemanticAction.issueStateChange => switch (payloadAction) {
            PayloadAction.closed
                when stateReason == IssueStateReason.notPlanned =>
              issueClosedNotPlanned,
            PayloadAction.closed
                when stateReason == IssueStateReason.duplicate =>
              issueClosedDuplicate,
            PayloadAction.closed => issueClosed,
            PayloadAction.reopened => issueReopened,
            _ => issueOpened,
          },
        SemanticAction.prStateChange => switch (payloadAction) {
            PayloadAction.merged => prMerged,
            PayloadAction.closed => prClosed,
            PayloadAction.reopened => prOpened,
            _ => prOpened,
          },
        SemanticAction.push => push,
        SemanticAction.commentChange => comment,
        SemanticAction.labelChange => labeled,
        SemanticAction.assigned => assigned,
        SemanticAction.createRef => createRef,
        SemanticAction.deleteRef => deleteRef,
        SemanticAction.watch => watch,
        SemanticAction.fork => fork,
        SemanticAction.release => release,
        SemanticAction.wikiChange => const GitHubActionVisual(
            icon: Octicons.book,
            color: Color(0xFF00BCD4),
            label: 'Wiki',
          ),
        SemanticAction.public => publicEvent,
        SemanticAction.member => memberEvent,
        SemanticAction.review => review,
        SemanticAction.discussion => const GitHubActionVisual(
            icon: Octicons.comment_discussion,
            color: Color(0xFF8B5CF6),
            label: 'Discussion',
          ),
        SemanticAction.other => const GitHubActionVisual(
            icon: Octicons.circle,
            color: Color(0xFF9E9E9E),
            label: 'Other',
          ),
      };

  /// Resolve from IssueVisualState enum.
  static GitHubActionVisual fromIssueVisualState(
          final IssueVisualState state) =>
      switch (state) {
        IssueVisualState.open => issueOpened,
        IssueVisualState.closed => issueClosed,
        IssueVisualState.closedNotPlanned => issueClosedNotPlanned,
        IssueVisualState.closedDuplicate => issueClosedDuplicate,
      };

  /// Resolve from PrVisualState enum.
  static GitHubActionVisual fromPrVisualState(final PrVisualState state) =>
      switch (state) {
        PrVisualState.open => prOpened,
        PrVisualState.draft => prDraft,
        PrVisualState.closed => prClosed,
        PrVisualState.merged => prMerged,
      };

  /// Resolve from any VisualState.
  static GitHubActionVisual fromVisualState(final VisualState state) =>
      switch (state) {
        final IssueVisualState s => fromIssueVisualState(s),
        final PrVisualState s => fromPrVisualState(s),
      };

  /// Resolve from GraphQL issue state enum.
  /// Used by IssuePullState and issue_screen.dart.
  static GitHubActionVisual fromGraphQLIssueState(
    final gql.IssueState state, {
    final gql.IssueStateReason? stateReason,
  }) {
    if (state == gql.IssueState.OPEN) return issueOpened;
    if (state == gql.IssueState.CLOSED) {
      if (stateReason == gql.IssueStateReason.NOT_PLANNED) {
        return issueClosedNotPlanned;
      }
      if (stateReason == gql.IssueStateReason.DUPLICATE) {
        return issueClosedDuplicate;
      }
      return issueClosed;
    }
    return issueOpened;
  }

  /// Resolve from GraphQL pull request state enum.
  /// Used by IssuePullState and commit_info_screen.dart.
  static GitHubActionVisual fromGraphQLPullRequestState(
    final gql.PullRequestState state, {
    final bool isDraft = false,
  }) {
    if (state == gql.PullRequestState.MERGED) return prMerged;
    if (state == gql.PullRequestState.CLOSED) return prClosed;
    if (isDraft) return prDraft;
    return prOpened;
  }

  /// Resolve from timeline child node type (used by discussion.dart).
  /// Replaces _getIconFromChild / _getIconColorFromChild.
  static GitHubActionVisual fromTimelineChild(final dynamic child) {
    if (child is AssignedEvent) return assigned;
    if (child is UnassignedEvent) return unassigned;
    if (child is ClosedEvent) return issueClosed;
    if (child is ReopenedEvent) return issueReopened;
    if (child is MergedEvent) return prMerged;
    if (child is LabeledEvent) return labeled;
    if (child is UnlabeledEvent) return unlabeled;
    if (child is PullRequestCommitEvent) return push;
    if (child is gql.PullRequestReviewEvent) return review;
    if (child is MilestonedEvent || child is DemilestonedEvent)
      return milestone;
    if (child is CrossReferenceEvent) return crossReference;
    if (child is ConvertedToDraftEvent) return convertedToDraft;
    if (child is ReadyForReviewEvent) return readyForReview;
    if (child is LockedEvent) return locked;
    if (child is UnlockedEvent) return unlocked;
    if (child is PinnedEvent) return pinned;
    if (child is UnpinnedEvent) return unpinned;
    if (child is MarkedAsDuplicateEvent || child is UnmarkedAsDuplicateEvent) {
      return crossReference;
    }
    if (child is RenamedTitleEvent) return renamed;
    if (child is BaseRefChangedEvent ||
        child is BaseRefForcePushedEvent ||
        child is BaseRefDeletedEvent ||
        child is HeadRefForcePushedEvent ||
        child is HeadRefDeletedEvent ||
        child is HeadRefRestoredEvent) {
      return refChanged;
    }
    if (child is IssueCommentEvent) return comment;
    return const GitHubActionVisual(
      icon: Octicons.circle,
      color: Color(0xFF9E9E9E),
      label: '',
    );
  }

  /// Resolve from timeline semantic action (and optional state reason / verb).
  /// Use with [TimelineCompoundData.partActions] so UI does not touch raw nodes.
  static GitHubActionVisual fromTimelineAction(
    final IssueTimelineSemanticAction action, {
    final gql.IssueStateReason? stateReason,
    final String? stateVerb,
  }) {
    switch (action) {
      case IssueTimelineSemanticAction.assigned:
        return assigned;
      case IssueTimelineSemanticAction.unassigned:
        return unassigned;
      case IssueTimelineSemanticAction.stateChange:
        if (stateVerb == 'merged') return prMerged;
        if (stateVerb == 'reopened') return issueReopened;
        if (stateReason == gql.IssueStateReason.NOT_PLANNED) {
          return issueClosedNotPlanned;
        }
        if (stateReason == gql.IssueStateReason.DUPLICATE) {
          return issueClosedDuplicate;
        }
        return issueClosed;
      case IssueTimelineSemanticAction.labelChange:
        return labeled;
      case IssueTimelineSemanticAction.commitPush:
        return push;
      case IssueTimelineSemanticAction.review:
        return review;
      case IssueTimelineSemanticAction.milestoneChange:
        return milestone;
      case IssueTimelineSemanticAction.crossReference:
        return crossReference;
      case IssueTimelineSemanticAction.comment:
        return comment;
      case IssueTimelineSemanticAction.other:
        return refChanged; // rename, lock, pin, ref events
    }
  }

  // NOTE: fromIssueAction(String) and fromPullRequestAction(String) have been
  // removed. Use fromIssueVisualState() and fromPrVisualState() instead for
  // type-safe visual resolution.
}
