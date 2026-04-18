import 'package:diohub/common/cards/state_chip.dart';
import 'package:diohub/common/issues/lock_reason_display_name.dart';
import 'package:diohub_models/models/pagination/unfinished_list.dart';
import 'package:diohub/common/widgets/status_flag_row.dart';
import 'package:diohub/common/widgets/metadata_rows.dart';
import 'package:diohub/common/widgets/metadata_composites.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub_models/models/visual_state.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

// ---------------------------------------------------------------------------
// People group (returns Widget; wrap in MetadataSectionSliver("Details") by caller)
// ---------------------------------------------------------------------------

Widget buildPeopleGroup(
  final BuildContext context,
  final WidgetRef ref, {
  required final Actor? createdBy,
  final CommentAuthorAssociation? authorAssociation,
  required final UnfinishedList<Actor> participantsInfo,
  final List<Actor>? assigneesNodes,
  final int assigneesTotalCount = 0,
}) {
  final List<Widget> rows = <Widget>[];

  if (createdBy != null) {
    rows.add(
      MetadataUserRow(
        label: 'Author',
        avatarUrl: createdBy.avatarUrl.toString(),
        login: createdBy.login,
        association: authorAssociation != null &&
                authorAssociation != CommentAuthorAssociation.NONE
            ? authorAssociation.name
            : null,
        onTap: () => UserRef(login: createdBy.login).navigate(context, ref),
      ),
    );
  }

  final List<Actor> assigneeList = assigneesNodes ?? <Actor>[];
  final int totalCount = assigneesTotalCount;
  if (assigneeList.isNotEmpty) {
    if (assigneeList.length == 1) {
      final Actor a = assigneeList.first;
      rows.add(
        MetadataUserRow(
          label: 'Assignee',
          avatarUrl: a.avatarUrl.toString(),
          login: a.login,
          onTap: () => UserRef(login: a.login).navigate(context, ref),
        ),
      );
    } else {
      rows.add(
        MetadataAvatarStack(
          label: 'Assignees',
          avatars: assigneeList
              .map((final Actor e) => e.avatarUrl.toString())
              .toList(),
          totalCount: totalCount,
        ),
      );
    }
  }

  if (participantsInfo.totalCount > 1) {
    rows.add(
      MetadataAvatarStack(
        label: 'Participants',
        avatars: participantsInfo.limitedAvailableList
            .map((final Actor e) => e.avatarUrl.toString())
            .toList(),
        totalCount: participantsInfo.totalCount,
      ),
    );
  }

  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: rows,
  );
}

// ---------------------------------------------------------------------------
// Tracking section (linked issues / PRs)
// ---------------------------------------------------------------------------

List<MetadataChipData> buildTrackingChips(
  final BuildContext context,
  final WidgetRef ref, {
  final IssueTrackedIssues? linkedIssues,
  final IssueTrackedInIssues? linkedIssuesTrackedIn,
  final PullClosingIssuesRefs? linkedPullRequests,
}) {
  final List<MetadataChipData> chips = <MetadataChipData>[];

  if ((linkedIssues?.totalCount ?? 0) > 0) {
    final List<IssueTrackedIssueNode> nodes =
        linkedIssues!.nodes?.whereType<IssueTrackedIssueNode>().toList() ??
            <IssueTrackedIssueNode>[];
    for (final IssueTrackedIssueNode node in nodes) {
      chips.add(
        MetadataChipData(
          label: '#${node.number} ${node.title}',
          color: Colors.green,
          onTap: () => IssueRef(
            repo: RepoRef(
              owner: node.repository.owner.login,
              name: node.repository.name,
            ),
            number: node.number,
          ).navigate(context, ref),
        ),
      );
    }
  }

  if ((linkedIssuesTrackedIn?.totalCount ?? 0) > 0) {
    final List<IssueTrackedInIssueNode> nodes = linkedIssuesTrackedIn!.nodes
            ?.whereType<IssueTrackedInIssueNode>()
            .toList() ??
        <IssueTrackedInIssueNode>[];
    for (final IssueTrackedInIssueNode node in nodes) {
      chips.add(
        MetadataChipData(
          label: 'in #${node.number} ${node.title}',
          color: Colors.blue,
          onTap: () => IssueRef(
            repo: RepoRef(
              owner: node.repository.owner.login,
              name: node.repository.name,
            ),
            number: node.number,
          ).navigate(context, ref),
        ),
      );
    }
  }

  if ((linkedPullRequests?.totalCount ?? 0) > 0) {
    final List<PullClosingIssueRefNode> nodes = linkedPullRequests!.nodes
            ?.whereType<PullClosingIssueRefNode>()
            .toList() ??
        <PullClosingIssueRefNode>[];
    for (final PullClosingIssueRefNode node in nodes) {
      chips.add(
        MetadataChipData(
          label: 'Closes #${node.number}',
          color: Colors.deepPurple,
          onTap: () => IssueRef(
            repo: RepoRef(
              owner: node.repository.owner.login,
              name: node.repository.name,
            ),
            number: node.number,
          ).navigate(context, ref),
        ),
      );
    }
  }

  return chips;
}

