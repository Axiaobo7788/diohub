import 'package:diohub/common/animations/animated_gradient_bar.dart';
import 'package:diohub/common/animations/animated_progress_ring.dart';
import 'package:diohub/common/cards/chips/metadata_chips_base.dart';
import 'package:diohub/common/cards/issue_pull_card_data.dart';
import 'package:diohub/common/cards/mini_avatar_stack.dart';
import 'package:diohub/utils/hex_color.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/diff_colors.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/indicator_utils.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// A chip that displays the comment count for an issue or PR.
///
/// When [createdAt] is provided, applies a heat-based background tint
/// (cold = default, warm = amber, hot = orange/red) via [computeHeat].
class CommentsChip extends StatelessWidget {
  const CommentsChip({
    required this.count,
    this.createdAt,
    this.now,
    super.key,
  });

  final int count;
  final DateTime? createdAt;
  final DateTime? now;

  @override
  Widget build(final BuildContext context) {
    Color? accentColor;
    if (createdAt != null) {
      final ConversationHeat heat = computeHeat(
        commentCount: count,
        createdAt: createdAt!,
        now: now ?? DateTime.now(),
      );
      switch (heat) {
        case ConversationHeat.warm:
          accentColor = Colors.amber;
        case ConversationHeat.hot:
          accentColor = Colors.orange;
        case ConversationHeat.cold:
          break;
      }
    }
    
    return MetadataChip(
      leading: const Icon(Octicons.comment),
      label: '$count',
      accentColor: accentColor,
    );
  }
}

/// An inline comments indicator (icon + count) for use in metadata rows
class InlineCommentsIndicator extends StatelessWidget {
  const InlineCommentsIndicator({
    required this.count,
    super.key,
  });

  final int count;

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          Octicons.comment,
          size: 13,
          color: context.colorScheme.onSurfaceVariant.muted,
        ),
        spacing.tightGap,
        Text(
          '$count',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant.secondary,
              ),
        ),
      ],
    );
  }
}

/// Chip showing PR review decision: Approved, Changes Requested, or Review Required.
class ReviewDecisionChip extends StatelessWidget {
  const ReviewDecisionChip({
    required this.reviewDecision,
    this.showChevron = false,
    super.key,
  });

  final CardReviewDecision? reviewDecision;
  final bool showChevron;

  @override
  Widget build(final BuildContext context) {
    if (reviewDecision == null) {
      return const SizedBox.shrink();
    }
    final AppSpacing spacing = context.spacing;
    final ColorScheme colorScheme = context.colorScheme;
    Color color = colorScheme.onSurfaceVariant;
    IconData icon = Octicons.code_review;
    String label = 'Review Required';
    switch (reviewDecision!) {
      case CardReviewDecision.approved:
        color = Colors.green;
        icon = Octicons.check_circle;
        label = 'Approved';
      case CardReviewDecision.changesRequested:
        color = Colors.red;
        icon = Icons.edit_note_rounded;
        label = 'Changes Requested';
      case CardReviewDecision.reviewRequired:
        color = Colors.amber;
        icon = Octicons.code_review;
        label = 'Review Required';
    }
    return TintedChip(
      color: color,
      icon: icon,
      label: label,
      iconSize: 12,
      padding: spacing.chipPadding,
      gap: spacing.tightSpacing,
      trailing: showChevron
          ? Icon(Icons.expand_more_rounded, size: 10, color: color.muted)
          : null,
    );
  }
}

/// Grouped review chip: stacked avatars + state dots (approved / changes requested / commented).
class ReviewersChip extends StatelessWidget {
  const ReviewersChip({
    required this.reviewerRows,
    this.reviewDecision,
    super.key,
  });

  final List<ReviewReviewerRow> reviewerRows;
  final CardReviewDecision? reviewDecision;

  static Color? _stateColor(final ReviewReviewerRow r) => r.stateColor;

  @override
  Widget build(final BuildContext context) {
    if (reviewerRows.isEmpty) return const SizedBox.shrink();
    final AppSpacing spacing = context.spacing;
    final ColorScheme cs = context.colorScheme;
    final List<String> avatarUrls = reviewerRows
        .map((final ReviewReviewerRow r) => r.avatarUrl ?? '')
        .toList();
    final List<Color?> stateColors =
        reviewerRows.map(ReviewersChip._stateColor).toList();
    final Set<Color?> unique = stateColors.toSet();
    final bool mixed = unique.length > 1;
    final Color? accentColor = mixed
        ? null
        : (reviewDecision != null
            ? switch (reviewDecision!) {
                CardReviewDecision.approved => Colors.green,
                CardReviewDecision.changesRequested => Colors.red,
                CardReviewDecision.reviewRequired => Colors.amber,
              }
            : (stateColors.isNotEmpty && stateColors.first != null
                ? stateColors.first!
                : null));
    const double dotSize = 6;
    final Widget dots = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < stateColors.length && i < 3; i++)
          Padding(
            padding: EdgeInsets.only(
                right: i < stateColors.length - 1
                    ? context.spacing.tightSpacing
                    : 0),
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: stateColors[i] ?? cs.onSurfaceVariant.muted,
              ),
            ),
          ),
      ],
    );
    
    final Widget leading = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        MiniAvatarStack(
          avatarUrls: avatarUrls,
          maxVisible: 3,
          size: 14,
          showExpandIcon: true,
        ),
        spacing.tightGap,
        dots,
      ],
    );
    
    return MetadataChip(
      leading: leading,
      accentColor: accentColor,
    );
  }
}

