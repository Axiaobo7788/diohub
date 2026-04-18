import 'package:diohub/common/cards/metadata_chips.dart';
import 'package:diohub/common/misc/inline_container.dart';
import 'package:diohub/common/widgets/composites/metadata_composites_pr.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/diff_colors.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileBioCard extends StatelessWidget {
  const ProfileBioCard({
    required this.bio,
    super.key,
  });

  final String bio;

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    final ColorScheme cs = context.colorScheme;
    return InlineContainer(
      padding: spacing.cardContentPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.format_quote_rounded,
                size: 14,
                color: cs.primary.muted,
              ),
              spacing.compactGap,
              Text(
                'Bio',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant.strong,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          spacing.compactGap,
          Text(
            bio,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: cs.onSurfaceVariant.secondary,
                ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Inline card for milestone: icon, title, due date, progress bar, optional description.

class ReleaseInlineSummary extends StatelessWidget {
  const ReleaseInlineSummary({
    required this.tagName,
    this.publishedAtIso8601,
    this.description,
    this.isPrerelease = false,
    this.isDraft = false,
    this.onTap,
    this.contained = true,
    super.key,
  });

  final String tagName;
  final String? publishedAtIso8601;
  final String? description;
  final bool isPrerelease;
  final bool isDraft;
  final VoidCallback? onTap;
  final bool contained;

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    final ColorScheme cs = context.colorScheme;
    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              Icons.local_offer_rounded,
              size: 16,
              color: cs.primary,
            ),
            spacing.compactGap,
            Expanded(
              child: Text(
                tagName,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isPrerelease)
              StatusBadge(
                label: 'Pre-release',
                color: cs.tertiary,
              ),
            if (isDraft) ...<Widget>[
              if (isPrerelease) spacing.tightGap,
              StatusBadge(
                label: 'Draft',
                color: cs.onSurfaceVariant,
              ),
            ],
          ],
        ),
        if (publishedAtIso8601 != null) ...<Widget>[
          spacing.compactGap,
          TimestampLabel(date: publishedAtIso8601!, shorten: false),
        ],
        if (description != null && description!.isNotEmpty) ...<Widget>[
          spacing.compactGap,
          Text(
            description!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant.secondary,
                ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
    final Widget wrapped = contained
        ? InlineContainer(
            padding: spacing.cardContentPadding,
            child: content,
          )
        : Padding(
            padding: spacing.metadataRowPadding,
            child: content,
          );
    if (onTap != null) {
      return InkWell(onTap: onTap, child: wrapped);
    }
    return wrapped;
  }
}

/// Card for commit verification: verified/unverified icon + label; optional signer; optional CI row.
class VerificationStatusCard extends StatelessWidget {
  const VerificationStatusCard({
    required this.isVerified,
    this.signer,
    this.ciState,
    this.contained = true,
    super.key,
  });

  final bool isVerified;
  final String? signer;
  final StatusState? ciState;
  final bool contained;

  static String _ciStateLabel(final StatusState state) {
    return switch (state) {
      StatusState.SUCCESS => 'Passing',
      StatusState.FAILURE || StatusState.ERROR => 'Failing',
      StatusState.PENDING || StatusState.EXPECTED => 'Pending',
      StatusState() => 'Pending',
    };
  }

  static Color _ciStateColor(final StatusState state) {
    return switch (state) {
      StatusState.SUCCESS => DiffColors.addition,
      StatusState.FAILURE || StatusState.ERROR => DiffColors.deletion,
      StatusState.PENDING || StatusState.EXPECTED => DiffColors.modified,
      StatusState() => DiffColors.modified,
    };
  }

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    final ColorScheme cs = context.colorScheme;
    final Color color = isVerified ? DiffColors.addition : cs.error;
    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              isVerified ? Octicons.verified : Octicons.unverified,
              size: 16,
              color: color,
            ),
            spacing.tightGap,
            Text(
              isVerified ? 'Verified' : 'Unverified',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        if (signer != null && signer!.isNotEmpty) ...<Widget>[
          spacing.compactGap,
          Text(
            signer!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant.secondary,
                ),
          ),
        ],
        if (ciState != null) ...<Widget>[
          spacing.compactGap,
          Row(
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _ciStateColor(ciState!),
                  shape: BoxShape.circle,
                ),
              ),
              spacing.tightGap,
              Text(
                _ciStateLabel(ciState!),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant.secondary,
                    ),
              ),
            ],
          ),
        ],
      ],
    );
    if (contained) {
      return InlineContainer(
        padding: spacing.cardContentPadding,
        child: content,
      );
    }
    return Padding(
      padding: spacing.metadataRowPadding,
      child: content,
    );
  }
}

/// Color-coded badge for PR merge state (mergeStateStatus). Use instead of boolean mergeable.

class RepoSettingsIndicators extends StatelessWidget {
  const RepoSettingsIndicators({
    this.mergeCommitAllowed,
    this.squashMergeAllowed,
    this.rebaseMergeAllowed,
    this.autoMergeAllowed,
    this.deleteBranchOnMerge,
    this.webCommitSignoffRequired,
    super.key,
  });

  final bool? mergeCommitAllowed;
  final bool? squashMergeAllowed;
  final bool? rebaseMergeAllowed;
  final bool? autoMergeAllowed;
  final bool? deleteBranchOnMerge;
  final bool? webCommitSignoffRequired;

  @override
  Widget build(final BuildContext context) {
    final List<Widget> chips = <Widget>[];
    Widget addChip(final IconData icon, final String label) => TintedChip(
          color: context.colorScheme.primary,
          icon: icon,
          label: label,
          iconSize: 12,
        );
    if (mergeCommitAllowed == true)
      chips.add(addChip(Icons.merge_rounded, 'Merge'));
    if (squashMergeAllowed == true)
      chips.add(addChip(Icons.compress_rounded, 'Squash'));
    if (rebaseMergeAllowed == true)
      chips.add(addChip(Icons.call_split_rounded, 'Rebase'));
    if (autoMergeAllowed == true)
      chips.add(addChip(Icons.auto_awesome_rounded, 'Auto-merge'));
    if (deleteBranchOnMerge == true)
      chips.add(addChip(Icons.delete_outline_rounded, 'Delete branch'));
    if (webCommitSignoffRequired == true)
      chips.add(addChip(Icons.edit_rounded, 'Sign-off'));
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: chips,
    );
  }
}
