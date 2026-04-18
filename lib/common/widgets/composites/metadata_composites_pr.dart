import 'package:diohub/common/cards/issue_pull_card_data.dart';
import 'package:diohub/common/cards/metadata_chips.dart';
import 'package:diohub/common/misc/inline_container.dart';
import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub/common/widgets/composites/metadata_composites_base.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/diff_colors.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class MilestoneProgressCard extends StatelessWidget {
  const MilestoneProgressCard({
    required this.title,
    this.dueDate,
    this.progress,
    this.description,
    this.onTap,
    this.contained = true,
    super.key,
  });

  final String title;
  final String? dueDate;
  final double? progress;
  final String? description;
  final VoidCallback? onTap;
  final bool contained;

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              Octicons.milestone,
              size: 16,
              color: context.colorScheme.primary,
            ),
            spacing.compactGap,
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (dueDate != null) ...<Widget>[
              spacing.compactGap,
              TimestampLabel(date: dueDate!),
            ],
          ],
        ),
        spacing.compactGap,
        if (progress != null) ...<Widget>[
          ClipRRect(
            borderRadius: context.radius(RadiusSize.soft),
            child: LinearProgressIndicator(
              value: progress!.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: context.colorScheme.surfaceContainerHighest,
              valueColor:
                  AlwaysStoppedAnimation<Color>(context.colorScheme.primary),
            ),
          ),
          if (description != null && description!.isNotEmpty)
            spacing.compactGap,
        ],
        if (description != null && description!.isNotEmpty)
          Text(
            description!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant.secondary,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
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

/// Inline release summary (tag, date, badges). Not a card — use [ReleaseCard] from release_card.dart when you have full release data.

class MergeStateBadge extends StatelessWidget {
  const MergeStateBadge({
    required this.mergeStateStatus,
    super.key,
  });

  final CardMergeStateStatus mergeStateStatus;

  static (String label, Color color) _labelAndColor(
    final BuildContext context,
    final CardMergeStateStatus status,
  ) {
    final ColorScheme cs = context.colorScheme;
    switch (status) {
      case CardMergeStateStatus.clean:
        return ('Clean', DiffColors.addition);
      case CardMergeStateStatus.blocked:
        return ('Blocked', cs.error);
      case CardMergeStateStatus.behind:
        return ('Behind', DiffColors.modified);
      case CardMergeStateStatus.unstable:
        return ('Unstable', cs.error);
      case CardMergeStateStatus.dirty:
        return ('Dirty', DiffColors.modified);
      case CardMergeStateStatus.draft:
        return ('Draft', cs.onSurfaceVariant);
      case CardMergeStateStatus.hasHooks:
        return ('Hooks', cs.primary);
      case CardMergeStateStatus.unknown:
        return ('Unknown', cs.onSurfaceVariant);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final (String label, Color color) =
        _labelAndColor(context, mergeStateStatus);
    return StatusBadge(label: label, color: color, icon: Octicons.git_merge);
  }
}

/// Reusable badge: label, color, optional icon. surfaceDecoration(RadiusSize.large, color.subtle, color.borderO).
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    required this.color,
    this.icon,
    super.key,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    return Container(
      padding: spacing.chipPadding,
      decoration: context.surfaceDecoration(
        RadiusSize.large,
        color: color.subtle,
        border: Border.all(color: color.borderO),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: color),
            spacing.tightGap,
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// A contained metadata group card with optional title/subtitle.

class ReviewCoverageRow extends StatelessWidget {
  const ReviewCoverageRow({
    required this.login,
    required this.avatarUrl,
    required this.state,
    this.onTap,
    super.key,
  });

  final String login;
  final String avatarUrl;
  final String state;
  final VoidCallback? onTap;

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    final ColorScheme cs = context.colorScheme;
    final IconData icon = state == 'APPROVED'
        ? Icons.check_circle_rounded
        : state == 'CHANGES_REQUESTED'
            ? Icons.cancel_rounded
            : state == 'COMMENTED'
                ? Icons.chat_bubble_outline_rounded
                : Icons.schedule_rounded;
    final Color color = state == 'APPROVED'
        ? cs.primary
        : state == 'CHANGES_REQUESTED'
            ? cs.error
            : cs.onSurfaceVariant;
    final Widget row = Padding(
      padding: spacing.metadataRowPadding,
      child: Row(
        children: <Widget>[
          UserAvatar(avatarUrl: avatarUrl, size: 24),
          spacing.itemGap,
          Expanded(
            child: Text(
              login,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(icon, size: 18, color: color),
        ],
      ),
    );
    if (onTap != null) {
      return InkWell(onTap: onTap, child: row);
    }
    return row;
  }
}

/// Summary of reviewer states for PR detail; replaces MetadataAvatarStack for reviewers.
class ReviewCoverageSummary extends StatelessWidget {
  const ReviewCoverageSummary({
    required this.rows,
    super.key,
  });

  final List<ReviewCoverageRowData> rows;

  @override
  Widget build(final BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows
          .map(
            (final ReviewCoverageRowData r) => ReviewCoverageRow(
              login: r.login,
              avatarUrl: r.avatarUrl,
              state: r.state,
              onTap: r.onTap,
            ),
          )
          .toList(),
    );
  }
}

/// Data for a single reviewer in ReviewCoverageSummary.
class ReviewCoverageRowData {
  const ReviewCoverageRowData({
    required this.login,
    required this.avatarUrl,
    required this.state,
    this.onTap,
  });

  final String login;
  final String avatarUrl;
  final String state;
  final VoidCallback? onTap;
}

/// Auto-merge detail: avatar + "Auto-merge enabled by @user · METHOD · since DATE".
class AutoMergeDetailCard extends StatelessWidget {
  const AutoMergeDetailCard({
    required this.enabledByLogin,
    this.enabledByAvatarUrl,
    required this.mergeMethod,
    required this.enabledAt,
    super.key,
  });

  final String enabledByLogin;
  final String? enabledByAvatarUrl;
  final String mergeMethod;
  final DateTime enabledAt;

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    final String date = enabledAt.toRelativeDate(shorten: true);
    return Padding(
      padding: spacing.metadataRowPadding,
      child: Row(
        children: <Widget>[
          if (enabledByAvatarUrl != null)
            UserAvatar(avatarUrl: enabledByAvatarUrl!, size: 20),
          if (enabledByAvatarUrl != null) spacing.itemGap,
          Expanded(
            child: Text(
              'Auto-merge enabled by @$enabledByLogin · $mergeMethod · since $date',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant.secondary,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Merge strategies and repo settings: Merge/Squash/Rebase, auto-merge, delete-branch, sign-off.
