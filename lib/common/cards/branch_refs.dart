import 'package:diohub/common/cards/issue_pull_card_data.dart';
import 'package:diohub/common/cards/popup_chip_builders.dart';
import 'package:diohub/common/clipboard/clipboard_service.dart';
import 'package:diohub/common/popup/popup_button.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:auto_route/auto_route.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/diff_colors.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_anchor/flutter_anchor.dart' show Placement;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// A pill-shaped widget displaying a branch reference
class BranchRefPill extends StatelessWidget {
  const BranchRefPill({
    required this.branchName,
    this.repoName,
    super.key,
  });

  final String branchName;
  final String? repoName; // For cross-repo PRs

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    return Container(
      padding: spacing.chipPadding,
      decoration: BoxDecoration(
        color: context.colorScheme.primaryContainer.subtle,
        borderRadius: context.radius(RadiusSize.medium),
        border: Border.all(
          color: context.colorScheme.primary.borderSubtle,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Octicons.git_branch,
            size: 12,
            color: context.colorScheme.primary.strong,
          ),
          spacing.tightGap,
          if (repoName != null) ...<Widget>[
            Flexible(
              child: Text(
                '$repoName:',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.colorScheme.primary.secondary,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            spacing.tightGap,
          ],
          Flexible(
            child: Text(
              branchName,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.primary.secondary,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A pill-shaped widget displaying a tag reference.
class TagRefPill extends StatelessWidget {
  const TagRefPill({required this.tagName, super.key});

  final String tagName;

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    return Container(
      padding: spacing.chipPadding,
      decoration: BoxDecoration(
        color: context.colorScheme.primaryContainer.subtle,
        borderRadius: context.radius(RadiusSize.medium),
        border: Border.all(
          color: context.colorScheme.primary.borderSubtle,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Octicons.tag,
            size: 12,
            color: context.colorScheme.primary.strong,
          ),
          spacing.tightGap,
          Flexible(
            child: Text(
              tagName,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.primary.secondary,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w500,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// A tappable [BranchRefPill] that navigates and shows a contextual popup.
/// Tap → navigate to code browser at this branch.
/// Long-press → popup with Browse / Commits / Compare / Copy.
class InteractiveBranchPill extends ConsumerWidget {
  const InteractiveBranchPill({
    required this.branchName,
    required this.repoRef,
    this.repoName,
    this.defaultBranch,
    super.key,
  });

  final String branchName;
  final RepoRef repoRef;
  final String? repoName;
  final String? defaultBranch;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return PopupButton(
      placement: Placement.bottom,
      buttonBuilder: (final BuildContext c, final VoidCallback showPopup) =>
          GestureDetector(
        onTap: () => _browseAtBranch(context, ref),
        onLongPress: showPopup,
        child: BranchRefPill(
          branchName: branchName,
          repoName: repoName,
        ),
      ),
      popupBuilder: (final BuildContext c, final VoidCallback onDismiss) =>
          buildBranchPopupContent(
        context,
        onDismiss: onDismiss,
        branchName: branchName,
        repoRef: repoRef,
        onBrowseFiles: () => _browseAtBranch(context, ref),
        onViewCommits: () => _viewCommitsAtBranch(context, ref),
        onCompare: defaultBranch != null && branchName != defaultBranch
            ? () => _compareWithDefault(context, ref)
            : null,
        onCopy: () => ref.read(clipboardServiceProvider).copy(branchName),
      ),
    );
  }

  void _browseAtBranch(final BuildContext context, final WidgetRef ref) {
    RepoRef(
      owner: repoRef.owner,
      name: repoRef.name,
      location: RepoLocationTree(branch: branchName),
    ).navigate(context, ref);
  }

  void _viewCommitsAtBranch(final BuildContext context, final WidgetRef ref) {
    RepoRef(
      owner: repoRef.owner,
      name: repoRef.name,
      location: RepoLocationCommits(branch: branchName),
    ).navigate(context, ref);
  }

  void _compareWithDefault(final BuildContext context, final WidgetRef ref) {
    context.router.push(CompareViewRoute(
      repoRef: repoRef,
      base: defaultBranch,
      head: branchName,
    ));
  }
}

/// A tappable [TagRefPill] that navigates and shows a contextual popup.
/// Tap → browse at tag. Long-press → popup with Browse / Compare with previous / Copy.
class InteractiveTagPill extends ConsumerWidget {
  const InteractiveTagPill({
    required this.tagName,
    required this.repoRef,
    this.previousTagName,
    super.key,
  });

  final String tagName;
  final RepoRef repoRef;
  final String? previousTagName;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return PopupButton(
      placement: Placement.bottom,
      buttonBuilder: (final BuildContext c, final VoidCallback showPopup) =>
          GestureDetector(
        onTap: () => _browseAtTag(context, ref),
        onLongPress: showPopup,
        child: TagRefPill(tagName: tagName),
      ),
      popupBuilder: (final BuildContext c, final VoidCallback onDismiss) =>
          buildTagPopupContent(
        context,
        onDismiss: onDismiss,
        tagName: tagName,
        repoRef: repoRef,
        onBrowseFiles: () => _browseAtTag(context, ref),
        onCompareWithPrevious: previousTagName != null
            ? () => context.router.push(CompareViewRoute(
                  repoRef: repoRef,
                  base: previousTagName,
                  head: tagName,
                ))
            : null,
        onCopy: () => ref.read(clipboardServiceProvider).copy(tagName),
      ),
    );
  }

  void _browseAtTag(final BuildContext context, final WidgetRef ref) {
    RepoRef(
      owner: repoRef.owner,
      name: repoRef.name,
      location: RepoLocationTree(branch: tagName),
    ).navigate(context, ref);
  }
}

/// A row displaying branch references with an arrow between them (from → to).
/// When [mergeState] is set and not clean/unknown, shows an inline status icon before the arrow.
/// When [repoRef] is non-null, pills are [InteractiveBranchPill] and tappable.
class BranchRefsRow extends ConsumerWidget {
  const BranchRefsRow({
    this.from,
    this.to,
    this.fromRepoName,
    this.mergeState,
    this.repoRef,
    super.key,
  });

  final String? from;
  final String? to;
  final String? fromRepoName; // Full repo name for head ref when different
  final CardMergeStateStatus? mergeState;
  final RepoRef? repoRef;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    if (from == null && to == null) {
      return const SizedBox.shrink();
    }
    final AppSpacing spacing = context.spacing;
    final bool showMergeIcon = mergeState != null &&
        mergeState != CardMergeStateStatus.clean &&
        mergeState != CardMergeStateStatus.unknown;
    IconData? mergeIcon;
    Color? mergeIconColor;
    if (showMergeIcon) {
      switch (mergeState!) {
        case CardMergeStateStatus.blocked:
        case CardMergeStateStatus.dirty:
          mergeIcon = Octicons.alert;
          mergeIconColor = DiffColors.deletion;
          break;
        case CardMergeStateStatus.behind:
          mergeIcon = Octicons.arrow_down;
          mergeIconColor = DiffColors.modified;
          break;
        case CardMergeStateStatus.unstable:
          mergeIcon = Octicons.alert;
          mergeIconColor = DiffColors.modified;
          break;
        default:
          break;
      }
    }
    final Widget fromPill = from != null
        ? (repoRef != null
            ? InteractiveBranchPill(
                branchName: from!,
                repoRef: repoRef!,
                repoName: fromRepoName,
              )
            : BranchRefPill(
                branchName: from!,
                repoName: fromRepoName,
              ))
        : const SizedBox.shrink();
    final Widget toPill = to != null
        ? (repoRef != null
            ? InteractiveBranchPill(
                branchName: to!,
                repoRef: repoRef!,
              )
            : BranchRefPill(branchName: to!))
        : const SizedBox.shrink();

    return Wrap(
      spacing: spacing.tightSpacing,
      runSpacing: spacing.tightSpacing,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        if (from != null) ...<Widget>[
          fromPill,
          if (showMergeIcon && mergeIcon != null && mergeIconColor != null)
            Icon(mergeIcon, size: 12, color: mergeIconColor),
          if (to != null)
            Icon(
              Octicons.arrow_right,
              size: 12,
              color: context.colorScheme.onSurfaceVariant.muted,
            ),
        ],
        if (to != null) toPill,
      ],
    );
  }
}
