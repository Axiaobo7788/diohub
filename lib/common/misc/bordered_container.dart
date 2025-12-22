import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:diohub/style/surface_style_theme.dart';
import 'package:diohub/common/misc/surface_shape_resolver.dart';

/// A widget that wraps a child with a colored border on one side with rounded corners.
///
/// This creates a 3D effect by adding a colored border on a specified side.
/// Uses standardized border radius sizes and supports squircle shapes.
class BorderedContainer extends StatelessWidget {
  const BorderedContainer({
    required this.child,
     this.borderColor,
    this.borderSide = BorderSideType.bottom,
    this.borderWidth = 1.2,
    this.size = BorderRadiusSize.medium,
    this.backgroundColor,
    super.key,
  });

  /// The widget to wrap
  final Widget child;

  /// Color of the border
  final Color? borderColor;

  /// Which side to show the border on
  final BorderSideType borderSide;

  /// Width of the border
  final double borderWidth;

  /// Border radius size (standardized)
  final BorderRadiusSize size;

  /// Background color of the container. If null, uses surfaceVariant from theme.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceStyle = theme.surfaceStyle;
    final borderRadius = surfaceStyle.borderRadius(size: size);

    // Create border with only the specified side visible
    final Border border;
    final BorderRadius clipRadius;
final BorderSide borderSideValue = BorderSide(color: borderColor?.withOpacity(0.8)??context.colorScheme.primary.withOpacity(0.5), width: borderWidth);
    switch (borderSide) {
      case BorderSideType.top:
        border = Border(
          top: borderSideValue,
        );
        // Clip bottom corners (opposite side) for consistent rounded borders
        clipRadius = BorderRadius.only(
          bottomLeft: borderRadius.bottomLeft,
          bottomRight: borderRadius.bottomRight,
        );
        break;
      case BorderSideType.bottom:
        border = Border(
          bottom: borderSideValue,
        );
        // Clip top corners (opposite side) for consistent rounded borders
        clipRadius = BorderRadius.only(
          topLeft: borderRadius.topLeft,
          topRight: borderRadius.topRight,
        );
        break;
      case BorderSideType.left:
        border = Border(
          left: borderSideValue,
        );
        // Clip right corners (opposite side) for consistent rounded borders
        clipRadius = BorderRadius.only(
          topRight: borderRadius.topRight,
          bottomRight: borderRadius.bottomRight,
        );
        break;
      case BorderSideType.right:
        border = Border(
          right: borderSideValue,
        );
        // Clip left corners (opposite side) for consistent rounded borders
        clipRadius = BorderRadius.only(
          topLeft: borderRadius.topLeft,
          bottomLeft: borderRadius.bottomLeft,
        );
        break;
    }

    // Get base decoration from theme API, then override with single-side border
    final baseDecoration = SurfaceShapeResolver.boxDecoration(
      context,
      size: size,
      color: backgroundColor ??
          Theme.of(context).colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
      border: border, // Pass the single-side border
    );

    // For single-side borders, we need BoxDecoration (not ShapeDecoration)
    // So extract the values and create a BoxDecoration
    final BoxDecoration decoration;
    if (baseDecoration is BoxDecoration) {
      decoration = baseDecoration.copyWith(border: border);
    } else {
      // Fallback if it's a ShapeDecoration (shouldn't happen for rounded)
      decoration = BoxDecoration(
        color: backgroundColor ??
            Theme.of(context).colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
        borderRadius: borderRadius,
        border: border,
      );
    }

    return ClipRRect(
      borderRadius: clipRadius,
      child: Container(
        decoration: decoration,
        child: child,
      ),
    );
  }
}
