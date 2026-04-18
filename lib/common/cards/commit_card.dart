import 'package:diohub/common/cards/branch_refs.dart';
import 'package:diohub/common/cards/card_body_preview.dart';
import 'package:diohub/common/cards/chip_priority.dart';
import 'package:diohub/common/cards/entity_card_layout.dart';
import 'package:diohub/common/cards/inline_metadata_line.dart';
import 'package:diohub/common/cards/issue_pull_card_data.dart';
import 'package:diohub/common/cards/chips/file_composition_bar.dart';
import 'package:diohub/common/cards/metadata_chips.dart';
import 'package:diohub/common/cards/popup_chip_builders.dart';
import 'package:diohub/common/misc/bordered_container.dart'
    show BorderedContainer;
import 'package:diohub/common/misc/list_loading_shimmers.dart'
    show ListLoadingShimmers;
import 'package:diohub_models/models/ci/check_conclusion.dart';
import 'package:diohub/common/popup/popup_button.dart';
import 'package:diohub/common/widgets/metadata_composites.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub/models/commits/commit_list_item_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub/app/settings/card_display.dart';
import 'package:diohub/providers/settings/card_display_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/diff_colors.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_anchor/flutter_anchor.dart' show Placement;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Shared commit row card used in repository Commits tab, Code tab, and PR commits.
///
/// Takes [CommitListItemModel] and optional [branches] (for graph tab). Does not wrap
/// in [BorderedContainer]; the caller provides the card surface.
/// When [highlighted] is true (e.g. current commit in Code tab), uses primary background.
/// Actions (Copy SHA, Copy URL, Share, Open in Browser) are in the peek overlay.
class CommitCard extends ConsumerWidget {
  const CommitCard({
    required this.data,
    this.branches,
    this.highlighted = false,
    this.repoRef,
    this.showRepoName = false,
    this.compact = false,
    super.key,
  });

  final CommitListItemModel data;
  final List<String>? branches;
  final bool highlighted;

  /// When set and [showRepoName] is true, shows repo name (e.g. for cross-repo commit search).
  final RepoRef? repoRef;
  final bool showRepoName;

  /// When true, shows only title + metadataLine + top 2 chips (CI status, verified).
  /// No supplementary (no body preview, no branches, no diff bar).
  final bool compact;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final settings = ref.watch(cardDisplayProvider);
    final String? authorLogin = data.authorLogin;
    final String shortSha =
        data.sha.length >= 7 ? data.sha.substring(0, 7) : data.sha;
    final Color fgColor = highlighted
        ? context.colorScheme.onPrimary
        : context.colorScheme.onSurface;
    final Color variantColor = highlighted
        ? context.colorScheme.onPrimary.withValues(alpha: 0.8)
        : context.colorScheme.onSurfaceVariant;

