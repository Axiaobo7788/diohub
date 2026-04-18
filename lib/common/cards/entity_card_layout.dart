import 'package:diohub/common/misc/shimmer_bone.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// Standardized card layout template for all entity cards.
///
/// Enforces consistent visual spacing, typography hierarchy, and slot structure:
/// - titlePrefix + title (titleSmall w600) + trailing
/// - metadataLine (bodySmall secondary, 4px below title)
/// - chips Wrap (6px below metadata, chipGap spacing)
/// - supplementary content (8px below chips)
///
/// Gaps collapse when slots are null.
class EntityCardLayout extends StatelessWidget {
  const EntityCardLayout({
    this.titlePrefix,
    required this.title,
    this.timestamp,
    this.trailing,
    this.metadataLine,
    this.chips,
    this.supplementary,
    super.key,
  });

  /// Optional widget to the left of the title (e.g., issue number, icon).
  /// Receives `Padding(top: 1.5)` for baseline alignment with title.
  final Widget? titlePrefix;

  /// Main title widget. Apply `titleSmall.w600` style for consistency.
  final Widget title;

  /// Optional timestamp widget (e.g., TimestampLabel).
  final Widget? timestamp;

  /// Optional trailing widget on the right of title row (e.g., star chip, upvote button).
  final Widget? trailing;

  /// Optional single-line metadata widget below title (e.g., InlineMetadataLine).
  final Widget? metadataLine;

  /// Optional list of chip widgets. Rendered as Wrap with chipGap spacing.
  final List<Widget>? chips;

  /// Optional supplementary content below chips (e.g., body preview, actions).
  final Widget? supplementary;

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Title row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (titlePrefix != null)
              Padding(
                padding: const EdgeInsets.only(top: 1.5),
                child: titlePrefix!,
              ),
            if (titlePrefix != null) spacing.tightGap,
            Expanded(
              child: title,
            ),
            if (trailing != null) ...<Widget>[
              spacing.tightGap,
              trailing!,
            ],
          ],
        ),
        
        // Timestamp (same row as title but right-aligned)
        if (timestamp != null) ...<Widget>[
          spacing.tightGap,
          Align(
            alignment: Alignment.centerLeft,
            child: timestamp!,
          ),
        ],
        
        // Metadata line
        if (metadataLine != null) ...<Widget>[
          spacing.tightGap,
          metadataLine!,
        ],
        
        // Chips row
        if (chips != null && chips!.isNotEmpty) ...<Widget>[
          spacing.compactGap,
          Wrap(
            spacing: spacing.chipGap,
            runSpacing: spacing.chipGap,
            children: chips!,
          ),
        ],
        
        // Supplementary content
        if (supplementary != null) ...<Widget>[
          spacing.itemGap,
          supplementary!,
        ],
      ],
    );
  }
}

/// Matching skeleton for EntityCardLayout with shimmer bones.
class EntityCardLayoutSkeleton extends StatelessWidget {
  const EntityCardLayoutSkeleton({
    this.showPrefix = false,
    this.showTrailing = false,
    this.showMetadataLine = true,
    this.showChips = 0,
    this.showSupplementary = false,
    super.key,
  });

  /// Whether to show prefix bone (small square before title).
  final bool showPrefix;

  /// Whether to show trailing bone (right side of title row).
  final bool showTrailing;

  /// Whether to show metadata line bone.
  final bool showMetadataLine;

  /// Number of chip bones to show (0 = no chip row).
  final int showChips;

  /// Whether to show supplementary content bones (multi-line block).
  final bool showSupplementary;

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Title row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (showPrefix) const ShimmerBone.icon(size: 12),
            if (showPrefix) spacing.tightGap,
            const Expanded(
              child: ShimmerBone.title(),
            ),
            if (showTrailing) ...<Widget>[
              spacing.tightGap,
              const ShimmerBone.chip(width: 60),
            ],
          ],
        ),
        
        // Metadata line
        if (showMetadataLine) ...<Widget>[
          spacing.tightGap,
          const ShimmerBone.label(),
        ],
        
        // Chips row
        if (showChips > 0) ...<Widget>[
          spacing.compactGap,
          Wrap(
            spacing: spacing.chipGap,
            runSpacing: spacing.chipGap,
            children: List<Widget>.generate(
              showChips,
              (final int index) => ShimmerBone.chip(width: 60 + (index * 10.0)),
            ),
          ),
        ],
        
        // Supplementary content
        if (showSupplementary) ...<Widget>[
          spacing.itemGap,
          ShimmerBone.lines(count: 2),
        ],
      ],
    );
  }
}
