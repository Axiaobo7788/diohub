import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

enum MetadataRowLayoutMode {
  adaptive,
  inline,
  stacked,
}

/// A single-line metadata row: icon (optional) + optional label + value.
///
/// Tap behaviour is opt-in via [onTap].
/// Optional [trailing] is rendered after the value with [itemGap].
/// When [label] is null, no label column is rendered (child-only row).
class MetadataRow extends StatelessWidget {
  const MetadataRow({
    required this.child,
    this.label,
    this.labelWidth = 108,
    this.icon,
    this.trailing,
    this.padding,
    this.layoutMode = MetadataRowLayoutMode.adaptive,
    this.onTap,
    super.key,
  });

  /// Label displayed in a muted caption style. When null, no label column is shown.
  final String? label;

  /// Width of the label column when [label] is non-null.
  final double labelWidth;

  /// The value widget, typically [Text] or a richer inline widget.
  final Widget child;

  /// Optional leading icon.
  final IconData? icon;

  /// Optional trailing widget (e.g. timestamp, state icon). Rendered after [child] with itemGap.
  final Widget? trailing;

  /// Controls responsive row layout behavior.
  final MetadataRowLayoutMode layoutMode;

  /// Tap callback — when non-null a subtle ink-splash is shown.
  final VoidCallback? onTap;

  /// Padding around the row. When null, uses [AppSpacing.metadataRowPadding] (e.g. for peek use zero).
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final AppSpacing spacing = context.spacing;
    final EdgeInsetsGeometry effectivePadding =
        padding ?? spacing.metadataRowPadding;
    final Widget content = LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        final bool useInline = _useInlineLayout(constraints.maxWidth);
        final Widget iconWidget = Icon(
          icon,
          size: 16,
          color: colorScheme.onSurfaceVariant.secondary,
        );
        final TextStyle? labelStyle = theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant.strong,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        );
        final TextStyle? valueStyle = theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.25,
        );
        final Widget valueChild = DefaultTextStyle.merge(
          style: valueStyle,
          child: child,
        );

        if (useInline) {
          return Padding(
            padding: effectivePadding,
            child: Row(
              children: <Widget>[
                if (icon != null) ...<Widget>[iconWidget, spacing.itemGap],
                if (label != null) ...<Widget>[
                  SizedBox(
                    width: labelWidth,
                    child: Text(
                      label!,
                      style: labelStyle,
                    ),
                  ),
                  spacing.itemGap,
                ],
                Expanded(child: valueChild),
                if (trailing != null) ...<Widget>[spacing.itemGap, trailing!],
              ],
            ),
          );
        }

        return Padding(
          padding: effectivePadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (icon != null) ...<Widget>[iconWidget, spacing.itemGap],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (label != null)
                      Text(
                        label!,
                        style: labelStyle,
                      ),
                    if (label != null)
                      SizedBox(height: spacing.metadataRowValueTopGap),
                    valueChild,
                  ],
                ),
              ),
              if (trailing != null) ...<Widget>[spacing.itemGap, trailing!],
            ],
          ),
        );
      },
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, child: content);
    }
    return content;
  }

  bool _useInlineLayout(final double maxWidth) {
    switch (layoutMode) {
      case MetadataRowLayoutMode.inline:
        return true;
      case MetadataRowLayoutMode.stacked:
        return false;
      case MetadataRowLayoutMode.adaptive:
        final int length = label?.length ?? 0;
        return maxWidth >= 360 && (label == null || length <= 14);
    }
  }
}

/// A contact link row: icon + value (no label column). Tap opens URL; caller provides [onTap].
class MetadataContactRow extends StatelessWidget {
  const MetadataContactRow({
    required this.icon,
    required this.value,
    required this.onTap,
    this.padding,
    super.key,
  });

