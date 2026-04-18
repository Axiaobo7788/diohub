import 'package:diohub/common/issues/issue_label.dart';
import 'package:diohub/common/misc/entity_header.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/popup/popup_sections_issue.dart';
import 'package:diohub/common/popup/popup_section_assemblers.dart';
import 'package:diohub/common/widgets/metadata_composites.dart';
import 'package:diohub/common/widgets/metadata_rows.dart';
import 'package:diohub/common/widgets/metadata_section_sliver.dart';
import 'package:diohub/common/widgets/status_flag_row.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub/utils/hex_color.dart';
import 'package:diohub/common/cards/metadata_chips.dart';
import 'package:diohub/common/cards/branch_refs.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_graphql/fragments/issue_detail_fields.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/entity_snapshot_factories.dart';
import 'package:diohub_models/models/pagination/unfinished_list.dart';
import 'package:diohub_models/models/visual_state.dart';
import 'package:diohub/providers/issue_pulls/issue_field_providers.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/view/issues_pulls/builders/shared_metadata_builders.dart';
import 'package:diohub/view/issues_pulls/widgets/config/issue_capabilities.dart';
import 'package:diohub/view/issues_pulls/widgets/config/issue_capabilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

List<StatusFlag> issueStatusFlags(IssueInfo data) => <StatusFlag>[
  if (data.locked) StatusFlag.locked,
  if (data.isPinned == true) StatusFlag.pinned,
];

extension IssueInfoStatusFlags on IssueInfo {
  List<StatusFlag> get statusFlags => issueStatusFlags(this);
}

extension IssueInfoEntityConfig on IssueInfo {
  EntityConfig toEntityConfig(
    final BuildContext context,
    final WidgetRef ref,
  ) => buildEntityConfig(context, ref, this.toRef, this);
}

EntityConfig buildEntityConfig(
  BuildContext context,
  WidgetRef ref,
  IssueRef issueRef,
  IssueInfo data,
) {
  final repo = data.repository;
  final closeable = buildCloseableEntityConfig(
    number: data.number,
    state: IssueVisualState.fromNames(
      data.issueState.name,
      reasonName: data.stateReason?.name,
    ),
    statusFlags: data.statusFlags,
  );

  // Combine status indicators with issue type chip if present
  final Widget statusIndicators;
  if (data.issueType case final issueType?) {
    final spacing = context.spacing;
    statusIndicators = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        closeable.statusIndicators,
        spacing.compactGap,
        IssueTypeChip(
          name: issueType.name,
          colorHex: _issueTypeColorHex(issueType.color),
        ),
      ],
    );
  } else {
    statusIndicators = closeable.statusIndicators;
  }

  return EntityConfig(
    leading: closeable.leading,
    title: EntityHeader(
      avatarUrl: repo.owner.avatarUrl.toString(),
      title: repo.name,
      subtitle: repo.owner.login,
      avatarSize: 20,
    ),
    subtitle: Text(repo.owner.login),
    statusIndicators: statusIndicators,
    metadataSections: _buildMetadataSections(context, data, ref),
    actionSections: buildIssuePopupSections(
      context,
      data,
      ref,
      issueRef,
      capabilities: issueCapabilities(
        context: context,
        ref: ref,
        issueRef: issueRef,
        data: data,
      ),
    ),
  );
}

List<MetadataSectionData> _buildMetadataSections(
  BuildContext context,
  IssueInfo data,
  WidgetRef ref,
) {
  return <MetadataSectionData>[
    MetadataSectionData(
      title: 'Details',
      icon: Icons.info_outline_rounded,
      variant: MetadataSectionVariant.strong,
      children: _buildDetailsChildren(context, data, ref),
    ),
  ];
}

String? _issueTypeColorHex(final IssueTypeColor? color) {
  if (color == null) return null;
  return switch (color) {
    IssueTypeColor.BLUE => '3B82F6',
    IssueTypeColor.GRAY => '6B7280',
    IssueTypeColor.GREEN => '22C55E',
    IssueTypeColor.ORANGE => 'F97316',
    IssueTypeColor.PINK => 'EC4899',
    IssueTypeColor.PURPLE => '8B5CF6',
    IssueTypeColor.RED => 'EF4444',
    _ => null,
  };
}

