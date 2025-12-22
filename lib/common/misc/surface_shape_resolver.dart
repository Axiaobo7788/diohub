import 'package:flutter/material.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:diohub/style/surface_style_theme.dart';

/// Helper to resolve surface shapes and decorations based on theme settings
///
/// This centralizes all shape/decoration logic so UI code doesn't need to
/// handle rounded vs squircle decisions or corner selection logic.
class SurfaceShapeResolver {
  /// Create a ShapeBorder with soft radius (4px default) - for subtle rounding
  static ShapeBorder soft(
    BuildContext context, {
    List<CornerSide>? corners,
    BorderSide side = BorderSide.none,
  }) =>
      shape(
        context,
        size: BorderRadiusSize.soft,
        corners: corners,
        side: side,
      );

  /// Create a ShapeBorder with small radius (10px default)
  static ShapeBorder small(
    BuildContext context, {
    List<CornerSide>? corners,
    BorderSide side = BorderSide.none,
  }) =>
      shape(
        context,
        size: BorderRadiusSize.small,
        corners: corners,
        side: side,
      );

  /// Create a ShapeBorder with medium radius (14px default)
  static ShapeBorder medium(
    BuildContext context, {
    List<CornerSide>? corners,
    BorderSide side = BorderSide.none,
  }) =>
      shape(
        context,
        size: BorderRadiusSize.medium,
        corners: corners,
        side: side,
      );

  /// Create a ShapeBorder with large radius (18px default)
  static ShapeBorder large(
    BuildContext context, {
    List<CornerSide>? corners,
    BorderSide side = BorderSide.none,
  }) =>
      shape(
        context,
        size: BorderRadiusSize.large,
        corners: corners,
        side: side,
      );

  /// Create a ShapeBorder with very large radius (28px default)
  static ShapeBorder veryLarge(
    BuildContext context, {
    List<CornerSide>? corners,
    BorderSide side = BorderSide.none,
  }) =>
      shape(
        context,
        size: BorderRadiusSize.veryLarge,
        corners: corners,
        side: side,
      );