  final IconData icon;
  final String value;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final AppSpacing spacing = context.spacing;
    final EdgeInsetsGeometry effectivePadding =
        padding ?? spacing.metadataRowPadding;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: effectivePadding,
        child: Row(
          children: <Widget>[
            Icon(
              icon,
              size: 16,
              color: colorScheme.onSurfaceVariant.secondary,
            ),
            spacing.compactGap,
            Flexible(
              child: Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: colorScheme.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: colorScheme.primary.withValues(alpha: 0.5),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data for a single flag chip (e.g. hireable, sponsors).
class MetadataFlag {
  const MetadataFlag({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
}

/// A wrap of flag chips with metadata row padding (e.g. hireable, sponsors).
class MetadataFlagWrap extends StatelessWidget {
  const MetadataFlagWrap({
    required this.flags,
    this.padding,
    super.key,
  });

  final List<MetadataFlag> flags;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(final BuildContext context) {
    if (flags.isEmpty) return const SizedBox.shrink();

    final AppSpacing spacing = context.spacing;
    final EdgeInsetsGeometry effectivePadding =
        padding ?? spacing.metadataRowPadding;

    return Padding(
      padding: effectivePadding,
      child: Wrap(
        spacing: spacing.compactSpacing,
        runSpacing: spacing.compactSpacing,
        children: flags.map((final MetadataFlag flag) {
          final Widget chip = TintedChip(
            color: flag.color,
            icon: flag.icon,
            label: flag.label,
            border: true,
          );
          if (flag.onTap != null) {
            return GestureDetector(onTap: flag.onTap, child: chip);
          }
          return chip;
        }).toList(),
      ),
    );
  }
}

/// Data for a single stat chip.
class MetadataStat {
  const MetadataStat({
    required this.label,
    required this.value,
    this.color,
    this.icon,
    this.onTap,
  });

  final String label;
  final String value;

  /// Chip accent color — defaults to [ColorScheme.primary].
  final Color? color;

  /// Optional icon shown before the value.
  final IconData? icon;

  /// Optional tap callback; when non-null the chip is tappable (e.g. navigate to tab).
  final VoidCallback? onTap;
}

/// A horizontal row of compact stat chips (e.g. +42 / −3 / 5 files).
class MetadataStatBar extends StatelessWidget {
  const MetadataStatBar({
    required this.stats,
    this.padding,
    super.key,
  });

  final List<MetadataStat> stats;

  /// When null, uses [AppSpacing.metadataRowPadding].
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final AppSpacing spacing = context.spacing;
    final EdgeInsetsGeometry effectivePadding =
        padding ?? spacing.metadataRowPadding;

    return Padding(
      padding: effectivePadding,
      child: Wrap(
        spacing: spacing.itemSpacing,
        runSpacing: spacing.compactSpacing,
        children: stats.map((final MetadataStat stat) {
          final Color chipColor = stat.color ?? colorScheme.primary;
          final Widget chip = Container(
            padding: spacing.chipPadding,
            decoration: BoxDecoration(
              color: chipColor.subtle,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: chipColor.tint,
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (stat.icon != null) ...<Widget>[
                  Icon(stat.icon, size: 13, color: chipColor),
                  spacing.tightGap,
                ],
                Text(
                  stat.value,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: chipColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                spacing.tightGap,
                Text(
                  stat.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.secondary,
                    fontSize: 10,
                  ),
                ),
                if (stat.onTap != null) ...<Widget>[
                  spacing.tightGap,
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 12,
                    color: colorScheme.onSurfaceVariant.muted,
                  ),
                ],
              ],
            ),
          );
          if (stat.onTap != null) {
            return InkWell(
              onTap: stat.onTap,
              borderRadius: BorderRadius.circular(8),
              child: chip,
            );
          }
          return chip;
        }).toList(),
      ),
    );
  }
}

/// A single timestamp entry.
class TimestampEntry {
  const TimestampEntry({required this.label, required this.date});

  final String label;
  final DateTime date;
}

/// Displays multiple timestamps inline, separated by ` · `.
///
/// Example: "Created 3d ago · Updated 1h ago · Closed 2d ago"
class MetadataTimestampRow extends StatelessWidget {
  const MetadataTimestampRow({
    required this.timestamps,
    this.padding,
    super.key,
  });

  final List<TimestampEntry> timestamps;

  /// When null, uses [AppSpacing.metadataRowPadding].
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(final BuildContext context) {
    if (timestamps.isEmpty) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final List<InlineSpan> spans = <InlineSpan>[];
    for (int i = 0; i < timestamps.length; i++) {
      if (i > 0) {
        spans.add(
          TextSpan(
            text: '  ·  ',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.muted,
              fontWeight: FontWeight.w400,
            ),
          ),
        );
      }
      final TimestampEntry ts = timestamps[i];
      spans.add(
        TextSpan(
          text: '${ts.label} ',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant.secondary,
            fontWeight: FontWeight.w400,
            fontSize: 11,
          ),
        ),
      );
      spans.add(
        TextSpan(
          text: ts.date.toRelativeDate(shorten: false),
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
        ),
      );
    }

    final AppSpacing spacing = context.spacing;
    final EdgeInsetsGeometry effectivePadding =
        padding ?? spacing.metadataRowPadding;
    return Padding(
      padding: effectivePadding,
      child: Text.rich(
        TextSpan(children: spans),
        style: theme.textTheme.bodySmall,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
    );
  }
}

/// Renders a visual branch flow: `head → base` with optional merge indicator.