List<Widget> _buildDetailsChildren(
  BuildContext context,
  IssueInfo data,
  WidgetRef ref,
) {
  final AppSpacing spacing = context.spacing;
  final List<Widget> children = <Widget>[];

  final List<StatusFlag> statusFlags = data.statusFlags;
  children.add(
    MetadataGroupCard(
      title: 'Status',
      children: <Widget>[
        buildStatusGroup(
          context,
          number: data.number,
          state: IssueVisualState.fromNames(
            data.issueState.name,
            reasonName: data.stateReason?.name,
          ),
          locked: data.locked,
          isPinned: data.isPinned == true,
          stateReasonName: data.stateReason?.name,
          activeLockReason: data.activeLockReason,
          statusFlags: statusFlags,
        ),
        if (data.viewerDidAuthor) ...[
          spacing.compactGap,
          ViewerContextBadges(viewerDidAuthor: true),
        ],
        if (data.lastEditedAt case final editedAt?) ...[
          spacing.compactGap,
          EditedIndicator(
            editedAt: editedAt,
            editorLogin: data.editor == null
                ? null
                : switch (data.editor!) {
                    Fragment$issueDetailFields$editor$$User a => a.login,
                    Fragment$issueDetailFields$editor$$Bot a => a.login,
                    Fragment$issueDetailFields$editor$$Organization a =>
                      a.login,
                    Fragment$issueDetailFields$editor$$Mannequin a => a.login,
                    Fragment$issueDetailFields$editor$$EnterpriseUserAccount
                    a =>
                      a.login,
                    Fragment$issueDetailFields$editor() => '',
                  },
            editorAvatarUrl: data.editor == null
                ? null
                : switch (data.editor!) {
                    Fragment$issueDetailFields$editor$$User a =>
                      a.avatarUrl.toString(),
                    Fragment$issueDetailFields$editor$$Bot a =>
                      a.avatarUrl.toString(),
                    Fragment$issueDetailFields$editor$$Organization a =>
                      a.avatarUrl.toString(),
                    Fragment$issueDetailFields$editor$$Mannequin a =>
                      a.avatarUrl.toString(),
                    Fragment$issueDetailFields$editor$$EnterpriseUserAccount
                    a =>
                      a.avatarUrl.toString(),
                    Fragment$issueDetailFields$editor() => '',
                  },
          ),
        ],
      ],
    ),
  );
  children.add(spacing.sectionGap);

  // Issue type chip now shown in header statusIndicators, removed from here

  final summary = data.subIssuesSummary;
  if (summary.total > 0) {
    children.add(
      Padding(
        padding: spacing.metadataRowPadding,
        child: MetadataChip(
          leading: const Icon(Octicons.checklist, size: 12),
          label:
              '${summary.completed}/${summary.total} sub-issues (${summary.percentCompleted}%)',
        ),
      ),
    );
    children.add(spacing.sectionGap);
  }

  final parentIssue = data.parent;
  if (parentIssue != null) {
    final theme = Theme.of(context);
    final parentRef = IssueRef(
      repo: RepoRef.fromFullName(parentIssue.repository.nameWithOwner),
      number: parentIssue.number,
    );
    children.add(
      Padding(
        padding: spacing.metadataRowPadding,
        child: InkWell(
          onTap: () => parentRef.navigate(context, ref),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Octicons.issue_opened,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                spacing.compactGap,
                Text(
                  'Sub-issue of #${parentIssue.number}',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    children.add(spacing.sectionGap);
  }

  if (data.labels?.nodes?.isNotEmpty ?? false) {
    children.add(
      Padding(
        padding: spacing.metadataRowPadding,
        child: Wrap(
          spacing: spacing.compactSpacing,
          runSpacing: spacing.tightSpacing,
          children: () {
            final nodes = data.labels?.nodes;
            if (nodes case final list?) {
              return list
                  .whereType<IssueLabelNode>()
                  .map(IssueLabel.gql)
                  .toList();
            }
            return <Widget>[];
          }(),
        ),
      ),
    );
    children.add(spacing.sectionGap);
  }

  // Issue fields (structured metadata)
  final issueRef = IssueRef(
    repo: RepoRef(
      owner: data.repository.owner.login,
      name: data.repository.name,
    ),
    number: data.number,
  );
  final fieldValuesAsync = ref.watch(issueFieldValuesProvider(issueRef));
  if (fieldValuesAsync.hasValue && fieldValuesAsync.value!.isNotEmpty) {
    children.add(
      MetadataGroupCard(
        title: 'Fields',
        children: <Widget>[
          Wrap(
            spacing: spacing.compactSpacing,
            runSpacing: spacing.tightSpacing,
            children: fieldValuesAsync.value!.map((fieldValue) {
              // For single-select fields
              if (fieldValue.selectedOption != null) {
                final option = fieldValue.selectedOption!;
                final Color color =
                    option.color != null && option.color!.isNotEmpty
                    ? tryParseHexColor(
                            option.color!,
                            fallback: Theme.of(context).colorScheme.primary,
                          ) ??
                          Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primary;
                return TintedChip(
                  color: color,
                  label: option.name,
                  iconSize: 12,
                );
              }
              // For text/number/date fields
              if (fieldValue.value != null) {
                return MetadataChip(
                  leading: const Icon(Icons.tag, size: 12),
                  label: fieldValue.value!,
                );
              }
              return const SizedBox.shrink();
            }).toList(),
          ),
        ],
      ),
    );
    children.add(spacing.sectionGap);
  }

  children.add(
    MetadataGroupCard(
      title: 'People',
      children: <Widget>[
        buildPeopleGroup(
          context,
          ref,
          createdBy: data.author,
          authorAssociation: data.authorAssociation,
          participantsInfo: UnfinishedList<Actor>(
            limitedAvailableList: data.participants.nodes!
                .map((IssueInfoParticipantNode? e) => e!)
                .toList(),
            totalCount: data.participants.totalCount,
          ),
          assigneesNodes:
              data.assignees.nodes?.whereType<Actor>().toList() ?? <Actor>[],
          assigneesTotalCount: data.assignees.nodes?.length ?? 0,
        ),
      ],
    ),
  );
  children.add(spacing.sectionGap);

  if (data.milestone != null) {
    final milestone = data.milestone!;
    children.add(
      MetadataGroupCard(
        title: 'Milestone',
        children: <Widget>[
          buildMilestoneCard(
            title: milestone.title,
            dueOnIso8601: milestone.dueOn?.toIso8601String(),
            progressPercentage: null,
            description: milestone.description,
          ),
        ],
      ),
    );
    children.add(spacing.sectionGap);
  }

  final List<Widget> trackingChildren = _buildTrackingChildren(
    context,
    ref,
    data,
  );
  if (trackingChildren.isNotEmpty) {
    children.add(
      MetadataGroupCard(
        title: 'Tracking',
        children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: trackingChildren,
          ),
        ],
      ),
    );
    children.add(spacing.sectionGap);
  }

  children.add(
    MetadataGroupCard(
      title: 'Timeline',
      children: <Widget>[
        buildTimestampsRow(
          createdAt: data.createdAt,
          updatedAt: data.updatedAt,
          closedAt: data.closedAt,
        ),
        if (data.comments.totalCount > 0) ...[
          context.spacing.itemGap,
          CommentsChip(count: data.comments.totalCount),
        ],
      ],
    ),
  );

  return children;
}

List<Widget> _buildTrackingChildren(
  BuildContext context,
  WidgetRef ref,
  IssueInfo data,
) {
  final AppSpacing spacing = context.spacing;
  final List<Widget> trackingChildren = <Widget>[];
  if (data.projectsV2.totalCount > 0) {
    trackingChildren.add(
      MetadataRow(
        icon: Octicons.project,
        label: 'Projects',
        child: Text('${data.projectsV2.totalCount}'),
      ),
    );
  }
  final List<MetadataChipData> trackingChips = buildTrackingChips(
    context,
    ref,
    linkedIssues: data.trackedIssues,
    linkedIssuesTrackedIn: data.trackedInIssues,
  );
  final List<Widget> branchChips =
      data.linkedBranches.edges
          ?.whereType<IssueLinkedBranchEdge>()
          .where((e) => e.node?.ref != null)
          .map((e) => BranchRefPill(branchName: e.node!.ref!.name))
          .toList() ??
      <Widget>[];
  if (trackingChips.isNotEmpty || branchChips.isNotEmpty) {
    trackingChildren.add(
      Wrap(
        spacing: spacing.compactSpacing,
        runSpacing: spacing.tightSpacing,
        children: <Widget>[
          if (trackingChips.isNotEmpty) MetadataChipWrap(chips: trackingChips),
          ...branchChips,
        ],
      ),
    );
  }
  return trackingChildren;
}
