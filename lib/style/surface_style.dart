import 'package:flutter/material.dart';

/// Standard border radius sizes used throughout the app
enum RadiusSize {
  soft,
  small,
  medium,
  large,
  xl,
}

/// Border style type - controls which implementation is used
enum SurfaceShape {
  /// Standard rounded rectangle border
  rounded,

  /// iOS-style superellipse (smooth corners)
  squircle,
}

/// Specifies which corners should have rounded borders
enum Corner {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

/// Specifies which side a border should appear on
enum BorderSideType {
  top,
  bottom,
  left,
  right,
}

/// Shortcut groups for corner combinations
extension CornerGroups on Corner {
  static const List<Corner> top = <Corner>[Corner.topLeft, Corner.topRight];
  static const List<Corner> bottom = <Corner>[
    Corner.bottomLeft,
    Corner.bottomRight
  ];
  static const List<Corner> left = <Corner>[Corner.topLeft, Corner.bottomLeft];
  static const List<Corner> right = <Corner>[
    Corner.topRight,
    Corner.bottomRight
  ];
}

/// Theme extension for surface styling (shapes, borders, shadows, radii)
///
/// This centralizes all surface styling decisions for containers, cards, dialogs, etc.
/// Uses a map-based design for radii to eliminate per-size boilerplate.
class SurfaceStyle extends ThemeExtension<SurfaceStyle> {
  const SurfaceStyle({
    this.shape = SurfaceShape.squircle,
    this.radii = const <RadiusSize, double>{
      RadiusSize.soft: 4,
      RadiusSize.small: 10,
      RadiusSize.medium: 14,
      RadiusSize.large: 18,
      RadiusSize.xl: 28,
    },
    this.smoothing = 0.5,
  });

  final SurfaceShape shape;
  final Map<RadiusSize, double> radii;
  final double smoothing;

  /// Get radius value for a given size
  double radius(final RadiusSize size) => radii[size] ?? 0;

  @override
  SurfaceStyle copyWith({
    final SurfaceShape? shape,
    final Map<RadiusSize, double>? radii,
    final double? smoothing,
  }) =>
      SurfaceStyle(
        shape: shape ?? this.shape,
        radii: radii ?? this.radii,
        smoothing: smoothing ?? this.smoothing,
      );

  @override
  SurfaceStyle lerp(
    covariant final ThemeExtension<SurfaceStyle>? other,
    final double t,
  ) {
    if (other is! SurfaceStyle) return this;
    return SurfaceStyle(
      shape: t < 0.5 ? shape : other.shape,
      radii: <RadiusSize, double>{
        for (final RadiusSize size in RadiusSize.values)
          size: radius(size) + (other.radius(size) - radius(size)) * t,
      },
      smoothing: smoothing + (other.smoothing - smoothing) * t,
    );
  }
}

/// Extension on ThemeData to access SurfaceStyle
extension SurfaceStyleEx on ThemeData {
  SurfaceStyle get surface => extension<SurfaceStyle>() ?? const SurfaceStyle();
}
