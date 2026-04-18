import 'package:diohub/common/cards/branch_refs.dart';
import 'package:diohub/common/cards/card_body_preview.dart';
import 'package:diohub/common/cards/chip_priority.dart';
import 'package:diohub/common/cards/chips/author_association_badge.dart';
import 'package:diohub/common/cards/chips/ci_check_ratio_chip.dart';
import 'package:diohub/common/cards/chips/review_coverage_bar.dart';
import 'package:diohub/common/cards/chips/time_to_resolution_chip.dart';
import 'package:diohub/common/cards/entity_card_layout.dart';
import 'package:diohub/common/cards/issue_pull_card_data.dart';
import 'package:diohub/common/cards/metadata_chips.dart';
import 'package:diohub/common/cards/popups/popup_chip_template.dart';
import 'package:diohub/common/cards/state_chip.dart';
import 'package:diohub/utils/indicator_utils.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub/common/cards/mini_avatar_stack.dart';
import 'package:diohub/common/cards/popup_chip_builders.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/common/popup/popup_button.dart';
import 'package:diohub/common/utils/github_visual_styles.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart' as gql;

import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub_models/models/visual_state.dart';
import 'package:diohub/app/settings/card_display.dart';
import 'package:diohub/providers/settings/card_display_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_anchor/flutter_anchor.dart' show Placement;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Card for a single issue. Single non-nullable data type: [data].
class IssueCard extends ConsumerWidget {
  const IssueCard(
    this.data, {
    this.showRepoName = true,
    this.showDescription = true,
    this.showTimestamp = true,
    this.useStateColor = true,
    this.displayStateAtEventTime,
    this.compact = false,
    super.key,
  });

  final IssueCardData data;
  final bool showRepoName;
  final bool showDescription;
  final bool showTimestamp;
  final bool useStateColor;
  final VisualState? displayStateAtEventTime;
  final bool compact;

