import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:diohub/style/surface_style_theme.dart';
import 'package:diohub/common/misc/surface_shape_resolver.dart';

/// Enum to specify the highlight style
enum HighlightStyle {
  /// Uses elevation shadow for highlighting
  elevation,

  /// Uses colored border on one side for highlighting
  border,
}

/// A widget that wraps a child with a highlight effect.
///
/// Can use either elevation shadow or a colored border on one side.
/// Uses standardized border radius sizes and supports squircle shapes.
///
/// The highlight style is hardcoded and will be made configurable via app settings later.
class HighlightedContainer extends StatelessWidget {
  const HighlightedContainer({
    required this.child,
    required this.highlightColor,
    this.backgroundColor,
    this.borderSide = BorderSideType.bottom,
    this.borderWidth = 0.5,
    this.size = BorderRadiusSize.medium,
    super.key,
  });

  /// The widget to wrap
  final Widget child;

  /// Color for the highlight (border color in border mode, not used in elevation mode)
  final Color highlightColor;

  /// Background color for the container. If null, uses default Material background.
  final Color? backgroundColor;

  /// Which side to show the border on (only used in border mode)
  final BorderSideType borderSide;

  /// Width of the border (only used in border mode)
  final double borderWidth;

  /// Border radius size (standardized)
  final BorderRadiusSize size;

  // TODO: Fetch from app settings
  static const HighlightStyle _style = HighlightStyle.elevation;

  /// Convert BorderSideType to CornerSide list for opposite corners
  List<CornerSide> _getOppositeCorners(BorderSideType side) {
    switch (side) {
      case BorderSideType.top:
        return const [CornerSide.bottom];
      case BorderSideType.bottom:
        return const [CornerSide.top];
      case BorderSideType.left:
        return const [CornerSide.right];
      case BorderSideType.right:
        return const [CornerSide.left];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_style == HighlightStyle.elevation) {
      // Elevation mode: use Material with elevation and squircle shape
      final shape = SurfaceShapeResolver.shape(
        context,
        size: size,
      );

      return Material(
        color: backgroundColor ?? context.colorScheme.onSurface,
        shape: shape,
        elevation: 1,
        child: child,
      );
    } else {
      // Border mode: use colored border on one side with squircle support
      final clipCorners = _getOppositeCorners(borderSide);

      final borderSideValue = BorderSide(
        color: highlightColor.withValues(alpha: 0.7),
        width: borderWidth,
      );

      final Border border;
      switch (borderSide) {
        case BorderSideType.top:
          border = Border(top: borderSideValue);
          break;
        case BorderSideType.bottom:
          border = Border(bottom: borderSideValue);
          break;
        case BorderSideType.left:
          border = Border(left: borderSideValue);
          break;
        case BorderSideType.right:
          border = Border(right: borderSideValue);
          break;
      }

      final decoration = SurfaceShapeResolver.boxDecoration(
        context,
        size: size,
        corners: clipCorners,
        border: border,
      );

      return DecoratedBox(
        decoration: decoration,
        child: child,
      );
    }
  }
}