    // Build title: commit message headline
    final Widget title = Text(
      data.messageHeadline,
      style: context.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: fgColor,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    // Build metadataLine: author + committer (if different) - no SHA, no repo
    final List<InlineMetadataItem> metadataItems = [];
    if (authorLogin != null && authorLogin.isNotEmpty) {
      metadataItems.add(InlineMetadataItem(text: authorLogin));
    }
    if (data.committerLogin != null &&
        data.committerLogin != data.authorLogin) {
      metadataItems.add(InlineMetadataItem(
        text: 'committed by ${data.committerLogin}',
      ));
    }
    final Widget? metadataLine = metadataItems.isNotEmpty
        ? InlineMetadataLine(items: metadataItems)
        : null;

    // Build trailing: timestamp
    final Widget trailing = TimestampLabel(date: data.committedDate.toIso8601String());

    // Build chips with priority
    final allChips = _buildPrioritizedChips(context, ref, settings, shortSha, variantColor);
    final maxVisible = compact ? 2 : settings.effectiveMaxChips;
    final chips = buildChipSection(
      chips: allChips,
      maxVisible: maxVisible,
    );

    // Build supplementary: repo (if showRepoName) + branches + diff bar + body
    Widget? supplementary;
    if (!compact) {
      final hasRepo = showRepoName && repoRef != null;
      final hasBranches = branches != null && branches!.isNotEmpty;
      final hasDiff = settings.showDiffDistribution && _hasDiffStats(data);
      final hasBody = settings.showBodyPreview &&
          data.messageBody != null &&
          data.messageBody!.trim().isNotEmpty;

      if (hasRepo || hasBranches || hasDiff || hasBody) {
        supplementary = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasRepo) ...[
              RepoNameLabel(repo: repoRef!),
              if (hasBranches || hasDiff || hasBody)
                SizedBox(height: context.spacing.tightSpacing),
            ],
            if (hasBranches) ...[
              Wrap(
                spacing: context.spacing.chipGap,
                runSpacing: context.spacing.chipGap,
                children: branches!
                    .map((branch) => BranchRefPill(branchName: branch))
                    .toList(),
              ),
              if (hasDiff || hasBody)
                SizedBox(height: context.spacing.compactSpacing),
            ],
            if (hasDiff) ...[
              PopupButton(
                placement: Placement.bottom,
                buttonBuilder: (c, show) => GestureDetector(
                  onTap: show,
                  child: CommitFileCompositionBar(
                    additions: data.additions ?? 0,
                    deletions: data.deletions ?? 0,
                    changedFiles: data.changedFilesCount,
                  ),
                ),
                popupBuilder: (c, onDismiss) => buildDiffPopupContent(
                  context,
                  onDismiss: onDismiss,
                  additions: data.additions ?? 0,
                  deletions: data.deletions ?? 0,
                  changedFiles: data.changedFilesCount ?? 0,
                  commitsCount: 1,
                  onViewChanges: data.repoOwner != null && data.repoName != null
                      ? () => CommitRef(
                            repo: RepoRef(
                              owner: data.repoOwner!,
                              name: data.repoName!,
                            ),
                            oid: data.sha,
                          ).navigate(context, ref)
                      : null,
                ),
              ),
              if (hasBody) SizedBox(height: context.spacing.itemSpacing),
            ],
            if (hasBody)
              CardBodyPreview(
                body: data.messageBody!,
                repoName: data.repoFullName ?? '',
              ),
          ],
        );
      }
    }

    return EntityCardLayout(
      title: title,
      metadataLine: metadataLine,
      trailing: trailing,
      chips: chips.isNotEmpty ? chips : null,
      supplementary: supplementary,
    );
  }

  List<PrioritizedChip> _buildPrioritizedChips(
    BuildContext context,
    WidgetRef ref,
    CardDisplaySettings settings,
    String shortSha,
    Color variantColor,
  ) {
    return [
      // Critical: SHA
      PrioritizedChip(
        priority: ChipPriority.critical,
        widget: MetadataChip(
          leading: Icon(Octicons.git_commit, size: 12, color: variantColor),
          label: shortSha,
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),

      // Critical: Verification
      if (data.isVerified != null)
        PrioritizedChip(
          priority: ChipPriority.critical,
          widget: _VerifiedChip(
            isVerified: data.isVerified!,
            signerDisplay: data.signerDisplay,
          ),
        ),

      // High: CI checks
      if (settings.showChecksStatus && data.statusCheckRollupState != null)
        PrioritizedChip(
          priority: ChipPriority.high,
          widget: ChecksStatusChip(
            state: _mapCommitCIState(data.statusCheckRollupState!),
          ),
        ),

      // High: Associated PR
      if (data.associatedPRNumber != null &&
          data.repoOwner != null &&
          data.repoName != null)
        PrioritizedChip(
          priority: ChipPriority.high,
          widget: GestureDetector(
            onTap: () => PullRequestRef(
              repo: RepoRef(
                owner: data.repoOwner!,
                name: data.repoName!,
              ),
              number: data.associatedPRNumber!,
            ).navigate(context, ref),
            child: TintedChip(
              color: context.colorScheme.primary,
              icon: Octicons.git_pull_request,
              label: '#${data.associatedPRNumber}',
              iconSize: 12,
            ),
          ),
        ),

      // Medium: Comments
      if (settings.showCommentCount && (data.commentsCount ?? 0) > 0)
        PrioritizedChip(
          priority: ChipPriority.medium,
          widget: CommentsChip(count: data.commentsCount!),
        ),

      // Low: Web commit indicator
      if (data.committedViaWeb == true)
        PrioritizedChip(
          priority: ChipPriority.low,
          widget: const WebCommitIndicator(),
        ),

      // Low: Merge indicator
      if ((data.parentCount ?? 0) > 1)
        PrioritizedChip(
          priority: ChipPriority.low,
          widget: TintedChip(
            color: context.colorScheme.onSurfaceVariant,
            icon: Octicons.git_merge,
            label: 'Merge',
            iconSize: 12,
          ),
        ),
    ];
  }

  static bool _hasDiffStats(final CommitListItemModel d) =>
      (d.additions != null && d.additions! > 0) ||
      (d.deletions != null && d.deletions! > 0) ||
      (d.changedFilesCount != null && d.changedFilesCount! > 0);

  static CardChecksState? _mapCommitCIState(final String state) {
    final conclusion = CheckConclusion.fromString(state);
    switch (conclusion) {
      case CheckConclusion.success:
        return CardChecksState.success;
      case CheckConclusion.failure:
      case CheckConclusion.actionRequired:
        return CardChecksState.failure;
      case CheckConclusion.neutral:
      case CheckConclusion.skipped:
        return CardChecksState.error;
      case CheckConclusion.cancelled:
      case CheckConclusion.timedOut:
      case CheckConclusion.stale:
      case CheckConclusion.startupFailure:
        return CardChecksState.pending;
      default:
        return null;
    }
  }
}

/// Verified/unverified chip with popup showing [VerificationStatusCard] (signer, Signed by GitHub).
class _VerifiedChip extends StatelessWidget {
  const _VerifiedChip({
    required this.isVerified,
    this.signerDisplay,
  });

  final bool isVerified;
  final String? signerDisplay;

  @override
  Widget build(final BuildContext context) {
    final chip = TintedChip(
      color: isVerified ? DiffColors.addition : DiffColors.deletion,
      icon: isVerified ? Octicons.verified : Octicons.unverified,
      label: isVerified ? 'Verified' : 'Unverified',
      iconSize: 12,
    );
    return PopupButton(
      placement: Placement.bottom,
      buttonBuilder: (final BuildContext c, final VoidCallback show) =>
          GestureDetector(onTap: show, child: chip),
      popupBuilder: (final BuildContext c, final VoidCallback onDismiss) =>
          Padding(
        padding: context.spacing.contentPadding,
        child: VerificationStatusCard(
          isVerified: isVerified,
          signer: signerDisplay,
          contained: true,
        ),
      ),
    );
  }
}

/// Skeleton for [CommitCard] used in first-page loading.
/// Use inside ShimmerScope and BorderedContainer (e.g. via [ListLoadingShimmers.commitList]).
class CommitCardSkeleton extends StatelessWidget {
  const CommitCardSkeleton({super.key});

  @override
  Widget build(final BuildContext context) {
    return const EntityCardLayoutSkeleton(
      showMetadataLine: true,
      showTrailing: true,
      showChips: 4,
      showSupplementary: false,
    );
  }
}
