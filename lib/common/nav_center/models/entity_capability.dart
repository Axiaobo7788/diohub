import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/nav_center/models/entity_action_defs.dart';
import 'package:diohub/common/nav_center/settings/settings_destructive_row.dart';
import 'package:diohub/common/nav_center/settings/settings_enum_row.dart';
import 'package:diohub/common/nav_center/settings/settings_sheet_action_row.dart';
import 'package:diohub/common/nav_center/settings/settings_toggle_row.dart';
import 'package:diohub_graphql/schema_typedefs.dart';

/// Type alias for sheet body builders used by tracking and batch actions.
typedef SheetBuilder =
    Widget Function(BuildContext context, [ScrollController? scrollController]);

/// Groups capabilities into logical sections for the settings tab.
/// The renderer creates one SettingsSection per group that has at least one visible capability.
enum CapabilityGroup {
  state('State', Icons.swap_horiz_rounded),
  notifications('Notifications', Icons.notifications_outlined),
  tracking('Tracking', Icons.label_outlined),
  moderation('Moderation', Icons.shield_outlined),
  merge('Merge', Icons.merge_rounded),
  danger('Danger zone', Icons.warning_amber_rounded),
  utility('', Icons.more_horiz_rounded);

  const CapabilityGroup(this.displayName, this.icon);
  final String displayName;
  final IconData icon;
}

/// A single capability that an entity possesses (e.g. "lockable", "trackable").
///
/// Each subclass carries its current state + mutation callbacks and knows
/// how to render itself on every action surface:
///   • popup menu (via [popupActions])
///   • settings tab (via [settingsWidgets])
///   • batch selection bar (via [batchActions])
///
/// Entity screens compose a `List<EntityCapability>` from the entity data,
/// then pass the list to generic surface renderers.
abstract class EntityCapability {
  const EntityCapability();

  /// Which SettingsSection this capability's settings widgets belong to.
  CapabilityGroup get group;

  /// Whether this capability should be rendered at all.
  /// Typically driven by viewer permissions.
  bool get isVisible;

  /// Actions for the popup menu. Empty list = nothing rendered.
  List<ActionButtonData> get popupActions;

  /// Widgets for the settings tab. Empty list = nothing rendered.
  /// Each widget should be a SettingsRow subclass (SettingsToggleRow, SettingsEnumRow, etc.).
  List<Widget> settingsWidgets(BuildContext context);

  /// Actions for batch operations via [SelectionDockPill]. Null = not batchable.
  List<ActionButtonData>? get batchActions => null;
}

// ─── Subscribable (notifications) ─────────────────────────────────────────

final class Subscribable extends EntityCapability {
  const Subscribable({
    required this.currentState,
    required this.viewerCanSubscribe,
    required this.onChanged,
  });

  final SubscriptionState currentState;
  final bool viewerCanSubscribe;
  final void Function(SubscriptionState) onChanged;

  @override
  CapabilityGroup get group => CapabilityGroup.notifications;

  @override
  bool get isVisible => viewerCanSubscribe;

  @override
  List<ActionButtonData> get popupActions => subscribableActions(
    currentState: currentState,
    viewerCanSubscribe: viewerCanSubscribe,
    onChanged: onChanged,
  );

  @override
  List<Widget> settingsWidgets(BuildContext context) {
    return [
      SettingsEnumRow<SubscriptionState>(
        label: 'Subscription',
        leadingIcon: Octicons.bell,
        value: currentState,
        options: [
          EnumOption<SubscriptionState>(
            value: SubscriptionState.SUBSCRIBED,
            label: 'All activity',
            icon: Icons.notifications_active_rounded,
          ),
          EnumOption<SubscriptionState>(
            value: SubscriptionState.UNSUBSCRIBED,
            label: 'Participating',
            icon: Icons.notifications_outlined,
          ),
          EnumOption<SubscriptionState>(
            value: SubscriptionState.IGNORED,
            label: 'Ignore',
            icon: Icons.notifications_off_rounded,
          ),
        ],
        onMutate: (SubscriptionState v) async => onChanged(v),
      ),
    ];
  }
}

// ─── Trackable (labels, assignees, milestone, projects) ───────────────────

