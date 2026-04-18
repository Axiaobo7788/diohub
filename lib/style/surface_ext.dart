import 'package:diohub/style/surface_style.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

/// Build a [ShapeBorder] from surface settings without using [BuildContext].
/// Use this when building theme (e.g. in getTheme) to avoid reading from the
/// theme that is currently being constructed.
/// Equivalent to "SurfaceShape.fromSettings(settings, radius)" (data-driven, no context).
ShapeBorder surfaceShapeFromSettings(
  final SurfaceStyle settings,
  final RadiusSize size, {
  final List<Corner>? corners,
  final BorderSide side = BorderSide.none,
  final double? radiusOverride,
}) =>
    _resolveShape(settings, size, corners, side, radiusOverride);

/// Build an [InputBorder] from surface settings without using [BuildContext].
InputBorder inputBorderFromSettings(
  final SurfaceStyle settings,
  final RadiusSize size, {
  final List<Corner>? corners,
  final BorderSide side = BorderSide.none,
}) =>
    OutlineInputBorder(
      borderRadius: _resolveBorderRadius(settings, size, corners),
      borderSide: side,
    );

/// BuildContext extensions for easy access to surface styling
extension SurfaceExt on BuildContext {
  SurfaceStyle get _ss => Theme.of(this).surface;

  /// Get a BorderRadius for a given size and optional corner selection.
  /// When [radiusOverride] is non-null, uses it instead of the theme radius for [size].
  BorderRadius radius(
    final RadiusSize size, {
    final List<Corner>? corners,
    final double? radiusOverride,
  }) =>
      _resolveBorderRadius(_ss, size, corners, radiusOverride);

  /// Get a ShapeBorder for Material widgets (Card, Dialog, etc.).
  /// When [radiusOverride] is non-null, uses it instead of the theme radius for [size].
  ShapeBorder surfaceShape(
    final RadiusSize size, {
    final List<Corner>? corners,
    final BorderSide side = BorderSide.none,
    final double? radiusOverride,
  }) =>
      _resolveShape(_ss, size, corners, side, radiusOverride);

  /// Get a Decoration for Container.decoration.
  /// When [radiusOverride] is non-null, uses it instead of the theme radius for [size].
  Decoration surfaceDecoration(
    final RadiusSize size, {
    final List<Corner>? corners,
    final Color? color,
    final Border? border,
    final Gradient? gradient,
    final List<BoxShadow>? shadow,
    final double? radiusOverride,
  }) =>
      _resolveDecoration(
          _ss, size, corners, color, border, gradient, shadow, radiusOverride);

  /// Get an InputBorder for TextField/InputDecoration
  InputBorder inputBorder(
    final RadiusSize size, {
    final List<Corner>? corners,
    final BorderSide side = BorderSide.none,
  }) =>
      OutlineInputBorder(
        borderRadius: _resolveBorderRadius(_ss, size, corners),
        borderSide: side,
      );
}

/// Resolves a BorderRadius based on size and corner selection.
/// When [radiusOverride] is non-null, uses it instead of [ss.radius(size)].
BorderRadius _resolveBorderRadius(
  final SurfaceStyle ss,
  final RadiusSize size,
  final List<Corner>? corners, [
  final double? radiusOverride,
]) {
  final double r = radiusOverride ?? ss.radius(size);
  if (corners == null || corners.isEmpty) {
    return BorderRadius.circular(r);
  }

  return BorderRadius.only(
    topLeft:
        corners.contains(Corner.topLeft) ? Radius.circular(r) : Radius.zero,
    topRight:
        corners.contains(Corner.topRight) ? Radius.circular(r) : Radius.zero,
    bottomLeft:
        corners.contains(Corner.bottomLeft) ? Radius.circular(r) : Radius.zero,
    bottomRight:
        corners.contains(Corner.bottomRight) ? Radius.circular(r) : Radius.zero,
  );
}

