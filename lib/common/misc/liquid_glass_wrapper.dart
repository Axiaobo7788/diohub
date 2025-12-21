import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// A reusable wrapper for liquid glass effects with sensible defaults.
///
/// Provides a consistent liquid glass appearance across the app with
/// theme-aware defaults. Can be used standalone or with a shape.
///
/// **Usage:**
/// ```dart
/// // Basic usage with defaults
/// LiquidGlassWrapper(
///   child: YourWidget(),
/// )
///
/// // With custom settings
/// LiquidGlassWrapper(
///   blur: 15,
///   glassColorOpacity: 0.3,
///   child: YourWidget(),
/// )
///
/// // With shape (for rounded corners)
/// LiquidGlassWrapper.withShape(
///   borderRadius: 28,
///   child: YourWidget(),
/// )
/// ```
class LiquidGlassWrapper extends StatelessWidget {
  const LiquidGlassWrapper({
    required this.child,
    this.blur,
    this.glassColor,
    this.glassColorOpacity,
    this.thickness,
    this.refractiveIndex,
    this.borderRadius,
    this.borderColor,
    this.borderWidth,
    super.key,
  });

  /// Creates a liquid glass wrapper with a rounded rectangle shape.
  ///
  /// This is useful for buttons, cards, or other widgets that need
  /// rounded corners with the glass effect.
  LiquidGlassWrapper.withShape({
    required this.child,
    this.borderRadius = 28,
    this.blur,
    this.glassColor,
    this.glassColorOpacity,
    this.thickness,
    this.refractiveIndex,
    this.borderColor,
    this.borderWidth = 0.5,
    super.key,
  });

  final Widget child;

  /// Blur amount (sigma). Defaults to 12.
  final double? blur;

  /// Custom glass color. If null, uses theme's surfaceContainerHighest.
  final Color? glassColor;

  /// Opacity for the glass color. Defaults to 0.25.
  final double? glassColorOpacity;

  /// Thickness of the glass effect. Defaults to 2.5.
  final double? thickness;

  /// Refractive index for the glass effect. Defaults to 1.5.
  final double? refractiveIndex;

  /// Border radius for the shape variant. Only used with [withShape] constructor.
  final double? borderRadius;

  /// Border color for the shape variant. Defaults to outline color with 0.15 opacity.
  final Color? borderColor;

  /// Border width for the shape variant. Defaults to 0.5.
  final double? borderWidth;

  /// Whether this wrapper uses a shape (from [withShape] constructor).
  bool get _hasShape => borderRadius != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveBlur = blur ?? 12.0;
    final effectiveGlassColor = glassColor ??
        colorScheme.surfaceContainerHighest
            .withOpacity(glassColorOpacity ?? 0.25);
    final effectiveThickness = thickness ?? 2.5;
    final effectiveRefractiveIndex = refractiveIndex ?? 1.5;

    final glassLayer = LiquidGlassLayer(
      settings: LiquidGlassSettings(
        blur: effectiveBlur,
        glassColor: effectiveGlassColor,
        thickness: effectiveThickness,
        refractiveIndex: effectiveRefractiveIndex,
      ),
      child: _hasShape
          ? LiquidGlass(
              shape: LiquidRoundedRectangle(
                borderRadius: borderRadius!,
              ),
              child: _buildShapedChild(context, colorScheme),
            )
          : child,
    );

    return glassLayer;
  }

  Widget _buildShapedChild(BuildContext context, ColorScheme colorScheme) {
    final effectiveBorderColor =
        borderColor ?? colorScheme.outline.withOpacity(0.15);
    final effectiveBorderWidth = borderWidth ?? 0.5;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius!),
        border: Border.all(
          color: effectiveBorderColor,
          width: effectiveBorderWidth,
        ),
      ),
      child: child,
    );
  }
}
