import 'package:flutter/material.dart';
import 'package:figma_squircle/figma_squircle.dart';

/// Standard border radius sizes used throughout the app
enum BorderRadiusSize {
  soft,
  small,
  medium,
  large,
  veryLarge,
}

/// Enum to specify which side the border should be on
enum BorderSideType {
  top,
  bottom,
  left,
  right,
}

/// Specifies which corners should have rounded borders
enum CornerSide {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  all,
  top,
  bottom,
  left,
  right,
  none,
}

/// Border style type - controls which implementation is used
enum BorderShapeType {
  /// Standard rounded rectangle border
  rounded,

  /// iOS-style superellipse (smooth corners)
  squircle,
}

/// Theme extension for surface styling (shapes, borders, shadows, radii)
///
/// This centralizes all surface styling decisions for containers, cards, dialogs, etc.
/// Provides app-wide control over shape style (rounded vs squircle), border radii,
/// corner smoothing, and default decorations.
class SurfaceStyleTheme extends ThemeExtension<SurfaceStyleTheme> {
  const SurfaceStyleTheme({
    this.shapeType = BorderShapeType.squircle,
    this.softRadius = 4,
    this.smallRadius = 10,
    this.mediumRadius = 14,
    this.largeRadius = 18,
    this.veryLargeRadius = 28,
    this.cornerSmoothing = 0.5,
    this.borderWidth = 0,
    this.borderColor,
    this.shadow = const [],
    this.padding,
    this.backgroundColor,
  });

  final BorderShapeType shapeType;
  final double softRadius;
  final double smallRadius;
  final double mediumRadius;
  final double largeRadius;
  final double veryLargeRadius;
  final double cornerSmoothing;
  final double borderWidth;
  final Color? borderColor;
  final List<BoxShadow> shadow;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  /// Get radius value for a given size
  double radius(final BorderRadiusSize size) {
    switch (size) {
      case BorderRadiusSize.soft:
        return softRadius;
      case BorderRadiusSize.small:
        return smallRadius;
      case BorderRadiusSize.medium:
        return mediumRadius;
      case BorderRadiusSize.large:
        return largeRadius;
      case BorderRadiusSize.veryLarge:
        return veryLargeRadius;
    }
  }

  /// Create a BorderRadius based on size and corner sides
  BorderRadius borderRadius({
    required final BorderRadiusSize size,
    final List<CornerSide>? corners,
  }) {
    final r = radius(size);
    final cs = corners ?? const [CornerSide.all];

    if (cs.contains(CornerSide.all) || cs.isEmpty) {
      return BorderRadius.circular(r);
    }

    return BorderRadius.only(
      topLeft: cs.any(
        (final c) =>
            c == CornerSide.topLeft ||
            c == CornerSide.top ||
            c == CornerSide.left,
      )
          ? Radius.circular(r)
          : Radius.zero,
      topRight: cs.any(
        (final c) =>
            c == CornerSide.topRight ||
            c == CornerSide.top ||
            c == CornerSide.right,
      )
          ? Radius.circular(r)
          : Radius.zero,
      bottomLeft: cs.any(
        (final c) =>
            c == CornerSide.bottomLeft ||
            c == CornerSide.bottom ||
            c == CornerSide.left,
      )
          ? Radius.circular(r)
          : Radius.zero,
      bottomRight: cs.any(
        (final c) =>
            c == CornerSide.bottomRight ||
            c == CornerSide.bottom ||
            c == CornerSide.right,
      )
          ? Radius.circular(r)
          : Radius.zero,
    );
  }

  /// Create a SmoothBorderRadius based on size and corner sides (for figma squircle)
  SmoothBorderRadius smoothBorderRadius({
    required final BorderRadiusSize size,
    final List<CornerSide>? corners,
  }) {
    final r = radius(size);
    final s = cornerSmoothing;
    final cs = corners ?? const [CornerSide.all];

    if (cs.contains(CornerSide.all) || cs.isEmpty) {
      return SmoothBorderRadius(
        cornerRadius: r,
        cornerSmoothing: s,
      );
    }

    final topLeft = cs.any(
      (final c) =>
          c == CornerSide.topLeft ||
          c == CornerSide.top ||
          c == CornerSide.left,
    );
    final topRight = cs.any(
      (final c) =>
          c == CornerSide.topRight ||
          c == CornerSide.top ||
          c == CornerSide.right,
    );
    final bottomLeft = cs.any(
      (final c) =>
          c == CornerSide.bottomLeft ||
          c == CornerSide.bottom ||
          c == CornerSide.left,
    );
    final bottomRight = cs.any(
      (final c) =>
          c == CornerSide.bottomRight ||
          c == CornerSide.bottom ||
          c == CornerSide.right,
    );

    return SmoothBorderRadius.only(
      topLeft: topLeft
          ? SmoothRadius(cornerRadius: r, cornerSmoothing: s)
          : SmoothRadius.zero,
      topRight: topRight
          ? SmoothRadius(cornerRadius: r, cornerSmoothing: s)
          : SmoothRadius.zero,
      bottomLeft: bottomLeft
          ? SmoothRadius(cornerRadius: r, cornerSmoothing: s)
          : SmoothRadius.zero,
      bottomRight: bottomRight
          ? SmoothRadius(cornerRadius: r, cornerSmoothing: s)
          : SmoothRadius.zero,
    );
  }