final class Trackable extends EntityCapability {
  const Trackable({
    required this.viewerCanUpdate,
    required this.labelsSheetBuilder,
    required this.assigneesSheetBuilder,
    required this.milestoneSheetBuilder,
    required this.projectsSheetBuilder,
    required this.labelCount,
    required this.assigneeCount,
    required this.milestoneTitle,
    required this.projectsCount,
  });

  final bool viewerCanUpdate;
  final SheetBuilder labelsSheetBuilder;
  final SheetBuilder assigneesSheetBuilder;
  final SheetBuilder milestoneSheetBuilder;
  final SheetBuilder projectsSheetBuilder;
  final int labelCount;
  final int assigneeCount;
  final String? milestoneTitle;
  final int projectsCount;

  @override
  CapabilityGroup get group => CapabilityGroup.tracking;

  @override
  bool get isVisible => viewerCanUpdate;

  @override
  List<ActionButtonData> get popupActions => [
    ...labelableActions(
      currentLabelCount: labelCount,
      viewerCanLabel: viewerCanUpdate,
      sheetBuilder: labelsSheetBuilder,
    ),
    ...assignableActions(
      currentAssigneeCount: assigneeCount,
      viewerCanUpdate: viewerCanUpdate,
      sheetBuilder: assigneesSheetBuilder,
    ),
    ...milestoneActions(
      hasMilestone: milestoneTitle != null,
      milestoneTitle: milestoneTitle,
      viewerCanUpdate: viewerCanUpdate,
      sheetBuilder: milestoneSheetBuilder,
    ),
    ...projectActions(
      currentProjectsCount: projectsCount,
      viewerCanUpdate: viewerCanUpdate,
      sheetBuilder: projectsSheetBuilder,
    ),
  ];

  @override
  List<Widget> settingsWidgets(BuildContext context) => [
    SettingsSheetActionRow(
      label: 'Labels',
      leadingIcon: Octicons.tag,
      subtitle: labelCount > 0 ? '$labelCount selected' : null,
      onTap: () async => AppSheet.scrollable<void>(
        context,
        header: AppSheetHeader.text('Labels'),
        bodyBuilder: (BuildContext ctx, _, ScrollController sc) =>
            labelsSheetBuilder(ctx, sc),
      ),
    ),
    SettingsSheetActionRow(
      label: 'Assignees',
      leadingIcon: Octicons.person,
      subtitle: assigneeCount > 0 ? '$assigneeCount assigned' : null,
      onTap: () async => AppSheet.scrollable<void>(
        context,
        header: AppSheetHeader.text('Assignees'),
        bodyBuilder: (BuildContext ctx, _, ScrollController sc) =>
            assigneesSheetBuilder(ctx, sc),
      ),
    ),
    SettingsSheetActionRow(
      label: 'Milestone',
      leadingIcon: Octicons.milestone,
      subtitle: milestoneTitle,
      onTap: () async => AppSheet.scrollable<void>(
        context,
        header: AppSheetHeader.text('Milestone'),
        bodyBuilder: (BuildContext ctx, _, ScrollController sc) =>
            milestoneSheetBuilder(ctx, sc),
      ),
    ),
    SettingsSheetActionRow(
      label: 'Projects',
      leadingIcon: Octicons.project,
      onTap: () async => AppSheet.scrollable<void>(
        context,
        header: AppSheetHeader.text('Projects'),
        bodyBuilder: (BuildContext ctx, _, ScrollController sc) =>
            projectsSheetBuilder(ctx, sc),
      ),
    ),
  ];

  @override
  List<ActionButtonData>? get batchActions => [
    SheetActionButton(
      icon: Octicons.tag,
      label: 'Add labels',
      sheetBuilder: labelsSheetBuilder,
      category: 'Batch',
    ),
    SheetActionButton(
      icon: Icons.remove_circle_outline_rounded,
      label: 'Remove labels',
      sheetBuilder: labelsSheetBuilder,
      category: 'Batch',
    ),
    SheetActionButton(
      icon: Octicons.person,
      label: 'Add assignees',
      sheetBuilder: assigneesSheetBuilder,
      category: 'Batch',
    ),
    SheetActionButton(
      icon: Icons.person_remove_rounded,
      label: 'Remove assignees',
      sheetBuilder: assigneesSheetBuilder,
      category: 'Batch',
    ),
    SheetActionButton(
      icon: Octicons.milestone,
      label: 'Milestone',
      sheetBuilder: milestoneSheetBuilder,
      category: 'Batch',
    ),
  ];
}

