import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';

/// Lightweight tappable wrapper for non-card surfaces.
///
/// Provides `Material(transparency)` + `InkWell` with correct `borderRadius`
/// for elements that just need splash feedback without a visible background
/// (icon buttons, list rows, inline tappables).
///
/// For tappable surfaces **with** a visible background, use
/// `BorderedContainer(onTap:)` instead.
///
/// When neither [onTap] nor [onLongPress] is set, returns [child] directly
/// with no gesture or Material overhead.
class TapFeedback extends StatelessWidget {
  const TapFeedback({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.size = RadiusSize.medium,
    super.key,
  });

  /// The content to display.
  final Widget child;

  /// Callback when tapped. If null (and [onLongPress] is also null),
  /// the widget renders [child] directly with no gesture layer.
  final VoidCallback? onTap;

  /// Callback when long pressed.
  final VoidCallback? onLongPress;

  /// Explicit border radius override for the splash shape.
  /// If null, falls back to the theme radius for [size].
  final BorderRadius? borderRadius;

  /// Theme-based radius size, used when [borderRadius] is null.
  /// Defaults to [RadiusSize.medium].
  final RadiusSize size;

  @override
  Widget build(final BuildContext context) {
    if (onTap == null && onLongPress == null) return child;
    final BorderRadius radius = borderRadius ?? context.radius(size);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: radius,
        child: child,
      ),
    );
  }
}
