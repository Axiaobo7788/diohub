import 'package:diohub/common/misc/bordered_container.dart'
    show BorderedContainer;
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';

/// Lightweight bordered container for inline/secondary content in sections.
///
/// Provides a consistent bordered box with subtle background, used for
/// secondary elements and info (e.g. settings rows, metadata blocks,
/// timeline event content, comment previews). Owns content insets via
/// [padding]; when null, uses [AppSpacing.cardContentPadding].
///
/// Unlike [BorderedContainer], this has no elevation and no tap handling;
/// use it for static inline blocks. For list cards and tappable surfaces,
/// use [BorderedContainer] instead.
class InlineContainer extends StatelessWidget {
  const InlineContainer({
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    super.key,
  });

  final Widget child;

  /// Padding around the child. When null, uses [AppSpacing.cardContentPadding].
  /// For tighter blocks (e.g. peek body, inline comment), pass
  /// [AppSpacing.chipPadding].
  final EdgeInsetsGeometry? padding;

  /// Background color. When null, transparent (border-only container).
  final Color? backgroundColor;

  /// Border color. When null, uses outlineVariant.borderO from theme.
  final Color? borderColor;

  /// Border radius. When null, uses [RadiusSize.medium].
  final BorderRadius? borderRadius;

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final EdgeInsetsGeometry effectivePadding =
        padding ?? spacing.cardContentPadding;
    final Color effectiveBg = backgroundColor ?? Colors.transparent;
    final Color effectiveBorderColor =
        borderColor ?? colorScheme.outlineVariant.borderO;
    final BorderRadius effectiveRadius =
        borderRadius ?? context.radius(RadiusSize.medium);

    return Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: effectiveRadius,
        border: Border.all(
          color: effectiveBorderColor,
        ),
      ),
      child: child,
    );
  }
}