// ─── CloseableIssue ────────────────────────────────────────────────────────

final class CloseableIssue extends EntityCapability {
  const CloseableIssue({
    required this.state,
    required this.viewerCanClose,
    required this.viewerCanReopen,
    required this.onClose,
    required this.onReopen,
  });

  final IssueState state;
  final bool viewerCanClose;
  final bool viewerCanReopen;
  final void Function(IssueClosedStateReason?) onClose;
  final VoidCallback onReopen;

  @override
  CapabilityGroup get group => CapabilityGroup.state;

  @override
  bool get isVisible => viewerCanClose || viewerCanReopen;

  @override
  List<ActionButtonData> get popupActions => closeableIssueActions(
    state: state,
    viewerCanClose: viewerCanClose,
    viewerCanReopen: viewerCanReopen,
    onClose: onClose,
    onReopen: onReopen,
  );

  @override
  List<Widget> settingsWidgets(BuildContext context) => const [];

  @override
  List<ActionButtonData>? get batchActions => [
    if (state == IssueState.OPEN && viewerCanClose)
      MinorActionButton(
        icon: Icons.close_rounded,
        label: 'Close',
        isDestructive: true,
        onTap: () => onClose(IssueClosedStateReason.COMPLETED),
      ),
    if (state == IssueState.CLOSED && viewerCanReopen)
      MinorActionButton(
        icon: Icons.replay_rounded,
        label: 'Reopen',
        isPositive: true,
        onTap: onReopen,
      ),
  ];
}

// ─── CloseablePull ────────────────────────────────────────────────────────

final class CloseablePull extends EntityCapability {
  const CloseablePull({
    required this.state,
    required this.viewerCanClose,
    required this.viewerCanReopen,
    required this.mergeableState,
    required this.onClose,
    required this.onReopen,
    required this.onMerge,
    required this.availableMergeMethods,
  });

  final PullRequestState state;
  final bool viewerCanClose;
  final bool viewerCanReopen;
  final MergeableState? mergeableState;
  final VoidCallback onClose;
  final VoidCallback onReopen;
  final void Function(PullRequestMergeMethod) onMerge;
  final List<PullRequestMergeMethod> availableMergeMethods;

  @override
  CapabilityGroup get group => CapabilityGroup.state;

  @override
  bool get isVisible => viewerCanClose || viewerCanReopen;

  @override
  List<ActionButtonData> get popupActions => closeablePullActions(
    state: state,
    viewerCanClose: viewerCanClose,
    viewerCanReopen: viewerCanReopen,
    mergeableState: mergeableState,
    onClose: onClose,
    onReopen: onReopen,
    onMerge: onMerge,
    availableMergeMethods: availableMergeMethods,
  );

  @override
  List<Widget> settingsWidgets(BuildContext context) => const [];

  @override
  List<ActionButtonData>? get batchActions => [
    if (state == PullRequestState.OPEN && viewerCanClose)
      MinorActionButton(
        icon: Icons.close_rounded,
        label: 'Close',
        isDestructive: true,
        onTap: onClose,
      ),
    if (state == PullRequestState.CLOSED && viewerCanReopen)
      MinorActionButton(
        icon: Icons.replay_rounded,
        label: 'Reopen',
        isPositive: true,
        onTap: onReopen,
      ),
  ];
}

// ─── Lockable ──────────────────────────────────────────────────────────────

final class Lockable extends EntityCapability {
  const Lockable({
    required this.isLocked,
    required this.activeLockReason,
    required this.viewerCanUpdate,
    required this.onLock,
    required this.onUnlock,
    this.showLockReasonPicker,
  });

  final bool isLocked;
  final LockReason? activeLockReason;
  final bool viewerCanUpdate;
  final void Function(LockReason) onLock;
  final VoidCallback onUnlock;
  final Future<LockReason?> Function(BuildContext)? showLockReasonPicker;

  @override
  CapabilityGroup get group => CapabilityGroup.moderation;

  @override
  bool get isVisible => viewerCanUpdate;

