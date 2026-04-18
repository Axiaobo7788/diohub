import 'package:diohub/common/issues/issue_label.dart';
import 'package:diohub/common/misc/entity_header.dart';
import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/popup/popup_section_assemblers.dart';
import 'package:diohub/common/cards/issue_pull_card_data.dart'
    show
        checksStateFromGitHubGql,
        mergeStateFromGitHubGql,
        reviewDecisionFromGitHubGql;
import 'package:diohub/common/widgets/metadata_composites.dart';
import 'package:diohub/common/widgets/metadata_rows.dart';
import 'package:diohub/common/widgets/metadata_section_sliver.dart'
    show MetadataSectionVariant;
import 'package:diohub/common/widgets/status_flag_row.dart';
import 'package:diohub_graphql/fragments/pull_detail_fields.graphql.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/entity_snapshot_factories.dart';
import 'package:diohub_models/models/pagination/unfinished_list.dart';
import 'package:diohub_models/models/visual_state.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/view/issues_pulls/builders/shared_metadata_builders.dart';
import 'package:diohub/common/popup/popup_sections_pull.dart';
import 'package:diohub/view/issues_pulls/widgets/config/pull_capabilities.dart';
import 'package:diohub/view/issues_pulls/widgets/pull_screen_utils.dart';
import 'package:diohub/common/cards/metadata_chips.dart';
import 'package:diohub/common/cards/popup_chip_builders.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:url_launcher/url_launcher.dart';

List<StatusFlag> prStatusFlags(PullInfo data) => <StatusFlag>[
  if (data.locked) StatusFlag.locked,
  if (data.isDraft) StatusFlag.draft,
  if (data.mergeable == MergeableState.CONFLICTING) StatusFlag.conflicts,
];

extension PullInfoStatusFlags on PullInfo {
  List<StatusFlag> get statusFlags => prStatusFlags(this);
}

extension PullInfoEntityConfig on PullInfo {
  EntityConfig toEntityConfig(
    final BuildContext context,
    final WidgetRef ref,
  ) => buildEntityConfig(context, ref, this.toRef, this);
}

EntityConfig buildEntityConfig(
  BuildContext context,
  WidgetRef ref,
  PullRequestRef pullRef,
  PullInfo data,
) {
  final repo = data.repository;
  final closeable = buildCloseableEntityConfig(
    number: data.number,
    state: PrVisualState.fromNames(
      data.pullRequestState.name,
      merged: data.merged,
      isDraft: data.isDraft,
    ),
    statusFlags: data.statusFlags,
  );
  return EntityConfig(
    leading: closeable.leading,
    title: EntityHeader(
      avatarUrl: repo.owner.avatarUrl.toString(),
      title: repo.name,
      subtitle: repo.owner.login,
      avatarSize: 20,
    ),
    subtitle: Text(repo.owner.login),
    statusIndicators: closeable.statusIndicators,
    metadataSections: _buildMetadataSections(context, ref, data, pullRef),
    actionSections: buildPullPopupSections(
      context,
      data,
      ref,
      pullRef,
      capabilities: pullCapabilities(
        context: context,
        ref: ref,
        pullRef: pullRef,
        data: data,
      ),
    ),
  );
}

List<MetadataSectionData> _buildMetadataSections(
  BuildContext context,
  WidgetRef ref,
  PullInfo data,
  PullRequestRef pullRef,
) {
  return <MetadataSectionData>[
    MetadataSectionData(
      title: 'Details',
      icon: Icons.info_outline_rounded,
      variant: MetadataSectionVariant.strong,
      children: _buildDetailsChildren(context, ref, data, pullRef),
    ),
  ];
}

