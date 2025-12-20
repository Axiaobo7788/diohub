import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

/// Enum to specify which side the border should be on (for border mode)
enum BorderSideType {
  top,
  bottom,
  left,
  right,
}

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
/// The border respects the borderRadius with ClipRRect on opposite corners.
///
/// The highlight style is hardcoded and will be made configurable via app settings later.
class HighlightedContainer extends StatelessWidget {
  const HighlightedContainer({
    required this.child,
    required this.highlightColor,
    this.backgroundColor,
    this.borderSide = BorderSideType.bottom,
    this.borderWidth = 1.0,
    this.borderRadius = 12.0,
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

  /// Border radius for rounded corners
  final double borderRadius;

  /// Elevation for shadow (only used in elevation mode)
  // final double elevation;

  // TODO: Fetch from app settings
  static const HighlightStyle _style = HighlightStyle.border;

  @override
  Widget build(BuildContext context) {
    if (_style == HighlightStyle.elevation) {
      // Elevation mode: use Material with elevation
      return Material(
        color: backgroundColor?? context.colorScheme.onSurface,
        borderRadius: BorderRadius.circular(borderRadius),
        elevation: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: child,
        ),
      );
    } else {
      // Border mode: use colored border on one side with theme colors
      // final borderColor = context.colorScheme.outlineVariant.withOpacity(0.3);
      final Border border;
      final BorderRadius clipRadius;

      // Create a single BorderSide instance to avoid code duplication
      final borderSideValue = BorderSide(
        color: highlightColor.withOpacity(0.7),
        width: borderWidth,
      );
      switch (borderSide) {
        case BorderSideType.top:
          border = Border(
            top: borderSideValue,
          );
          // Clip bottom corners (opposite side) for consistent rounded borders
          clipRadius = BorderRadius.only(
            bottomLeft: Radius.circular(borderRadius),
            bottomRight: Radius.circular(borderRadius),
          );
          break;
        case BorderSideType.bottom:
          border = Border(
            bottom: borderSideValue,
          );
          // Clip top corners (opposite side) for consistent rounded borders
          clipRadius = BorderRadius.only(
            topLeft: Radius.circular(borderRadius),
            topRight: Radius.circular(borderRadius),
          );
          break;
        case BorderSideType.left:
          border = Border(
            left: borderSideValue,
          );
          // Clip right corners (opposite side) for consistent rounded borders
          clipRadius = BorderRadius.only(
            topRight: Radius.circular(borderRadius),
            bottomRight: Radius.circular(borderRadius),
          );
          break;
        case BorderSideType.right:
          border = Border(
            right: borderSideValue,
          );
          // Clip left corners (opposite side) for consistent rounded borders
          clipRadius = BorderRadius.only(
            topLeft: Radius.circular(borderRadius),
            bottomLeft: Radius.circular(borderRadius),
          );
          break;
      }

      return ClipRRect(
        borderRadius: clipRadius,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? context.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border,
          ),
          child: child,
        ),
      );
    }
  }
}