  RepoRef get _repo => data.repo;
  VisualState get _state => data.state;
  bool get _isLocked => data.locked;
  bool get _isPinned => data.isPinned;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final settings = ref.watch(cardDisplayProvider);
    return SizedBox(
      width: double.infinity,
      child: _buildContent(context, settings, ref),
    );
  }

  Color? get stateColor {
    if (!useStateColor) return null;
    final state = displayStateAtEventTime ?? _state;
    if (state is IssueVisualState) {
      return GitHubVisualStyles.fromIssueVisualState(state).color;
    } else if (state is PrVisualState) {
      return GitHubVisualStyles.fromPrVisualState(state).color;
    }
    return null;
  }

  List<PrioritizedChip> _buildPrioritizedIssueChips(
    BuildContext context,
    CardDisplaySettings settings,
    WidgetRef ref,
  ) {
    final DateTime? createdAt = DateTime.tryParse(data.createdAt);
    final DateTime? closedAt =
        data.closedAt != null ? DateTime.tryParse(data.closedAt!) : null;
    final List<CardReactionGroup> reactionList = data.reactionGroups;

    return [
      // Critical: Time to resolution
      if (settings.showTimeToResolution && createdAt != null)
        PrioritizedChip(
          priority: ChipPriority.critical,
          widget: TimeToResolutionChip(
            createdAt: createdAt,
            closedAt: closedAt,
          ),
        ),
      
      // High: Comments (with popup)
      if (data.commentsCount > 0)
        PrioritizedChip(
          priority: ChipPriority.high,
          widget: PopupButton(
            placement: Placement.bottom,
            buttonBuilder: (c, show) => GestureDetector(
              onTap: show,
              child: CommentsChip(
                count: data.commentsCount,
                createdAt: createdAt,
              ),
            ),
            popupBuilder: (c, onDismiss) => buildCommentsPopupContent(
              context,
              onDismiss: onDismiss,
              commentsCount: data.commentsCount,
              reviewThreadsCount: 0,
              onViewComments: () => launchUrl(data.url),
            ),
          ),
        ),

      // High: Linked PRs
      if (data.linkedPRCount > 0)
        PrioritizedChip(
          priority: ChipPriority.high,
          widget: TintedChip(
            color: context.colorScheme.primary,
            icon: Octicons.git_pull_request,
            label: data.linkedPRCount == 1
                ? '1 linked PR'
                : '${data.linkedPRCount} linked PRs',
          ),
        ),

      // High: Sub-issue progress or tracked issues
      if (data.subIssuesSummary.total > 0)
        PrioritizedChip(
          priority: ChipPriority.high,
          widget: PopupButton(
            placement: Placement.bottom,
            buttonBuilder: (c, show) => GestureDetector(
              onTap: show,
              child: SubIssueProgressChip(
                completed: data.subIssuesSummary.completed,
                total: data.subIssuesSummary.total,
                percentCompleted: data.subIssuesSummary.percentCompleted,
                showChevron: true,
              ),
            ),
            popupBuilder: (c, onDismiss) => buildSubIssuePopupContent(
              context,
              onDismiss: onDismiss,
              completed: data.subIssuesSummary.completed,
              total: data.subIssuesSummary.total,
              percentCompleted: data.subIssuesSummary.percentCompleted,
            ),
          ),
        )
      else if (data.trackedIssuesCount > 0)
        PrioritizedChip(
          priority: ChipPriority.high,
          widget: GestureDetector(
            onTap: () => showTrackedIssuesSheet(
              context,
              totalCount: data.trackedIssuesCount,
              items: data.trackedIssues,
              onViewAll: data.trackedIssuesCount > 10 ? () {} : null,
            ),
            child: TrackedChip(count: data.trackedIssuesCount, showChevron: true),
          ),
        ),

      // Medium: Milestone
      if (data.milestone != null)
        PrioritizedChip(
          priority: ChipPriority.medium,
          widget: PopupButton(
            placement: Placement.bottom,
            buttonBuilder: (c, show) => GestureDetector(
              onTap: show,
              child: MetadataChip(
                leading: Icon(Octicons.milestone,
                    size: 12, color: context.colorScheme.primary),
                label: data.milestone!.title,
                showChevron: true,
              ),
            ),
            popupBuilder: (c, onDismiss) => buildMilestonePopupContent(
              context,
              onDismiss: onDismiss,
              title: data.milestone!.title,
              dueDate: data.milestone!.dueOn,
              progress: data.milestone!.progress,
              description: data.milestone!.description,
              openIssues: data.milestone!.openIssues,
              closedIssues: data.milestone!.closedIssues,
            ),
          ),
        ),

      // Medium: Labels summary
      if (data.labels.isNotEmpty)
        PrioritizedChip(
          priority: ChipPriority.medium,
          widget: PopupButton(
            placement: Placement.bottom,
            buttonBuilder: (c, show) => GestureDetector(
              onTap: show,
              child: LabelsSummaryChip(labels: data.labels, showChevron: true),
            ),
            popupBuilder: (c, onDismiss) => buildLabelsPopupContent(
              context,
              onDismiss: onDismiss,
              labels: data.labels,
            ),
          ),
        ),

      // Low: Assignees
      if (data.assigneeAvatarUrls.isNotEmpty)
        PrioritizedChip(
          priority: ChipPriority.low,
          widget: GestureDetector(
            onTap: () => showAssigneesSheet(
              context,
              assigneeNodes: data.assigneeNodes,
            ),
            child: MiniAvatarStack(
              avatarUrls: data.assigneeAvatarUrls,
              labelIcon: Octicons.people,
              showExpandIcon: true,
            ),
          ),
        ),

      // Low: Reactions
      if (settings.showReactions && reactionList.isNotEmpty)
        PrioritizedChip(
          priority: ChipPriority.low,
          widget: PopupButton(
            placement: Placement.bottom,
            buttonBuilder: (c, show) => GestureDetector(
              onTap: show,
              child: ReactionSummaryChip(
                reactionGroups: reactionList,
                showChevron: true,
              ),
            ),
            popupBuilder: (c, onDismiss) => buildReactionPopupContent(
              context,
              onDismiss: onDismiss,
              reactionGroups: reactionList,
            ),
          ),
        ),

      // Low: Projects
      if (settings.showProjectChips && data.projectItems.isNotEmpty)
        ...data.projectItems.map(
          (item) => PrioritizedChip(
            priority: ChipPriority.low,
            widget: GestureDetector(
              onTap: item.url != null
                  ? () => launchUrl(
                      item.url!,
                      mode: LaunchMode.externalApplication,
                    )
                  : null,
              child: MetadataChip(
                leading: Icon(
                  Octicons.project,
                  size: 12,
                  color: context.colorScheme.primary,
                ),
                label: item.title,
                accentColor: context.colorScheme.primary,
              ),
            ),
          ),
        ),
    ];
  }

  Widget _buildContent(final BuildContext context,
      final CardDisplaySettings settings, final WidgetRef ref) {
    // Build titlePrefix: StateChip + icons
    final spacing = context.spacing;
    final titlePrefix = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StateChip(
          number: data.number,
          state: displayStateAtEventTime ?? _state,
          useStateColor: useStateColor,
        ),
        if (_isLocked) ...[
          SizedBox(width: spacing.tightSpacing),
          Icon(
            Octicons.lock,
            size: 12,
            color: context.colorScheme.onSurfaceVariant.hinted,
          ),
        ],
        if (_isPinned) ...[
          SizedBox(width: spacing.tightSpacing),
          Icon(
            Octicons.pin,
            size: 12,
            color: context.colorScheme.onSurfaceVariant.hinted,
          ),
        ],
      ],
    );

    // Build metadataLine: InteractiveAuthorLabel + AuthorAssociationBadge + InteractiveRepoLabel
    final Widget metadataLine = Row(
      children: [
        if (data.author != null) ...[
          InteractiveAuthorLabel(
            login: data.author!.login,
            avatarUrl: data.author!.avatarUrl,
          ),
          if (settings.showAuthorAssociation && data.authorAssociation != null)
            AuthorAssociationBadge(association: data.authorAssociation),
          SizedBox(width: spacing.itemSpacing),
        ],
        if (showRepoName) InteractiveRepoLabel(repo: _repo),
      ],
    );

    // Build trailing timestamp
    final trailing = showTimestamp ? TimestampLabel(date: data.createdAt) : null;

    // Build chips with priority
    final allChips = _buildPrioritizedIssueChips(context, settings, ref);
    final maxVisible = compact ? 2 : settings.effectiveMaxChips;
    final chips = buildChipSection(
      chips: allChips,
      maxVisible: maxVisible,
    );

    // Build supplementary: parent link + body preview
    Widget? supplementary;
    if (!compact) {
      final hasParent = data.parent != null;
      final hasBody = settings.showBodyPreview &&
          showDescription &&
          data.body.trim().isNotEmpty;
      
      if (hasParent || hasBody) {
        supplementary = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasParent)
              Consumer(
                builder: (context, ref, _) => GestureDetector(
                  onTap: () {
                    IssueRef(
                      repo: RepoRef.fromFullName(data.parent!.repoNameWithOwner),
                      number: data.parent!.number,
                    ).navigate(context, ref);
                  },
                  child: Text(
                    'Parent: ${data.parent!.repoNameWithOwner}#${data.parent!.number} ${data.parent!.title}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            if (hasBody) ...[
              if (hasParent) SizedBox(height: context.spacing.compactSpacing),
              CardBodyPreview(
                body: data.body,
                repoName: _repo.fullName,
              ),
            ],
          ],
        );
      }
    }

    return EntityCardLayout(
      titlePrefix: titlePrefix,
      title: Text(
        data.title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: context.colorScheme.onSurface,
        ),
      ),
      timestamp: trailing,
      metadataLine: metadataLine,
      chips: chips.isNotEmpty ? chips : null,
      supplementary: supplementary,
    );
  }
}