  /// Create a ShapeBorder for Material surfaces (Card, Dialog, BottomSheet, etc.)
  ///
  /// Automatically uses the shape type from theme (rounded or squircle).
  /// For squircle, prefers RoundedSuperellipseBorder when all corners are rounded,
  /// falls back to SmoothRectangleBorder when selective corners are specified.
  static ShapeBorder shape(
    BuildContext context, {
    required BorderRadiusSize size,
    List<CornerSide>? corners,
    BorderSide side = BorderSide.none,
  }) {
    final ss = Theme.of(context).surfaceStyle;
    final r = ss.radius(size);

    switch (ss.shapeType) {
      case BorderShapeType.rounded:
        return RoundedRectangleBorder(
          side: side,
          borderRadius: ss.borderRadius(size: size, corners: corners),
        );

      case BorderShapeType.squircle:
        final allCorners = corners == null ||
            corners.isEmpty ||
            corners.contains(CornerSide.all);

        if (allCorners) {
          // Prefer superellipse when all corners are rounded
          return RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(r),
            side: side,
          );
        }

        // Fallback to figma squircle for selective corners
        return SmoothRectangleBorder(
          borderRadius: ss.smoothBorderRadius(size: size, corners: corners),
          side: side,
        );
    }
  }

  /// Create a Decoration with soft radius (4px default) - for subtle rounding
  static Decoration softDecoration(
    BuildContext context, {
    List<CornerSide>? corners,
    Color? color,
    Border? border,
    Gradient? gradient,
    List<BoxShadow>? boxShadow,
    BoxShape shape = BoxShape.rectangle,
  }) =>
      boxDecoration(
        context,
        size: BorderRadiusSize.soft,
        corners: corners,
        color: color,
        border: border,
        gradient: gradient,
        boxShadow: boxShadow,
        shape: shape,
      );

  /// Create a Decoration with small radius (10px default)
  static Decoration smallDecoration(
    BuildContext context, {
    List<CornerSide>? corners,
    Color? color,
    Border? border,
    Gradient? gradient,
    List<BoxShadow>? boxShadow,
    BoxShape shape = BoxShape.rectangle,
  }) =>
      boxDecoration(
        context,
        size: BorderRadiusSize.small,
        corners: corners,
        color: color,
        border: border,
        gradient: gradient,
        boxShadow: boxShadow,
        shape: shape,
      );

  /// Create a Decoration with medium radius (14px default)
  static Decoration mediumDecoration(
    BuildContext context, {
    List<CornerSide>? corners,
    Color? color,
    Border? border,
    Gradient? gradient,
    List<BoxShadow>? boxShadow,
    BoxShape shape = BoxShape.rectangle,
  }) =>
      boxDecoration(
        context,
        size: BorderRadiusSize.medium,
        corners: corners,
        color: color,
        border: border,
        gradient: gradient,
        boxShadow: boxShadow,
        shape: shape,
      );

  /// Create a Decoration with large radius (18px default)
  static Decoration largeDecoration(
    BuildContext context, {
    List<CornerSide>? corners,
    Color? color,
    Border? border,
    Gradient? gradient,
    List<BoxShadow>? boxShadow,
    BoxShape shape = BoxShape.rectangle,
  }) =>
      boxDecoration(
        context,
        size: BorderRadiusSize.large,
        corners: corners,
        color: color,
        border: border,
        gradient: gradient,
        boxShadow: boxShadow,
        shape: shape,
      );

  /// Create a Decoration with very large radius (28px default)
  static Decoration veryLargeDecoration(
    BuildContext context, {
    List<CornerSide>? corners,
    Color? color,
    Border? border,
    Gradient? gradient,
    List<BoxShadow>? boxShadow,
    BoxShape shape = BoxShape.rectangle,
  }) =>
      boxDecoration(
        context,
        size: BorderRadiusSize.veryLarge,
        corners: corners,
        color: color,
        border: border,
        gradient: gradient,
        boxShadow: boxShadow,
        shape: shape,
      );

  /// Create a Decoration for Container.decoration
  ///
  /// Automatically uses the shape type from theme and applies defaults
  /// for border/shadow from the theme if not overridden.
  static Decoration boxDecoration(
    BuildContext context, {
    required BorderRadiusSize size,
    List<CornerSide>? corners,
    Color? color,
    Border? border,
    Gradient? gradient,
    List<BoxShadow>? boxShadow,
    BoxShape shape = BoxShape.rectangle,
  }) {
    final ss = Theme.of(context).surfaceStyle;
    final resolvedBorder = border ??
        (ss.borderWidth > 0
            ? Border.all(
                color: ss.borderColor ?? Colors.transparent,
                width: ss.borderWidth,
              )
            : null);
    final shadows = boxShadow ?? ss.shadow;

    switch (ss.shapeType) {
      case BorderShapeType.rounded:
        return BoxDecoration(
          color: color ?? ss.backgroundColor,
          gradient: gradient,
          borderRadius: ss.borderRadius(size: size, corners: corners),
          border: resolvedBorder,
          boxShadow: shadows,
          shape: shape,
        );

      case BorderShapeType.squircle:
        final allCorners = corners == null ||
            corners.isEmpty ||
            corners.contains(CornerSide.all);

        if (allCorners && shape == BoxShape.rectangle) {
          // Prefer superellipse when all corners are rounded
          return ShapeDecoration(
            color: color ?? ss.backgroundColor,
            gradient: gradient != null
                ? LinearGradient(colors: gradient.colors)
                : null,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(ss.radius(size)),
              side: resolvedBorder != null
                  ? BorderSide(
                      color: resolvedBorder.top.color,
                      width: resolvedBorder.top.width,
                    )
                  : BorderSide.none,
            ),
            shadows: shadows,
          );
        }

        // Fallback to figma squircle for selective corners
        return ShapeDecoration(
          color: color ?? ss.backgroundColor,
          gradient:
              gradient != null ? LinearGradient(colors: gradient.colors) : null,
          shape: SmoothRectangleBorder(
            borderRadius: ss.smoothBorderRadius(size: size, corners: corners),
            side: resolvedBorder != null
                ? BorderSide(
                    color: resolvedBorder.top.color,
                    width: resolvedBorder.top.width,
                  )
                : BorderSide.none,
          ),
          shadows: shadows,
        );
    }
  }

  /// Create an InputBorder for TextField/InputDecoration
  ///
  /// Uses standard rounded borders even when squircle is selected
  /// (since TextField borders are typically rounded).
  static InputBorder inputBorder(
    BuildContext context, {
    required BorderRadiusSize size,
    List<CornerSide>? corners,
    BorderSide borderSide = BorderSide.none,
  }) {
    final ss = Theme.of(context).surfaceStyle;
    return OutlineInputBorder(
      borderRadius: ss.borderRadius(size: size, corners: corners),
      borderSide: borderSide,
    );
  }
}