  @override
  List<ActionButtonData> get popupActions => lockableActions(
    isLocked: isLocked,
    activeLockReason: activeLockReason,
    viewerCanUpdate: viewerCanUpdate,
    onLock: onLock,
    onUnlock: onUnlock,
  );

  @override
  List<Widget> settingsWidgets(BuildContext context) => [
    SettingsToggleRow(
      label: isLocked ? 'Locked' : 'Lock conversation',
      leadingIcon: Octicons.lock,
      value: isLocked,
      onMutate: (bool v) async {
        if (v) {
          final LockReason? reason = await showLockReasonPicker?.call(context);
          if (reason == null) throw StateError('cancelled');
          onLock(reason);
        } else {
          onUnlock();
        }
      },
    ),
  ];

  @override
  List<ActionButtonData>? get batchActions => [
    MinorActionButton(
      icon: Icons.lock_rounded,
      label: 'Lock',
      onTap: () => onLock(LockReason.OFF_TOPIC),
    ),
    MinorActionButton(
      icon: Icons.lock_open_rounded,
      label: 'Unlock',
      onTap: onUnlock,
    ),
  ];
}

// ─── Pinnable (issue only) ─────────────────────────────────────────────────

final class Pinnable extends EntityCapability {
  const Pinnable({
    required this.isPinned,
    required this.viewerCanPin,
    required this.onToggle,
  });

  final bool isPinned;
  final bool viewerCanPin;
  final VoidCallback onToggle;

  @override
  CapabilityGroup get group => CapabilityGroup.moderation;

  @override
  bool get isVisible => viewerCanPin;

  @override
  List<ActionButtonData> get popupActions => pinActions(
    isPinned: isPinned,
    viewerCanPin: viewerCanPin,
    onPin: onToggle,
    onUnpin: onToggle,
  );

  @override
  List<Widget> settingsWidgets(BuildContext context) => [
    SettingsToggleRow(
      label: isPinned ? 'Pinned' : 'Pin',
      leadingIcon: Octicons.pin,
      value: isPinned,
      onMutate: (_) async => onToggle(),
    ),
  ];
}

// ─── Reviewable (PR only) ──────────────────────────────────────────────────

final class Reviewable extends EntityCapability {
  const Reviewable({required this.viewerCanUpdate, required this.sheetBuilder});

  final bool viewerCanUpdate;
  final SheetBuilder sheetBuilder;

  @override
  CapabilityGroup get group => CapabilityGroup.tracking;

  @override
  bool get isVisible => viewerCanUpdate;

  @override
  List<ActionButtonData> get popupActions => const [];

  @override
  List<Widget> settingsWidgets(BuildContext context) => [
    SettingsSheetActionRow(
      label: 'Request review',
      leadingIcon: Octicons.eye,
      onTap: () async => AppSheet.scrollable<void>(
        context,
        header: AppSheetHeader.text('Request review'),
        bodyBuilder: (BuildContext ctx, _, ScrollController sc) =>
            sheetBuilder(ctx, sc),
      ),
    ),
  ];
}

// ─── Mergeable (PR only) ───────────────────────────────────────────────────

final class Mergeable extends EntityCapability {
  const Mergeable({
    required this.canEnableAutoMerge,
    required this.canDisableAutoMerge,
    required this.autoMergeEnabled,
    required this.isMerged,
    required this.headRefName,
    required this.viewerCanDeleteHeadRef,
    required this.onToggleAutoMerge,
    required this.onDeleteBranch,
    required this.pullState,
  });

  final bool canEnableAutoMerge;
  final bool canDisableAutoMerge;
  final bool autoMergeEnabled;
  final bool isMerged;
  final String? headRefName;
  final bool viewerCanDeleteHeadRef;
  final VoidCallback onToggleAutoMerge;
  final VoidCallback onDeleteBranch;
  final PullRequestState pullState;

  @override
  CapabilityGroup get group => CapabilityGroup.merge;

  @override
  bool get isVisible => _hasVisibleChildren;

  bool get _hasVisibleChildren =>
      (pullState == PullRequestState.OPEN &&
          (canEnableAutoMerge || canDisableAutoMerge)) ||
      (isMerged && headRefName != null && viewerCanDeleteHeadRef);

  @override
  List<ActionButtonData> get popupActions => const [];