/// Card for a single pull request. Single non-nullable data type: [data].
class PullRequestCard extends ConsumerWidget {
  const PullRequestCard(
    this.data, {
    this.showRepoName = true,
    this.showDescription = true,
    this.showTimestamp = true,
    this.useStateColor = true,
    this.branchFrom,
    this.branchTo,
    this.branchFromRepoName,
    this.displayStateAtEventTime,
    this.compact = false,
    super.key,
  });

  final PullRequestCardData data;
  final bool showRepoName;
  final bool showDescription;
  final bool showTimestamp;
  final bool useStateColor;
  final String? branchFrom;
  final String? branchTo;
  final String? branchFromRepoName;
  final VisualState? displayStateAtEventTime;
  final bool compact;

  RepoRef get _repo => data.repo;
  VisualState get _state => data.state;
  bool get _hasBranchRefs => branchFrom != null || branchTo != null;

  bool get _fromDifferentRepo =>
      branchFromRepoName != null && branchFromRepoName != _repo.fullName;

  bool get _isLocked => data.locked;

  Color? get stateColor {
    if (!useStateColor) return null;
    final state = displayStateAtEventTime ?? _state;
    if (state is IssueVisualState) {
      return GitHubVisualStyles.fromIssueVisualState(state).color;
    } else if (state is PrVisualState) {
      return GitHubVisualStyles.fromPrVisualState(state).color;
    }
    return null;
  }