/// Resolves a SmoothBorderRadius (for figma squircle) based on size and corners.
/// When [radiusOverride] is non-null, uses it instead of [ss.radius(size)].
SmoothBorderRadius _resolveSmoothBorderRadius(
  final SurfaceStyle ss,
  final RadiusSize size,
  final List<Corner>? corners, [
  final double? radiusOverride,
]) {
  final double r = radiusOverride ?? ss.radius(size);
  final double s = ss.smoothing;

  if (corners == null || corners.isEmpty) {
    return SmoothBorderRadius(
      cornerRadius: r,
      cornerSmoothing: s,
    );
  }

  return SmoothBorderRadius.only(
    topLeft: corners.contains(Corner.topLeft)
        ? SmoothRadius(cornerRadius: r, cornerSmoothing: s)
        : SmoothRadius.zero,
    topRight: corners.contains(Corner.topRight)
        ? SmoothRadius(cornerRadius: r, cornerSmoothing: s)
        : SmoothRadius.zero,
    bottomLeft: corners.contains(Corner.bottomLeft)
        ? SmoothRadius(cornerRadius: r, cornerSmoothing: s)
        : SmoothRadius.zero,
    bottomRight: corners.contains(Corner.bottomRight)
        ? SmoothRadius(cornerRadius: r, cornerSmoothing: s)
        : SmoothRadius.zero,
  );
}

/// Resolves a ShapeBorder based on surface shape type.
/// When [radiusOverride] is non-null, uses it instead of [ss.radius(size)].
ShapeBorder _resolveShape(
  final SurfaceStyle ss,
  final RadiusSize size,
  final List<Corner>? corners,
  final BorderSide side, [
  final double? radiusOverride,
]) {
  final double r = radiusOverride ?? ss.radius(size);
  switch (ss.shape) {
    case SurfaceShape.rounded:
      return RoundedRectangleBorder(
        side: side,
        borderRadius: _resolveBorderRadius(ss, size, corners, radiusOverride),
      );

    case SurfaceShape.squircle:
      final bool allCorners = corners == null || corners.isEmpty;

      if (allCorners) {
        // Prefer superellipse when all corners are rounded
        return RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(r),
          side: side,
        );
      }

      // Fallback to figma squircle for selective corners
      return SmoothRectangleBorder(
        borderRadius:
            _resolveSmoothBorderRadius(ss, size, corners, radiusOverride),
        side: side,
      );
  }
}

/// Resolves a Decoration based on surface shape type.
/// When [radiusOverride] is non-null, uses it instead of [ss.radius(size)].
Decoration _resolveDecoration(
  final SurfaceStyle ss,
  final RadiusSize size,
  final List<Corner>? corners,
  final Color? color,
  final Border? border,
  final Gradient? gradient,
  final List<BoxShadow>? shadow, [
  final double? radiusOverride,
]) {
  final double r = radiusOverride ?? ss.radius(size);
  final List<BoxShadow> shadows = shadow ?? <BoxShadow>[];

  switch (ss.shape) {
    case SurfaceShape.rounded:
      return BoxDecoration(
        color: color,
        gradient: gradient,
        borderRadius: _resolveBorderRadius(ss, size, corners, radiusOverride),
        border: border,
        boxShadow: shadows,
      );

    case SurfaceShape.squircle:
      final bool allCorners = corners == null || corners.isEmpty;

      if (allCorners) {
        // Prefer superellipse when all corners are rounded
        return ShapeDecoration(
          color: color,
          gradient: gradient,
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(r),
            side: border != null
                ? BorderSide(
                    color: border.top.color,
                    width: border.top.width,
                  )
                : BorderSide.none,
          ),
          shadows: shadows,
        );
      }

      // Fallback to figma squircle for selective corners
      return ShapeDecoration(
        color: color,
        gradient: gradient,
        shape: SmoothRectangleBorder(
          borderRadius:
              _resolveSmoothBorderRadius(ss, size, corners, radiusOverride),
          side: border != null
              ? BorderSide(
                  color: border.top.color,
                  width: border.top.width,
                )
              : BorderSide.none,
        ),
        shadows: shadows,
      );
  }
}
