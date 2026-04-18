import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/nav_center/models/action_surface.dart';
import 'package:diohub_graphql/schema_typedefs.dart';

// ─────────────────────────────────────────────────────
// Shared Action Groups
//
// Each function returns a List<ActionButtonData> that can be spread
// into a PopupMenuSection's actions list. Functions are pure — they
// take data values, not providers — so they can be called from any
// screen config builder.
// ─────────────────────────────────────────────────────

export 'package:diohub/common/nav_center/models/action_surface.dart';

/// Actions grouped by their target surface (for filtering by popup vs settings vs adaptive).
class SurfacedActions {
  const SurfacedActions(this.actions, this.surface);
  final List<ActionButtonData> actions;
  final ActionSurface surface;
}

// ── Star / Unstar (Repository) ──

List<ActionButtonData> starActions({
  required bool viewerHasStarred,
  required int stargazerCount,
  required VoidCallback onToggle,
  required ColorScheme colorScheme,
}) {
  return <ActionButtonData>[
    MajorActionButton(
      icon: viewerHasStarred ? Icons.star_rounded : Icons.star_outline_rounded,
      label: viewerHasStarred ? 'Unstar' : 'Star',
      trailing: Text(
        stargazerCount.toString(),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      seedColor: viewerHasStarred ? colorScheme.tertiary : null,
      onTap: onToggle,
    ),
  ];
}

// ── Fork (Repository) ──

List<ActionButtonData> forkActions({
  required bool forkingAllowed,
  required int forkCount,
  required VoidCallback onFork,
}) {
  return <ActionButtonData>[
    MajorActionButton(
      icon: Icons.fork_right_rounded,
      label: 'Fork',
      trailing: Text(
        forkCount.toString(),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      enabled: forkingAllowed,
      onTap: onFork,
    ),
  ];
}

// ── Subscription / Notifications (Repository, Issue, PR) ──

List<ActionButtonData> subscribableActions({
  required SubscriptionState currentState,
  required bool viewerCanSubscribe,
  required ValueChanged<SubscriptionState> onChanged,
}) {
  if (!viewerCanSubscribe) return const <ActionButtonData>[];

  return <ActionButtonData>[
    ExpandableActionButton.enumSelector<SubscriptionState>(
      icon: switch (currentState) {
        SubscriptionState.SUBSCRIBED => Icons.notifications_active_rounded,
        SubscriptionState.IGNORED => Icons.notifications_off_rounded,
        _ => Icons.notifications_outlined,
      },
      label: 'Notifications',
      value: currentState,
      values: SubscriptionState.values.toList(),
      onChanged: onChanged,
      labelBuilder: (SubscriptionState state) => switch (state) {
        SubscriptionState.SUBSCRIBED => 'Subscribed (All activity)',
        SubscriptionState.UNSUBSCRIBED => 'Not subscribed (Participating)',
        SubscriptionState.IGNORED => 'Ignored',
        _ => state.name,
      },
      iconBuilder: (SubscriptionState state) => switch (state) {
        SubscriptionState.SUBSCRIBED => Icons.notifications_active_rounded,
        SubscriptionState.IGNORED => Icons.notifications_off_rounded,
        _ => Icons.notifications_outlined,
      },
    ),
  ];
}

// ── Close / Reopen Issue ──

List<ActionButtonData> closeableIssueActions({
  required IssueState state,
  required bool viewerCanClose,
  required bool viewerCanReopen,
  required ValueChanged<IssueClosedStateReason?> onClose,
  required VoidCallback onReopen,
}) {
  final List<ActionButtonData> actions = <ActionButtonData>[];

  if (viewerCanClose && state == IssueState.OPEN) {
    actions.add(
      ExpandableActionButton.enumSelector<IssueClosedStateReason>(
        icon: Icons.cancel_rounded,
        label: 'Close as',
        value: IssueClosedStateReason.COMPLETED,
        values: const <IssueClosedStateReason>[
          IssueClosedStateReason.COMPLETED,
          IssueClosedStateReason.NOT_PLANNED,
        ],
        onChanged: onClose,
        labelBuilder: (IssueClosedStateReason reason) => switch (reason) {
          IssueClosedStateReason.COMPLETED => 'Completed',
          IssueClosedStateReason.NOT_PLANNED => 'Not planned',
          _ => reason.name,
        },
        iconBuilder: (IssueClosedStateReason reason) => switch (reason) {
          IssueClosedStateReason.COMPLETED => Icons.check_circle_rounded,
          IssueClosedStateReason.NOT_PLANNED => Icons.not_interested_rounded,
          _ => Icons.cancel_rounded,
        },
        isDestructive: true,
        category: 'State',
        surface: ActionSurface.adaptive,
      ),
    );
  }

  if (viewerCanReopen && state == IssueState.CLOSED) {
    actions.add(
      MajorActionButton(
        icon: Icons.replay_rounded,
        label: 'Reopen',
        isPositive: true,
        onTap: onReopen,
        category: 'State',
        surface: ActionSurface.adaptive,
      ),
    );
  }

  return actions;
}

// ── Close / Reopen / Merge Pull Request ──

List<ActionButtonData> closeablePullActions({
  required PullRequestState state,
  required bool viewerCanClose,
  required bool viewerCanReopen,
  required MergeableState? mergeableState,
  required VoidCallback onClose,
  required VoidCallback onReopen,
  required ValueChanged<PullRequestMergeMethod> onMerge,
  required List<PullRequestMergeMethod> availableMergeMethods,
}) {
  final List<ActionButtonData> actions = <ActionButtonData>[];

  if (state == PullRequestState.OPEN &&
      mergeableState == MergeableState.MERGEABLE &&
      availableMergeMethods.isNotEmpty) {
    actions.add(
      ExpandableActionButton.enumSelector<PullRequestMergeMethod>(
        icon: Icons.merge_rounded,
        label: 'Merge',
        value: availableMergeMethods.first,
        values: availableMergeMethods,
        onChanged: onMerge,
        labelBuilder: (PullRequestMergeMethod method) => switch (method) {
          PullRequestMergeMethod.MERGE => 'Create a merge commit',
          PullRequestMergeMethod.SQUASH => 'Squash and merge',
          PullRequestMergeMethod.REBASE => 'Rebase and merge',
          _ => method.name,
        },
        iconBuilder: (PullRequestMergeMethod method) => switch (method) {
          PullRequestMergeMethod.MERGE => Icons.merge_rounded,
          PullRequestMergeMethod.SQUASH => Icons.compress_rounded,
          PullRequestMergeMethod.REBASE => Icons.linear_scale_rounded,
          _ => Icons.merge_rounded,
        },
        isPositive: true,
        category: 'State',
        surface: ActionSurface.adaptive,
      ),
    );
  }

  if (viewerCanClose && state == PullRequestState.OPEN) {
    actions.add(
      MajorActionButton(
        icon: Icons.cancel_rounded,
        label: 'Close',
        isDestructive: true,
        onTap: onClose,
        category: 'State',
        surface: ActionSurface.adaptive,
      ),
    );
  }

  if (viewerCanReopen && state == PullRequestState.CLOSED) {
    actions.add(
      MajorActionButton(
        icon: Icons.replay_rounded,
        label: 'Reopen',
        isPositive: true,
        onTap: onReopen,
        category: 'State',
        surface: ActionSurface.adaptive,
      ),
    );
  }

  return actions;
}

// ── Pin / Unpin (Issue) ──

List<ActionButtonData> pinActions({
  required bool isPinned,
  required bool viewerCanPin,
  required VoidCallback onPin,
  required VoidCallback onUnpin,
}) {
  if (!viewerCanPin) return const <ActionButtonData>[];

  return <ActionButtonData>[
    MajorActionButton(
      icon: isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
      label: isPinned ? 'Unpin' : 'Pin',
      onTap: isPinned ? onUnpin : onPin,
      category: 'Manage',
      surface: ActionSurface.adaptive,
    ),
  ];
}

// ── Lock / Unlock (Issue, PR) ──

List<ActionButtonData> lockableActions({
  required bool isLocked,
  required LockReason? activeLockReason,
  required bool viewerCanUpdate,
  required ValueChanged<LockReason> onLock,
  required VoidCallback onUnlock,
}) {
  if (!viewerCanUpdate) return const <ActionButtonData>[];

  if (isLocked) {
    return <ActionButtonData>[
      MajorActionButton(
        icon: Icons.lock_open_rounded,
        label: 'Unlock conversation',
        onTap: onUnlock,
        category: 'Manage',
        surface: ActionSurface.adaptive,
      ),
    ];
  }

  return <ActionButtonData>[
    ExpandableActionButton.enumSelector<LockReason>(
      icon: Icons.lock_rounded,
      label: 'Lock conversation',
      value: LockReason.OFF_TOPIC,
      values: LockReason.values.toList(),
      onChanged: onLock,
      labelBuilder: (LockReason reason) => switch (reason) {
        LockReason.OFF_TOPIC => 'Off-topic',
        LockReason.TOO_HEATED => 'Too heated',
        LockReason.RESOLVED => 'Resolved',
        LockReason.SPAM => 'Spam',
        _ => reason.name,
      },
      category: 'Manage',
      surface: ActionSurface.adaptive,
    ),
  ];
}

// ── Labels (Issue, PR) ──

List<ActionButtonData> labelableActions({
  required int currentLabelCount,
  required bool viewerCanLabel,
  required Widget Function(BuildContext context,
          [ScrollController? scrollController])
      sheetBuilder,
}) {
  if (!viewerCanLabel) return const <ActionButtonData>[];

  return <ActionButtonData>[
    SheetActionButton(
      icon: Icons.label_rounded,
      label: 'Labels',
      subtitle: currentLabelCount > 0 ? '$currentLabelCount selected' : 'None',
      sheetBuilder: sheetBuilder,
      category: 'Manage',
      surface: ActionSurface.adaptive,
    ),
  ];
}

// ── Assignees (Issue, PR) ──

List<ActionButtonData> assignableActions({
  required int currentAssigneeCount,
  required bool viewerCanUpdate,
  required Widget Function(BuildContext context,
          [ScrollController? scrollController])
      sheetBuilder,
}) {
  if (!viewerCanUpdate) return const <ActionButtonData>[];

  return <ActionButtonData>[
    SheetActionButton(
      icon: Icons.person_add_rounded,
      label: 'Assignees',
      subtitle:
          currentAssigneeCount > 0 ? '$currentAssigneeCount assigned' : 'None',
      sheetBuilder: sheetBuilder,
      category: 'Manage',
      surface: ActionSurface.adaptive,
    ),
  ];
}

// ── Milestone (Issue, PR) ──

List<ActionButtonData> milestoneActions({
  required bool hasMilestone,
  required String? milestoneTitle,
  required bool viewerCanUpdate,
  required Widget Function(BuildContext context,
          [ScrollController? scrollController])
      sheetBuilder,
}) {
  if (!viewerCanUpdate) return const <ActionButtonData>[];

  return <ActionButtonData>[
    SheetActionButton(
      icon: Icons.flag_rounded,
      label: 'Milestone',
      subtitle: hasMilestone ? milestoneTitle : 'None',
      sheetBuilder: sheetBuilder,
      category: 'Manage',
      surface: ActionSurface.adaptive,
    ),
  ];
}

// ── Projects (Issue, PR) ──

List<ActionButtonData> projectActions({
  required int currentProjectsCount,
  required bool viewerCanUpdate,
  required Widget Function(BuildContext context,
          [ScrollController? scrollController])
      sheetBuilder,
}) {
  if (!viewerCanUpdate) return const <ActionButtonData>[];

  return <ActionButtonData>[
    SheetActionButton(
      icon: Icons.view_column_rounded,
      label: 'Projects',
      subtitle:
          currentProjectsCount > 0 ? '$currentProjectsCount linked' : 'None',
      sheetBuilder: sheetBuilder,
      category: 'Manage',
      surface: ActionSurface.adaptive,
    ),
  ];
}

// ── Follow / Unfollow (User) ──

List<ActionButtonData> followActions({
  required bool isFollowing,
  required bool viewerCanFollow,
  required VoidCallback onToggle,
  Widget? trailing,
}) {
  if (!viewerCanFollow) return const <ActionButtonData>[];

  return <ActionButtonData>[
    MajorActionButton(
      icon: isFollowing
          ? Icons.person_remove_rounded
          : Icons.person_add_alt_1_rounded,
      label: isFollowing ? 'Unfollow' : 'Follow',
      trailing: trailing,
      isPositive: !isFollowing,
      onTap: onToggle,
      category: 'Social',
    ),
  ];
}

/// Single Block/Unblock action for profile. Use inside [ReactiveActionButton]
/// with [blockStateForUserProvider] to drive [isBlocked] and [isLoading].
ActionButtonData blockAction({
  required bool isBlocked,
  required bool isLoading,
  required void Function(void Function() dismiss) onTapWithDismiss,
}) {
  return MinorActionButton(
    icon: Icons.block,
    label: isLoading ? '…' : (isBlocked ? 'Unblock' : 'Block'),
    trailing: isLoading
        ? const ButtonSpinner(size: 16)
        : null,
    isDestructive: !isBlocked,
    enabled: !isLoading,
    dismissBehavior: ActionDismissBehavior.none,
    onTapWithDismiss: onTapWithDismiss,
  );
}

// ── Utility Actions (all screens) ──

List<ActionButtonData> utilityActions({
  required String url,
  required VoidCallback copyUrl,
  required VoidCallback share,
}) {
  return <ActionButtonData>[
    MinorActionButton(
      icon: Icons.copy_rounded,
      label: 'Copy URL',
      onTap: copyUrl,
    ),
    MinorActionButton(
      icon: Icons.share_rounded,
      label: 'Share',
      onTap: share,
    ),
  ];
}

// ── Repo utility (Compare, Clone, Copy URL, Share) ──

List<ActionButtonData> repoUtilityActions({
  required VoidCallback onCompare,
  required VoidCallback onClone,
  required String url,
  required VoidCallback copyUrl,
  required VoidCallback share,
}) {
  return <ActionButtonData>[
    MinorActionButton(
      icon: Icons.compare_arrows_rounded,
      label: 'Compare',
      onTap: onCompare,
    ),
    MinorActionButton(
      icon: Icons.folder_rounded,
      label: 'Clone',
      onTap: onClone,
    ),
    ...utilityActions(url: url, copyUrl: copyUrl, share: share),
  ];
}

/// Copy SHA action for commit popups.
ActionButtonData copyShaAction({
  required String sha,
  required VoidCallback copySha,
}) =>
    MinorActionButton(
      label: 'Copy SHA',
      icon: Icons.copy_rounded,
      dismissBehavior: ActionDismissBehavior.immediate,
      onTap: copySha,
    );