/// Pure diff stats chip for PR cards
class DiffChip extends StatelessWidget {
  const DiffChip({
    required this.additions,
    required this.deletions,
    this.changedFiles,
    super.key,
  });

  final int additions;
  final int deletions;
  final int? changedFiles;

  @override
  Widget build(final BuildContext context) => DiffDistribution(
        additions: additions,
        deletions: deletions,
        changedFiles: changedFiles,
      );
}

/// Single widget for diff stats: gradient bar-fill background + text row.
/// Wrapped in [AnimatedGradientBar] for grow-in entrance (preset-gated).
class DiffDistribution extends StatelessWidget {
  const DiffDistribution({
    required this.additions,
    required this.deletions,
    this.changedFiles,
    super.key,
  });

  final int additions;
  final int deletions;
  final int? changedFiles;

  @override
  Widget build(final BuildContext context) {
    return Consumer(
      builder: (final BuildContext context, final WidgetRef ref, final _) =>
          AnimatedGradientBar(child: _buildContent(context)),
    );
  }

  Widget _buildContent(final BuildContext context) {
    final int total = additions + deletions;
    final bool hasFiles = changedFiles != null && changedFiles! > 0;
    if (total == 0 && !hasFiles) return const SizedBox.shrink();
    final AppSpacing spacing = context.spacing;
    final TextStyle baseStyle =
        Theme.of(context).textTheme.labelSmall ?? const TextStyle(fontSize: 11);
    final ColorScheme cs = context.colorScheme;
    final Color addColor = DiffColors.addition;
    final Color delColor = DiffColors.deletion;
    final Color mutedColor = cs.onSurfaceVariant.muted;
    final BorderRadius borderRadius = context.radius(RadiusSize.small);

    final bool neutralFill = total == 0 && hasFiles;
    final Decoration decoration;
    if (neutralFill) {
      decoration = BoxDecoration(
        borderRadius: borderRadius,
        color: cs.onSurfaceVariant.withValues(alpha: Opacities.subtle),
      );
    } else {
      final double addFrac = total > 0 ? additions / total : 0.5;
      decoration = BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            addColor.withValues(alpha: Opacities.subtle),
            addColor.withValues(alpha: Opacities.subtle),
            delColor.withValues(alpha: Opacities.subtle),
            delColor.withValues(alpha: Opacities.subtle),
          ],
          stops: <double>[0, addFrac, addFrac, 1],
        ),
      );
    }

    final Widget textRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (additions > 0)
          Text(
            '+${additions.toShortenedStr()}',
            style: baseStyle.copyWith(
              color: addColor.withValues(alpha: Opacities.secondary),
              fontWeight: FontWeight.w500,
            ),
          ),
        if (additions > 0 && (deletions > 0 || hasFiles)) spacing.tightGap,
        if (deletions > 0)
          Text(
            '−${deletions.toShortenedStr()}',
            style: baseStyle.copyWith(
              color: delColor.withValues(alpha: Opacities.secondary),
              fontWeight: FontWeight.w500,
            ),
          ),
        if ((additions > 0 || deletions > 0) && hasFiles) spacing.tightGap,
        if (hasFiles)
          Text(
            '· ${changedFiles!} file${changedFiles == 1 ? '' : 's'}',
            style: baseStyle.copyWith(
              color: mutedColor,
            ),
          ),
      ],
    );

    return Container(
      padding: spacing.chipPadding,
      decoration: decoration,
      child: textRow,
    );
  }
}

/// Chip for sub-issues progress: circular ring + "3/7".
///
/// Ring color: 0% → red, 50% → amber, 100% → green. Entrance uses
/// [AnimatedProgressRing] sweep.
class SubIssueProgressChip extends ConsumerWidget {
  const SubIssueProgressChip({
    required this.completed,
    required this.total,
    this.percentCompleted,
    this.showChevron = false,
    super.key,
  });

  final int completed;
  final int total;
  final double? percentCompleted;
  final bool showChevron;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    if (total <= 0) return const SizedBox.shrink();
    final int completedClamped = completed.clamp(0, total);
    final double progress = total > 0 ? completedClamped / total : 0.0;
    final Color ringColor = _progressColor(progress);
    
    final Widget leading = AnimatedProgressRing(
      value: progress,
      size: 12,
      strokeWidth: 2.5,
      color: ringColor,
      backgroundColor: context.colorScheme.onSurfaceVariant.subtle,
    );
    
