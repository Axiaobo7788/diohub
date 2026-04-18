import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

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
    this.size = RadiusSize.medium,
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
  final RadiusSize size;

  // Future: Fetch from app settings.
  static const HighlightStyle _style = HighlightStyle.elevation;

  /// Convert BorderSideType to Corner list for opposite corners
  List<Corner> _getOppositeCorners(final BorderSideType side) {
    switch (side) {
      case BorderSideType.top:
        return CornerGroups.bottom;
      case BorderSideType.bottom:
        return CornerGroups.top;
      case BorderSideType.left:
        return CornerGroups.right;
      case BorderSideType.right:
        return CornerGroups.left;
    }
  }

  @override
  Widget build(final BuildContext context) {
    if (_style == HighlightStyle.elevation) {
      // Elevation mode: use Material with elevation and squircle shape
      final ShapeBorder shape = context.surfaceShape(size);

      return Material(
        color: backgroundColor ?? context.colorScheme.onSurface,
        shape: shape,
        elevation: 1,
        child: child,
      );
    } else {
      // Border mode: use colored border on one side with squircle support
      final List<Corner> clipCorners = _getOppositeCorners(borderSide);

      final BorderSide borderSideValue = BorderSide(
        color: highlightColor.withValues(alpha: 0.7),
        width: borderWidth,
      );

      final Border border;
      switch (borderSide) {
        case BorderSideType.top:
          border = Border(top: borderSideValue);
        case BorderSideType.bottom:
          border = Border(bottom: borderSideValue);
        case BorderSideType.left:
          border = Border(left: borderSideValue);
        case BorderSideType.right:
          border = Border(right: borderSideValue);
      }

      final Decoration decoration = context.surfaceDecoration(
        size,
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