  List<PrioritizedChip> _buildPrioritizedPRChips(
    BuildContext context,
    CardDisplaySettings settings,
    WidgetRef ref,
  ) {
    final Uri prUrl = data.url;
    final DateTime? createdAt = DateTime.tryParse(data.createdAt);
    final DateTime? closedAt =
        data.closedAt != null ? DateTime.tryParse(data.closedAt!) : null;
    final DateTime? mergedAt =
        data.mergedAt != null ? DateTime.tryParse(data.mergedAt!) : null;
    
    return [
      // Critical: Time to resolution
      if (settings.showTimeToResolution && createdAt != null)
        PrioritizedChip(
          priority: ChipPriority.critical,
          widget: TimeToResolutionChip(
            createdAt: createdAt,
            closedAt: closedAt,
            mergedAt: mergedAt,
            isMerged: data.merged,
          ),
        ),

      // Critical: Review coverage bar
      if (settings.showReviewerChip && data.reviewerRows.isNotEmpty)
        PrioritizedChip(
          priority: ChipPriority.critical,
          widget: ReviewCoverageBar(
            summary: summarizeReviews(
              data.reviewerRows
                  .map((r) => r.stateName ?? 'PENDING')
                  .toList(),
            ),
          ),
        ),

      // High: Comments (with popup)
      if (data.commentsCount > 0)
        PrioritizedChip(
          priority: ChipPriority.high,
          widget: PopupButton(
            placement: Placement.bottom,
            buttonBuilder: (c, show) => GestureDetector(
              onTap: show,
              child: CommentsChip(
                count: data.commentsCount,
                createdAt: createdAt,
              ),
            ),
            popupBuilder: (c, onDismiss) => buildCommentsPopupContent(
              context,
              onDismiss: onDismiss,
              commentsCount: data.commentsCount,
              reviewThreadsCount: data.reviewThreadsCount,
              onViewComments: () => launchUrl(prUrl),
            ),
          ),
        ),

      // High: Diff distribution
      if (settings.showDiffDistribution && data.hasDiffStats)
        PrioritizedChip(
          priority: ChipPriority.high,
          widget: PopupButton(
            placement: Placement.bottom,
            buttonBuilder: (c, show) => GestureDetector(
              onTap: show,
              child: DiffChip(
                additions: data.additions,
                deletions: data.deletions,
                changedFiles: data.changedFiles,
              ),
            ),
            popupBuilder: (c, onDismiss) => buildDiffPopupContent(
              context,
              onDismiss: onDismiss,
              additions: data.additions,
              deletions: data.deletions,
              changedFiles: data.changedFiles,
              commitsCount: data.commitsCount,
              onViewChanges: () => launchUrl(prUrl),
            ),
          ),
        ),

      // High: Reviewers
      if (settings.showReviewerChip && data.reviewerRows.isNotEmpty)
        PrioritizedChip(
          priority: ChipPriority.high,
          widget: PopupButton(
            placement: Placement.bottom,
            buttonBuilder: (c, show) => GestureDetector(
              onTap: show,
              child: ReviewersChip(
                reviewerRows: data.reviewerRows,
                reviewDecision: data.reviewDecision,
              ),
            ),
            popupBuilder: (c, onDismiss) => buildReviewDecisionPopupContent(
              context,
              onDismiss: onDismiss,
              reviewers: data.reviewerRows,
              onViewReviews: () => launchUrl(prUrl),
            ),
          ),
        ),

      // High: CI/Checks status
      if (settings.showChecksStatus && data.checksState != null)
        PrioritizedChip(
          priority: ChipPriority.high,
          widget: PopupButton(
            placement: Placement.bottom,
            buttonBuilder: (c, show) => GestureDetector(
              onTap: show,
              child: CICheckRatioChip(
                state: data.checksState,
                totalCount: data.checksTotalCount,
                showChevron: true,
              ),
            ),
            popupBuilder: (c, onDismiss) => buildChecksPopupContent(
              context,
              onDismiss: onDismiss,
              state: data.checksState!,
            ),
          ),
        ),

      // Medium: Auto-merge
      if (data.autoMergeMethod != null)
        PrioritizedChip(
          priority: ChipPriority.medium,
          widget: AutoMergeChip(mergeMethod: data.autoMergeMethod!),
        ),

      // Medium: Merge queue
      if (data.isInMergeQueue)
        PrioritizedChip(
          priority: ChipPriority.medium,
          widget: TintedChip(
            color: Theme.of(context).colorScheme.tertiary,
            icon: Icons.queue_rounded,
            label: data.mergeQueuePosition != null
                ? 'Queue #${data.mergeQueuePosition}'
                : 'In queue',
            iconSize: 12,
          ),
        ),

      // Medium: Merged by
      if (data.merged && data.mergedByLogin != null)
        PrioritizedChip(
          priority: ChipPriority.medium,
          widget: TintedChip(
            color: Theme.of(context).colorScheme.secondary,
            icon: Octicons.git_merge,
            label: 'by ${data.mergedByLogin}',
            iconSize: 12,
          ),
        ),

      // Medium: Cross-repo
      if (data.isCrossRepository)
        PrioritizedChip(
          priority: ChipPriority.medium,
          widget: TintedChip(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            icon: Octicons.repo_forked,
            label: 'Cross-repo',
            iconSize: 12,
          ),
        ),

      // Medium: Milestone
      if (data.milestone != null)
        PrioritizedChip(
          priority: ChipPriority.medium,
          widget: PopupButton(
            placement: Placement.bottom,
            buttonBuilder: (c, show) => GestureDetector(
              onTap: show,
              child: MetadataChip(
                leading: Icon(Octicons.milestone,
                    size: 12, color: context.colorScheme.primary),
                label: data.milestone!.title,
                showChevron: true,
              ),
            ),
            popupBuilder: (c, onDismiss) => buildMilestonePopupContent(
              context,
              onDismiss: onDismiss,
              title: data.milestone!.title,
              dueDate: data.milestone!.dueOn,
              progress: data.milestone!.progress,
              description: data.milestone!.description,
              openIssues: data.milestone!.openIssues,
              closedIssues: data.milestone!.closedIssues,
            ),
          ),
        ),

      // Medium: Labels summary
      if (data.labels.isNotEmpty)
        PrioritizedChip(
          priority: ChipPriority.medium,
          widget: PopupButton(
            placement: Placement.bottom,
            buttonBuilder: (c, show) => GestureDetector(
              onTap: show,
              child: LabelsSummaryChip(labels: data.labels, showChevron: true),
            ),
            popupBuilder: (c, onDismiss) => buildLabelsPopupContent(
              context,
              onDismiss: onDismiss,
              labels: data.labels,
            ),
          ),
        ),

      // Low: Assignees
      if (data.assigneeAvatarUrls.isNotEmpty)
        PrioritizedChip(
          priority: ChipPriority.low,
          widget: GestureDetector(
            onTap: () => showAssigneesSheet(
              context,
              assigneeNodes: data.assigneeNodes,
            ),
            child: MiniAvatarStack(
              avatarUrls: data.assigneeAvatarUrls,
              labelIcon: Octicons.people,
              showExpandIcon: true,
            ),
          ),
        ),

      // Low: Reactions
      if (settings.showReactions && data.reactionGroups.isNotEmpty)
        PrioritizedChip(
          priority: ChipPriority.low,
          widget: PopupButton(
            placement: Placement.bottom,
            buttonBuilder: (c, show) => GestureDetector(
              onTap: show,
              child: ReactionSummaryChip(
                reactionGroups: data.reactionGroups,
                showChevron: true,
              ),
            ),
            popupBuilder: (c, onDismiss) => buildReactionPopupContent(
              context,
              onDismiss: onDismiss,
              reactionGroups: data.reactionGroups,
            ),
          ),
        ),

      // Low: Projects
      if (settings.showProjectChips && data.projectItems.isNotEmpty)
        ...data.projectItems.map(
          (item) => PrioritizedChip(
            priority: ChipPriority.low,
            widget: GestureDetector(
              onTap: item.url != null
                  ? () => launchUrl(
                      item.url!,
                      mode: LaunchMode.externalApplication,
                    )
                  : null,
              child: MetadataChip(
                leading: Icon(
                  Octicons.project,
                  size: 12,
                  color: context.colorScheme.primary,
                ),
                label: item.title,
                accentColor: context.colorScheme.primary,
              ),
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final settings = ref.watch(cardDisplayProvider);
    return SizedBox(
      width: double.infinity,
      child: _buildContent(context, settings, ref),
    );
  }

  Widget _buildContent(final BuildContext context,
      final CardDisplaySettings settings, final WidgetRef ref) {
    // Build titlePrefix: StateChip + lock icon
    final spacing = context.spacing;
    final titlePrefix = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StateChip(
          number: data.number,
          state: displayStateAtEventTime ?? _state,
          useStateColor: useStateColor,
        ),
        if (_isLocked) ...[
          SizedBox(width: spacing.tightSpacing),
          Icon(
            Octicons.lock,
            size: 12,
            color: context.colorScheme.onSurfaceVariant.hinted,
          ),
        ],
      ],
    );

    // Build metadataLine: InteractiveAuthorLabel + AuthorAssociationBadge + InteractiveRepoLabel
    final Widget metadataLine = Row(
      children: [
        if (data.author != null) ...[
          InteractiveAuthorLabel(
            login: data.author!.login,
            avatarUrl: data.author!.avatarUrl,
          ),
          if (settings.showAuthorAssociation && data.authorAssociation != null)
            AuthorAssociationBadge(association: data.authorAssociation),
          SizedBox(width: spacing.itemSpacing),
        ],
        if (showRepoName) InteractiveRepoLabel(repo: _repo),
      ],
    );

    // Build trailing timestamp
    final trailing = showTimestamp ? TimestampLabel(date: data.createdAt) : null;

    // Build chips with priority
    final allChips = _buildPrioritizedPRChips(context, settings, ref);
    final maxVisible = compact ? 2 : settings.effectiveMaxChips;
    final chips = buildChipSection(
      chips: allChips,
      maxVisible: maxVisible,
    );

    // Build supplementary: branch refs + body preview
    Widget? supplementary;
    if (!compact) {
      final hasBranchRefs = settings.showBranchRefs && _hasBranchRefs;
      final hasBody = settings.showBodyPreview &&
          showDescription &&
          data.body.trim().isNotEmpty;
      
      if (hasBranchRefs || hasBody) {
        supplementary = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasBranchRefs)
              BranchRefsRow(
                from: branchFrom,
                to: branchTo,
                fromRepoName: _fromDifferentRepo ? branchFromRepoName : null,
                mergeState: data.mergeStateStatus,
                repoRef: _repo,
              ),
            if (hasBody) ...[
              if (hasBranchRefs) SizedBox(height: context.spacing.compactSpacing),
              CardBodyPreview(
                body: data.body,
                repoName: _repo.fullName,
              ),
            ],
          ],
        );
      }
    }