    return MetadataChip(
      leading: leading,
      label: '$completed/$total',
      showChevron: showChevron,
    );
  }

  static Color _progressColor(final double t) {
    final double clamped = t.clamp(0.0, 1.0);
    if (clamped < 0.5) {
      return Color.lerp(
        DiffColors.deletion,
        Colors.amber,
        clamped * 2,
      )!;
    }
    return Color.lerp(
      Colors.amber,
      DiffColors.addition,
      (clamped - 0.5) * 2,
    )!;
  }
}

class AutoMergeChip extends StatelessWidget {
  const AutoMergeChip({
    required this.mergeMethod,
    super.key,
  });

  final String mergeMethod;

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    return TintedChip(
      color: DiffColors.addition,
      icon: Octicons.git_merge,
      label: 'Auto-merge ($mergeMethod)',
      iconSize: 12,
      padding: spacing.chipPadding,
      gap: spacing.tightSpacing,
    );
  }
}

class LabelsSummaryChip extends StatelessWidget {
  const LabelsSummaryChip({
    required this.labels,
    this.showChevron = false,
    super.key,
  });

  final List<CardLabel> labels;
  final bool showChevron;

  static Color _parseColor(final String color) =>
      tryParseHexColor(color, fallback: Colors.white) ?? Colors.white;

  @override
  Widget build(final BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    final CardLabel first = labels.first;
    final Color accentColor = _parseColor(first.color);
    final List<Color> leadingColors = labels
        .take(3)
        .map((final CardLabel l) => _parseColor(l.color))
        .toList();
    final int n = labels.length;
    return MetadataChip(
      leading: _multiColorDots(leadingColors, context),
      label: '$n label${n == 1 ? '' : 's'}',
      accentColor: accentColor,
      showChevron: showChevron,
    );
  }

  static Widget _colorDot(final Color color) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      );

  static Widget _multiColorDots(
      final List<Color> colors, final BuildContext context) {
    if (colors.isEmpty) return const SizedBox.shrink();
    if (colors.length == 1) return _colorDot(colors.single);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: colors
          .map(
            (final Color c) => Padding(
              padding: EdgeInsets.only(right: context.spacing.tightSpacing),
              child: _colorDot(c),
            ),
          )
          .toList(),
    );
  }
}

class TrackedChip extends StatelessWidget {
  const TrackedChip({
    required this.count,
    this.showChevron = false,
    super.key,
  });

  final int count;
  final bool showChevron;

  @override
  Widget build(final BuildContext context) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }
    
    return MetadataChip(
      leading: const Icon(Octicons.tasklist),
      label: '$count tracked',
      showChevron: showChevron,
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    this.emoji,
    this.message,
    super.key,
  });

  final String? emoji;
  final String? message;

  @override
  Widget build(final BuildContext context) {
    if (message == null || message!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final Widget? leading = (emoji != null && emoji!.isNotEmpty) 
        ? Text(
            emoji!,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant.strong,
              fontWeight: FontWeight.w500,
            ),
          )
        : null;
    
    return MetadataChip(
      leading: leading,
      label: message,
      textStyle: TextStyle(
        color: context.colorScheme.onSurfaceVariant.strong,
        fontWeight: FontWeight.w500,
      ),
      backgroundOpacity: Opacities.border,
    );
  }
}

class IssueTypeChip extends StatelessWidget {
  const IssueTypeChip({
    required this.name,
    this.colorHex,
    super.key,
  });

  final String name;
  final String? colorHex;

  @override
  Widget build(final BuildContext context) {
    final Color color = colorHex != null && colorHex!.isNotEmpty
        ? tryParseHexColor(colorHex!, fallback: context.colorScheme.primary) ?? context.colorScheme.primary
        : context.colorScheme.primary;
    return TintedChip(
      color: color,
      icon: Octicons.issue_opened,
      label: name,
      iconSize: 12,
    );
  }
}

class CrossRepoBadge extends StatelessWidget {
  const CrossRepoBadge({
    required this.headRepoName,
    super.key,
  });

  final String headRepoName;

  @override
  Widget build(final BuildContext context) {
    return TintedChip(
      color: context.colorScheme.tertiary,
      icon: Octicons.repo_forked,
      label: headRepoName,
      iconSize: 12,
    );
  }
}

class CommitsCountChip extends StatelessWidget {
  const CommitsCountChip({
    required this.count,
    super.key,
  });

  final int count;

  @override
  Widget build(final BuildContext context) {
    return MetadataChip(
      leading: Icon(Octicons.git_commit,
          size: 12, color: context.colorScheme.onSurfaceVariant.strong),
      label: '$count ${count == 1 ? 'commit' : 'commits'}',
    );
  }
}

/// Merge queue position chip
class MergeQueueChip extends StatelessWidget {
  const MergeQueueChip({
    required this.position,
    super.key,
  });

  final int position;

  @override
  Widget build(final BuildContext context) {
    final Color color = context.colorScheme.tertiary;
    return TintedChip(
      color: color,
      icon: Icons.join_inner_rounded,
      label: 'Queue #$position',
      iconSize: 12,
    );
  }
}