  /// Helper method: Get BorderRadius with soft size (4px default)
  BorderRadius borderRadiusSoft({final List<CornerSide>? corners}) =>
      borderRadius(size: BorderRadiusSize.soft, corners: corners);

  /// Helper method: Get BorderRadius with small size (10px default)
  BorderRadius borderRadiusSmall({final List<CornerSide>? corners}) =>
      borderRadius(size: BorderRadiusSize.small, corners: corners);

  /// Helper method: Get BorderRadius with medium size (14px default)
  BorderRadius borderRadiusMedium({final List<CornerSide>? corners}) =>
      borderRadius(size: BorderRadiusSize.medium, corners: corners);

  /// Helper method: Get BorderRadius with large size (18px default)
  BorderRadius borderRadiusLarge({final List<CornerSide>? corners}) =>
      borderRadius(size: BorderRadiusSize.large, corners: corners);

  /// Helper method: Get BorderRadius with very large size (28px default)
  BorderRadius borderRadiusVeryLarge({final List<CornerSide>? corners}) =>
      borderRadius(size: BorderRadiusSize.veryLarge, corners: corners);

  @override
  SurfaceStyleTheme copyWith({
    final BorderShapeType? shapeType,
    final double? softRadius,
    final double? smallRadius,
    final double? mediumRadius,
    final double? largeRadius,
    final double? veryLargeRadius,
    final double? cornerSmoothing,
    final double? borderWidth,
    final Color? borderColor,
    final List<BoxShadow>? shadow,
    final EdgeInsetsGeometry? padding,
    final Color? backgroundColor,
  }) {
    return SurfaceStyleTheme(
      shapeType: shapeType ?? this.shapeType,
      softRadius: softRadius ?? this.softRadius,
      smallRadius: smallRadius ?? this.smallRadius,
      mediumRadius: mediumRadius ?? this.mediumRadius,
      largeRadius: largeRadius ?? this.largeRadius,
      veryLargeRadius: veryLargeRadius ?? this.veryLargeRadius,
      cornerSmoothing: cornerSmoothing ?? this.cornerSmoothing,
      borderWidth: borderWidth ?? this.borderWidth,
      borderColor: borderColor ?? this.borderColor,
      shadow: shadow ?? this.shadow,
      padding: padding ?? this.padding,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }

  @override
  SurfaceStyleTheme lerp(
    covariant final ThemeExtension<SurfaceStyleTheme>? other,
    final double t,
  ) {
    if (other is! SurfaceStyleTheme) return this;
    return SurfaceStyleTheme(
      shapeType: t < 0.5 ? shapeType : other.shapeType,
      softRadius: softRadius + (other.softRadius - softRadius) * t,
      smallRadius: smallRadius + (other.smallRadius - smallRadius) * t,
      mediumRadius: mediumRadius + (other.mediumRadius - mediumRadius) * t,
      largeRadius: largeRadius + (other.largeRadius - largeRadius) * t,
      veryLargeRadius:
          veryLargeRadius + (other.veryLargeRadius - veryLargeRadius) * t,
      cornerSmoothing:
          cornerSmoothing + (other.cornerSmoothing - cornerSmoothing) * t,
      borderWidth: borderWidth + (other.borderWidth - borderWidth) * t,
      borderColor: Color.lerp(borderColor, other.borderColor, t),
      shadow: shadow,
      padding: padding,
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
    );
  }
}

extension SurfaceStyleThemeEx on ThemeData {
  SurfaceStyleTheme get surfaceStyle =>
      extension<SurfaceStyleTheme>() ?? const SurfaceStyleTheme();
}


extension SurfaceShapeResolverContextEx on BuildContext {
  BorderRadius borderRadius(final BorderRadiusSize size) =>
    Theme.of(this).surfaceStyle.borderRadius(size: size);
}