  @override
  List<Widget> settingsWidgets(BuildContext context) => [
    if (pullState == PullRequestState.OPEN &&
        (canEnableAutoMerge || canDisableAutoMerge))
      SettingsToggleRow(
        label: 'Auto-merge',
        leadingIcon: Icons.auto_mode_rounded,
        value: autoMergeEnabled,
        onMutate: (_) async => onToggleAutoMerge(),
      ),
    if (isMerged && headRefName != null && viewerCanDeleteHeadRef)
      SettingsDestructiveRow(
        label: 'Delete branch',
        leadingIcon: Octicons.git_branch,
        confirmTitle: 'Delete branch "$headRefName"?',
        confirmExplanation: 'This cannot be undone.',
        onMutate: (_) async => onDeleteBranch(),
      ),
  ];
}

// ─── DangerZone (issue only) ───────────────────────────────────────────────

final class DangerZone extends EntityCapability {
  const DangerZone({required this.children});

  /// List of SettingsDestructiveRow widgets (transfer, delete, etc.).
  final List<Widget> children;

  @override
  CapabilityGroup get group => CapabilityGroup.danger;

  @override
  bool get isVisible => children.isNotEmpty;

  @override
  List<ActionButtonData> get popupActions => const [];

  @override
  List<Widget> settingsWidgets(BuildContext context) => children;
}

// ─── Utility (all entities) ───────────────────────────────────────────────

final class Utility extends EntityCapability {
  const Utility({
    required this.url,
    required this.copyUrl,
    required this.share,
  });

  final String url;
  final VoidCallback copyUrl;
  final VoidCallback share;

  @override
  CapabilityGroup get group => CapabilityGroup.utility;

  @override
  bool get isVisible => true;

  @override
  List<ActionButtonData> get popupActions =>
      utilityActions(url: url, copyUrl: copyUrl, share: share);

  @override
  List<Widget> settingsWidgets(BuildContext context) => const [];
}

// ─── RepoUtility (repo only) ───────────────────────────────────────────────

final class RepoUtility extends EntityCapability {
  const RepoUtility({
    required this.onCompare,
    required this.onClone,
    required this.url,
    required this.copyUrl,
    required this.share,
  });

  final VoidCallback onCompare;
  final VoidCallback onClone;
  final String url;
  final VoidCallback copyUrl;
  final VoidCallback share;

  @override
  CapabilityGroup get group => CapabilityGroup.utility;

  @override
  bool get isVisible => true;

  @override
  List<ActionButtonData> get popupActions => repoUtilityActions(
    onCompare: onCompare,
    onClone: onClone,
    url: url,
    copyUrl: copyUrl,
    share: share,
  );

  @override
  List<Widget> settingsWidgets(BuildContext context) => const [];
}

// ─── Followable (profile only) ──────────────────────────────────────────────

final class Followable extends EntityCapability {
  const Followable({
    required this.isFollowing,
    required this.viewerCanFollow,
    required this.onToggle,
    this.trailing,
  });

  final bool isFollowing;
  final bool viewerCanFollow;
  final VoidCallback onToggle;
  final Widget? trailing;

  @override
  CapabilityGroup get group => CapabilityGroup.state;

  @override
  bool get isVisible => viewerCanFollow;

  @override
  List<ActionButtonData> get popupActions => followActions(
    isFollowing: isFollowing,
    viewerCanFollow: viewerCanFollow,
    onToggle: onToggle,
    trailing: trailing,
  );

  @override
  List<Widget> settingsWidgets(BuildContext context) => const [];
}

// ─── Blockable (profile only) ───────────────────────────────────────────────

final class Blockable extends EntityCapability {
  const Blockable({
    required this.isBlocked,
    required this.isLoading,
    required this.onTapWithDismiss,
  });

  final bool isBlocked;
  final bool isLoading;
  final void Function(VoidCallback dismiss) onTapWithDismiss;

  @override
  CapabilityGroup get group => CapabilityGroup.moderation;

  @override
  bool get isVisible => true;

  @override
  List<ActionButtonData> get popupActions => [
    blockAction(
      isBlocked: isBlocked,
      isLoading: isLoading,
      onTapWithDismiss: onTapWithDismiss,
    ),
  ];

  @override
  List<Widget> settingsWidgets(BuildContext context) => const [];
}
