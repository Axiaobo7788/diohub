import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/cards/branch_refs.dart';
import 'package:diohub/common/cards/metadata_chips.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/pulls/mergeable_state.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MetadataBranchFlow extends ConsumerWidget {
  const MetadataBranchFlow({
    required this.headRef,
    required this.baseRef,
    this.isCrossRepository = false,
    this.fromRepoName,
    this.headRefOid,
    this.baseRefOid,
    this.mergeableState,
    this.padding,
    this.repoRef,
    this.defaultBranch,
    super.key,
  });

  final String headRef;
  final String baseRef;
  final bool isCrossRepository;
  final String? fromRepoName;
  final String? headRefOid;
  final String? baseRefOid;
  final String? mergeableState;
  final EdgeInsetsGeometry? padding;
  final RepoRef? repoRef;
  final String? defaultBranch;

  Color _mergeColor(final ColorScheme cs) {
    if (mergeableState == null) return cs.onSurfaceVariant;
    final state = MergeableState.fromString(mergeableState!);
    switch (state) {
      case MergeableState.mergeable:
        return cs.primary;
      case MergeableState.conflicting:
        return cs.error;
      default:
        return cs.onSurfaceVariant;
    }
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final AppSpacing spacing = context.spacing;
    final Color mergeColor = _mergeColor(colorScheme);
    final EdgeInsetsGeometry effectivePadding =
        padding ?? spacing.metadataRowPadding;

    final Widget headPill = repoRef != null
        ? InteractiveBranchPill(
            branchName: headRef,
            repoRef: repoRef!,
            repoName: isCrossRepository ? fromRepoName : null,
            defaultBranch: defaultBranch,
          )
        : BranchRefPill(
            branchName: headRef,
            repoName: isCrossRepository ? fromRepoName : null,
          );
    final Widget basePill = repoRef != null
        ? InteractiveBranchPill(
            branchName: baseRef,
            repoRef: repoRef!,
            defaultBranch: defaultBranch,
          )
        : BranchRefPill(branchName: baseRef);

    return Padding(
      padding: effectivePadding,
      child: Row(
        children: <Widget>[
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                headPill,
                if (headRefOid != null) ...[
                  spacing.tightGap,
                  BranchSHAPill(sha: headRefOid!),
                ],
              ],
            ),
          ),
          spacing.itemGap,
          if (repoRef != null)
            GestureDetector(
              onTap: () => context.router.push(CompareViewRoute(
                repoRef: repoRef!,
                base: baseRef,
                head: headRef,
              )),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: mergeColor.strong,
              ),
            )
          else
            Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: mergeColor.strong,
            ),
          spacing.itemGap,
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                basePill,
                if (baseRefOid != null) ...[
                  spacing.tightGap,
                  BranchSHAPill(sha: baseRefOid!),
                ],
              ],
            ),
          ),
          if (isCrossRepository) ...<Widget>[
            spacing.itemGap,
            Icon(
              Icons.call_split_rounded,
              size: 14,
              color: colorScheme.onSurfaceVariant.muted,
            ),
          ],
          if (mergeableState != null) ...<Widget>[
            const Spacer(),
            Container(
              padding: context.spacing.badgePadding,
              decoration: BoxDecoration(
                color: mergeColor.subtle,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                mergeableState == 'MERGEABLE'
                    ? 'Mergeable'
                    : mergeableState == 'CONFLICTING'
                        ? 'Conflicts'
                        : 'Unknown',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: mergeColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Displays a user with avatar, login, and optional association badge.
/// Optional [trailing] is rendered after login with Spacer + itemGap.