List<Widget> _buildDetailsChildren(
  BuildContext context,
  WidgetRef ref,
  PullInfo data,
  PullRequestRef pullRef,
) {
  final AppSpacing spacing = context.spacing;
  final List<Widget> children = <Widget>[];

  final List<StatusFlag> statusFlags = data.statusFlags;
  final List<Widget> statusChildren = <Widget>[
    buildStatusGroup(
      context,
      number: data.number,
      state: PrVisualState.fromNames(
        data.pullRequestState.name,
        merged: data.merged,
        isDraft: data.isDraft,
      ),
      locked: data.locked,
      isDraft: data.isDraft,
      activeLockReason: data.activeLockReason,
      statusFlags: statusFlags,
    ),
    spacing.compactGap,
    MetadataBranchFlow(
      headRef: data.headRef?.name ?? 'unknown',
      baseRef: data.baseRef?.name ?? 'unknown',
      isCrossRepository: data.isCrossRepository,
      mergeableState: data.mergeable.name,
      repoRef: pullRef.repo,
      defaultBranch: data.baseRef?.name,
      headRefOid: data.headRefOid,
      baseRefOid: data.baseRefOid,
      fromRepoName: data.isCrossRepository && data.headRepository != null
          ? data.headRepository!.nameWithOwner
          : null,
    ),
    if (data.isCrossRepository && data.headRepository != null) ...[
      spacing.compactGap,
      TapFeedback(
        onTap: () => launchUrl(data.headRepository!.url),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.call_split_rounded,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: spacing.tightSpacing),
            Text(
              'From: ${data.headRepository!.nameWithOwner}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
            SizedBox(width: spacing.tightSpacing),
            Text(
              '★ ${data.headRepository!.stargazerCount}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    ],
  ];
  if (data.merged && data.mergedBy != null) {
    statusChildren.add(spacing.compactGap);
    statusChildren.add(
      MergedByAttribution(
        login: data.mergedBy!.login,
        avatarUrl: data.mergedBy!.avatarUrl.toString(),
        mergedAt: data.mergedAt!,
        onTap: () =>
            UserRef(login: data.mergedBy!.login).navigate(context, ref),
      ),
    );
  }
  if (data.merged && data.revertUrl != null) {
    // Revert action is available via premium capabilities
  }
  if (data.isInMergeQueue &&
      data.mergeQueueEntry != null &&
      data.mergeQueueEntry!.position > 0) {
    statusChildren.add(spacing.compactGap);
    statusChildren.add(
      MergeQueueChip(position: data.mergeQueueEntry!.position),
    );
  }
  final bool reviewRequested = data.reviewRequests?.nodes?.isNotEmpty ?? false;
  final String? viewerReviewState = data.viewerLatestReview?.state.name;
  if (data.viewerDidAuthor ||
      reviewRequested ||
      (viewerReviewState != null && viewerReviewState.isNotEmpty)) {
    statusChildren.add(spacing.compactGap);
    statusChildren.add(
      ViewerContextBadges(
        viewerDidAuthor: data.viewerDidAuthor,
        reviewRequested: reviewRequested,
        reviewState: viewerReviewState,
      ),
    );
  }
  children.add(MetadataGroupCard(title: 'Status', children: statusChildren));
  children.add(spacing.sectionGap);

  final List<CICheckRunRowData> ciRuns = ciRunsFromStatusCheckRollup(
    data.statusCheckRollup,
  );
  final Widget checksChip = ChecksStatusChip(
    state: data.statusCheckRollup != null
        ? checksStateFromGitHubGql(data.statusCheckRollup!.state)
        : null,
  );
  final List<Widget> changesChildren = <Widget>[
    DiffDistribution(additions: data.additions, deletions: data.deletions),
    ciRuns.isEmpty
        ? checksChip
        : TapFeedback(
            onTap: () => buildCIChecksBottomSheet(
              context,
              repoRef: pullRef.repo,
              runs: ciRuns,
            ),
            child: checksChip,
          ),
    ReviewDecisionChip(
      reviewDecision: reviewDecisionFromGitHubGql(data.reviewDecision),
    ),
    MergeStateBadge(
      mergeStateStatus: mergeStateFromGitHubGql(data.mergeStateStatus),
    ),
    if (data.mergeable != MergeableState.MERGEABLE)
      TintedChip(
        color: data.canBeRebased
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.errorContainer,
        icon: data.canBeRebased
            ? Octicons.git_branch
            : Icons.warning_amber_rounded,
        label: data.canBeRebased
            ? 'Can be rebased'
            : 'Cannot be rebased — resolve conflicts manually',
        border: true,
      ),
  ];
  final List<String> reviewerAvatars =
      data.reviewRequests?.nodes
          ?.map((PullInfoReviewRequestNode? n) {
            final reviewer = n?.requestedReviewer;
            if (reviewer == null) return null;
            return reviewer.maybeWhen<String?>(
              user: (u) => u.userAvatarUrl.toString(),
              team: (t) => t.teamAvatarUrl?.toString(),
              orElse: () => null,
            );
          })
          .whereType<String>()
          .toList() ??
      <String>[];
  final List<ReviewCoverageRowData> reviewerRows = reviewerCoverageFromPull(
    data,
    context,
    ref,
  );
  if (reviewerAvatars.isNotEmpty) {
    final Widget reviewerChip = MetadataAvatarStack(
      label: 'Reviewers',
      avatars: reviewerAvatars,
      totalCount: reviewerAvatars.length,
    );
    changesChildren.add(
      reviewerRows.isEmpty
          ? reviewerChip
          : TapFeedback(
              onTap: () =>
                  buildReviewersBottomSheet(context, rows: reviewerRows),
              child: reviewerChip,
            ),
    );
  }
  children.add(
    MetadataGroupCard(
      title: 'Changes',
      children: <Widget>[
        Wrap(
          spacing: spacing.compactSpacing,
          runSpacing: spacing.tightSpacing,
          children: changesChildren,
        ),
      ],
    ),
  );
  children.add(spacing.sectionGap);

  final amr = data.autoMergeRequest;
  if (amr != null && amr.enabledAt != null && amr.enabledBy != null) {
    children.add(
      MetadataGroupCard(
        title: 'Merge',
        children: <Widget>[
          AutoMergeDetailCard(
            enabledByLogin: switch (amr.enabledBy!) {
              Fragment$pullDetailFields$autoMergeRequest$enabledBy$$User a =>
                a.login,
              Fragment$pullDetailFields$autoMergeRequest$enabledBy$$Bot a =>
                a.login,
              Fragment$pullDetailFields$autoMergeRequest$enabledBy$$Organization
              a =>
                a.login,
              Fragment$pullDetailFields$autoMergeRequest$enabledBy$$Mannequin
              a =>
                a.login,
              Fragment$pullDetailFields$autoMergeRequest$enabledBy$$EnterpriseUserAccount
              a =>
                a.login,
              Fragment$pullDetailFields$autoMergeRequest$enabledBy() => '',
            },
            enabledByAvatarUrl: switch (amr.enabledBy!) {
              Fragment$pullDetailFields$autoMergeRequest$enabledBy$$User a =>
                a.avatarUrl.toString(),
              Fragment$pullDetailFields$autoMergeRequest$enabledBy$$Bot a =>
                a.avatarUrl.toString(),
              Fragment$pullDetailFields$autoMergeRequest$enabledBy$$Organization
              a =>
                a.avatarUrl.toString(),
              Fragment$pullDetailFields$autoMergeRequest$enabledBy$$Mannequin
              a =>
                a.avatarUrl.toString(),
              Fragment$pullDetailFields$autoMergeRequest$enabledBy$$EnterpriseUserAccount
              a =>
                a.avatarUrl.toString(),
              Fragment$pullDetailFields$autoMergeRequest$enabledBy() => '',
            },
            mergeMethod: amr.mergeMethod.name,
            enabledAt: amr.enabledAt!,
          ),
        ],
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
          children: (data.labels?.nodes ?? <PullLabelNode?>[])
              .whereType<PullLabelNode>()
              .map((n) => IssueLabel.gql(n))
              .toList(),
        ),
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
                .map((PullInfoParticipantNode? e) => e!)
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
            progressPercentage: milestone.progressPercentage,
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
          mergedAt: data.merged ? data.mergedAt : null,
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
  PullInfo data,
) {
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
    linkedPullRequests: data.closingIssuesReferences,
  );
  if (trackingChips.isNotEmpty) {
    trackingChildren.add(MetadataChipWrap(chips: trackingChips));
  }
  return trackingChildren;
}
