import 'package:diohub/common/widgets/surface.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';

/// A reusable chip widget showing icon + label in a tinted pill.
///
/// This abstracts the common pattern of "small icon + text in a colored rounded box"
/// seen in branch tags, issue state badges, metadata chips, etc.
class TintedChip extends StatelessWidget {
  const TintedChip({
    required this.color,
    this.icon,
    super.key,
    this.label,
    this.iconSize = 12,
    this.border = false,
    this.size = RadiusSize.small,
    this.padding,
    this.labelStyle,
    this.gap,
    this.trailing,
    this.minContentHeight,
  });

  final Color color;
  final IconData? icon;
  final String? label;
  final double iconSize;
  final bool border;
  final RadiusSize size;
  final EdgeInsetsGeometry? padding;
  final TextStyle? labelStyle;

  /// Minimum height for the inner content row. If null, defaults to 18 for
  /// icon-only chips (no [label]) and 0 for labeled chips.
  final double? minContentHeight;

  /// Horizontal gap between icon and label. When null, uses [AppSpacing.tightSpacing].
  final double? gap;

  /// Optional trailing widget (e.g. expand chevron).
  final Widget? trailing;

  @override
  Widget build(final BuildContext context) {
    final EdgeInsetsGeometry effectivePadding = padding ??
        (label != null || trailing != null
            ? context.spacing.chipPadding
            : const EdgeInsets.all(4));
    final double effectiveGap = gap ?? context.spacing.tightSpacing;

    return Surface(
      size: size,
      color: color.tint,
      border: border
          ? Border.all(
              color: color.borderO,
            )
          : null,
      padding: effectivePadding,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: minContentHeight ?? (label == null ? 18 : 0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (icon != null)
              Icon(
                icon!,
                size: iconSize,
                color: color,
              ),
            if (icon != null && label != null) SizedBox(width: effectiveGap),
            if (label != null)
              Text(
                label!,
                style: labelStyle ??
                    Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
              ),
            if (trailing != null) ...<Widget>[
              SizedBox(width: effectiveGap),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