Widget? buildTrackingGroup(
  final BuildContext context,
  final WidgetRef ref, {
  final IssueTrackedIssues? linkedIssues,
  final IssueTrackedInIssues? linkedIssuesTrackedIn,
  final PullClosingIssuesRefs? linkedPullRequests,
}) {
  final List<MetadataChipData> chips = buildTrackingChips(
    context,
    ref,
    linkedIssues: linkedIssues,
    linkedIssuesTrackedIn: linkedIssuesTrackedIn,
    linkedPullRequests: linkedPullRequests,
  );
  if (chips.isEmpty) return null;

  return MetadataChipWrap(chips: chips);
}

// ---------------------------------------------------------------------------
// Closeable entity config (shared leading + status indicators for EntityConfig)
// ---------------------------------------------------------------------------

/// Returns [leading] (StateChip) and [statusIndicators] (StatusFlagRow) for
/// issue/PR entity config. Wire into [EntityConfig].
({Widget leading, Widget statusIndicators}) buildCloseableEntityConfig({
  required int number,
  required VisualState state,
  required List<StatusFlag> statusFlags,
}) {
  return (
    leading: StateChip(number: number, state: state, useStateColor: true),
    statusIndicators: StatusFlagRow(flags: statusFlags),
  );
}

// ---------------------------------------------------------------------------
// Status section (issue/PR: state chip + lock/pin)
// ---------------------------------------------------------------------------

Widget buildStatusGroup(
  final BuildContext context, {
  required final int number,
  required final VisualState state,
  final bool locked = false,
  final bool isPinned = false,
  final bool isDraft = false,
  final String? stateReasonName,
  final LockReason? activeLockReason,
  final List<StatusFlag> statusFlags = const <StatusFlag>[],
}) {
  final List<Widget> children = <Widget>[
    StateChip(number: number, state: state, useStateColor: true),
    if (locked || isPinned || isDraft) ...<Widget>[
      context.spacing.tightGap,
      if (locked)
        Icon(
          Octicons.lock,
          size: 12,
          color: context.colorScheme.onSurfaceVariant.muted,
        ),
      if (isPinned) ...[
        context.spacing.tightGap,
        Icon(
          Octicons.pin,
          size: 12,
          color: context.colorScheme.onSurfaceVariant.muted,
        ),
      ],
      if (isDraft) ...[
        context.spacing.tightGap,
        Icon(
          Octicons.git_pull_request_draft,
          size: 12,
          color: context.colorScheme.onSurfaceVariant.muted,
        ),
      ],
    ],
  ];
  final List<Widget> statusTexts = <Widget>[
    if (stateReasonName != null && stateReasonName.isNotEmpty)
      Padding(
        padding: EdgeInsets.only(top: context.spacing.compactSpacing),
        child: Text(
          stateReasonName,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant.secondary,
              ),
        ),
      ),
    if (locked && activeLockReason != null)
      Padding(
        padding: EdgeInsets.only(top: context.spacing.compactSpacing),
        child: Text(
          'Lock reason: ${lockReasonDisplayName(activeLockReason)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant.secondary,
              ),
        ),
      ),
  ];
  final List<Widget> columnChildren = <Widget>[
    Row(children: children),
    ...statusTexts,
  ];
  if (statusFlags.isNotEmpty) {
    columnChildren.add(context.spacing.tightGap);
    columnChildren.add(
      StatusFlagRow(
        flags: statusFlags,
        compact: false,
      ),
    );
  }
  return Padding(
    padding: context.spacing.metadataRowPadding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: columnChildren,
    ),
  );
}

// ---------------------------------------------------------------------------
// Milestone section (MilestoneProgressCard)
// ---------------------------------------------------------------------------

Widget buildMilestoneCard({
  required final String title,
  final String? dueOnIso8601,
  final double? progressPercentage,
  final String? description,
  final VoidCallback? onTap,
}) {
  return MilestoneProgressCard(
    title: title,
    dueDate: dueOnIso8601,
    progress: progressPercentage != null ? progressPercentage / 100 : null,
    description: description,
    onTap: onTap,
    contained: false,
  );
}

// ---------------------------------------------------------------------------
// Timestamps / Timeline section
// ---------------------------------------------------------------------------

Widget buildTimestampsRow({
  required final DateTime createdAt,
  final DateTime? updatedAt,
  final DateTime? closedAt,
  final DateTime? mergedAt,
}) {
  final List<TimestampEntry> timestamps = <TimestampEntry>[
    TimestampEntry(label: 'Created', date: createdAt),
    if (updatedAt != null) TimestampEntry(label: 'Updated', date: updatedAt),
    if (mergedAt != null) TimestampEntry(label: 'Merged', date: mergedAt),
    if (closedAt != null) TimestampEntry(label: 'Closed', date: closedAt),
  ];
  return MetadataTimestampRow(timestamps: timestamps);
}