    return EntityCardLayout(
      titlePrefix: titlePrefix,
      title: Text(
        data.title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: context.colorScheme.onSurface,
        ),
      ),
      timestamp: trailing,
      metadataLine: metadataLine,
      chips: chips.isNotEmpty ? chips : null,
      supplementary: supplementary,
    );
  }
}

/// Convenience: use [IssueCard] or [PullRequestCard] directly when you have
/// [IssueCardData] or [PullCardData]. These factories forward to them.
abstract final class IssuePullCard {
  IssuePullCard._();

  static Widget fromIssue(
    final gql.IssueCardData gqlData, {
    final bool showRepoName = true,
    final bool showDescription = true,
    final bool showTimestamp = true,
    final bool useStateColor = true,
    final VisualState? displayStateAtEventTime,
    final bool compact = false,
  }) =>
      IssueCard(
        IssueCardData.fromGitHubGql(gqlData),
        showRepoName: showRepoName,
        showDescription: showDescription,
        showTimestamp: showTimestamp,
        useStateColor: useStateColor,
        displayStateAtEventTime: displayStateAtEventTime,
        compact: compact,
      );

  static Widget fromPullRequest(
    final gql.PullCardData gqlData, {
    final bool showRepoName = true,
    final bool showDescription = true,
    final bool showTimestamp = true,
    final bool useStateColor = true,
    final String? branchFrom,
    final String? branchTo,
    final String? branchFromRepoName,
    final VisualState? displayStateAtEventTime,
    final bool compact = false,
  }) =>
      PullRequestCard(
        PullRequestCardData.fromGitHubGql(gqlData),
        showRepoName: showRepoName,
        showDescription: showDescription,
        showTimestamp: showTimestamp,
        useStateColor: useStateColor,
        branchFrom: branchFrom,
        branchTo: branchTo,
        branchFromRepoName: branchFromRepoName,
        displayStateAtEventTime: displayStateAtEventTime,
        compact: compact,
      );
}

/// Loading card for issues/pull requests
class IssuePullLoadingCard extends StatelessWidget {
  const IssuePullLoadingCard({
    this.showRepoName = true,
    this.showDescription = true,
    super.key,
  });

  final bool showRepoName;
  final bool showDescription;

  @override
  Widget build(final BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ShimmerScope(
        child: EntityCardLayoutSkeleton(
          showPrefix: true,
          showTrailing: true,
          showMetadataLine: true,
          showChips: 3,
          showSupplementary: showDescription,
        ),
      ),
    );
  }
}
