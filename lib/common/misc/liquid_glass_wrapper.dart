import 'dart:math';
import 'dart:ui' as ui;

import 'package:diohub/app/settings/appearance.dart' as app_settings;
import 'package:diohub/providers/settings/appearance_provider.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings for portable glass effects with app-tuned defaults.
///
/// Keeps the material controls independent from the renderer so callers do not
/// depend on a platform-specific shader package.
class GlassSettings {
  const GlassSettings({
    this.blur = 8,
    this.thickness = 6.5,
    this.refractiveIndex = 1.3,
    this.chromaticAberration = 0.1,
    this.lightIntensity = 0.4,
    this.saturation = 1.2,
    this.visibility = 1.0,
    this.lightAngle = 0.5 * pi,
    this.ambientStrength = 0,
    this.glassColor = _defaultGlassColor,
    this.borderWidth = 0.5,
    this.borderColor = _defaultBorderColor,
    this.borderRadiusDelta,
    this.specularAlpha = 0.03,
  });

  final double blur;
  final double thickness;
  final double refractiveIndex;
  final double chromaticAberration;
  final double lightIntensity;
  final double saturation;
  final double visibility;
  final double lightAngle;
  final double ambientStrength;
  final Color Function(BuildContext) glassColor;
  final double borderWidth;
  final Color Function(BuildContext) borderColor;
  final double? borderRadiusDelta;
  final double specularAlpha;

  static Color _defaultGlassColor(final BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest.tintMedium;

  static Color _defaultBorderColor(final BuildContext context) =>
      Theme.of(context).colorScheme.outline.tint;

  /// Builds [GlassSettings] from persisted [app_settings.AppearanceSettings] and theme.
  /// Used when [LiquidGlassWrapper] has no custom [settings] (null).
  static GlassSettings fromAppearance(
    final app_settings.AppearanceSettings app,
    final BuildContext context,
  ) => GlassSettings(
    blur: app.glassBlur,
    thickness: app.glassThickness,
    lightIntensity: app.glassLightIntensity,
    visibility: app.glassVisibility,
    borderWidth: app.glassBorderWidth,
    specularAlpha: 0.03,
  );

  /// Creates a scaled variant of this settings.
  ///
  /// Only [blurScale] and [opacityScale] affect the glass material properties.
  /// This ensures consistent glass character across the app while allowing
  /// controlled visual weight adjustments for attention-demanding states.
  GlassSettings scaled({
    final double blurScale = 1.0,
    final double opacityScale = 1.0,
    final double? borderRadiusDelta,
    final double? borderWidth,
    final Color Function(BuildContext)? borderColor,
  }) => GlassSettings(
    blur: blur * blurScale,
    thickness: thickness,
    refractiveIndex: refractiveIndex,
    chromaticAberration: chromaticAberration,
    lightIntensity: lightIntensity,
    saturation: saturation,
    visibility: visibility,
    lightAngle: lightAngle,
    ambientStrength: ambientStrength,
    glassColor: opacityScale == 1.0
        ? glassColor
        : (final BuildContext context) {
            final ui.Color base = glassColor(context);
            return base.withValues(
              alpha: (base.opacity * opacityScale).clamp(0.0, 1.0),
            );
          },
    borderWidth: borderWidth ?? this.borderWidth,
    borderColor: borderColor ?? this.borderColor,
    borderRadiusDelta: borderRadiusDelta ?? this.borderRadiusDelta,
    specularAlpha: specularAlpha,
  );

  /// Returns a copy with the given fields replaced. Used to merge app defaults
  /// with animation overrides (e.g. glass pill reveal).
  GlassSettings copyWith({
    final double? blur,
    final double? thickness,
    final double? borderWidth,
    final double? borderRadiusDelta,
    final Color Function(BuildContext)? glassColor,
    final Color Function(BuildContext)? borderColor,
    final double? specularAlpha,
  }) => GlassSettings(
    blur: blur ?? this.blur,
    thickness: thickness ?? this.thickness,
    refractiveIndex: refractiveIndex,
    chromaticAberration: chromaticAberration,
    lightIntensity: lightIntensity,
    saturation: saturation,
    visibility: visibility,
    lightAngle: lightAngle,
    ambientStrength: ambientStrength,
    glassColor: glassColor ?? this.glassColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderColor: borderColor ?? this.borderColor,
    borderRadiusDelta: borderRadiusDelta ?? this.borderRadiusDelta,
    specularAlpha: specularAlpha ?? this.specularAlpha,
  );
}

/// A reusable wrapper for glass effects with tuned defaults.
///
/// Reads [app_settings.SurfaceRendering] from [appearanceProvider] and branches:
/// glass, blur (both BackdropFilter variants), or solid (opaque surface).
///
/// **Basic usage:**
/// ```dart
/// LiquidGlassWrapper(
///   size: RadiusSize.large,
///   child: YourWidget(),
/// )
/// ```
///
/// When [settings] is null (default), values from [appearanceProvider] are used.
///
/// **Custom settings:**
/// ```dart
/// LiquidGlassWrapper(
///   size: RadiusSize.xl,
///   settings: GlassSettings(
///     blur: 40,
///     glassColor: (context) => Theme.of(context).colorScheme.primary.tintStrong,
///     borderWidth: 1.0,
///   ),
///   child: YourWidget(),
/// )
/// ```
class LiquidGlassWrapper extends ConsumerWidget {
  const LiquidGlassWrapper({
    required this.child,
    required this.size,
    this.corners,
    this.settings,
    this.surfaceRenderingOverride,
    this.borderOverride,
    this.borderRadiusOverride,
    super.key,
  });

  final Widget child;
  final RadiusSize size;
  final List<Corner>? corners;

  /// When null, use app default from [appearanceProvider]. Pass custom
  /// [GlassSettings] to override (e.g. toolbar tension scaling).
  final GlassSettings? settings;

  /// When set, use this instead of [appearanceProvider]. Keeps the same visual
  /// (e.g. blur) regardless of user setting; use for overlay cards that must
  /// not rebuild when the user changes surface style (e.g. onboarding).
  final app_settings.SurfaceRendering? surfaceRenderingOverride;

  /// When non-null, use this border instead of building from [GlassSettings].
  /// Used e.g. for attached app bar (left/right/bottom only, no top).
  final Border? borderOverride;

  /// When non-null, use this for clip and decoration shape instead of single
  /// radius from [size] + [GlassSettings.borderRadiusDelta]. Enables per-corner
  /// radii (e.g. top 0, bottom r when attached).
  final BorderRadius? borderRadiusOverride;

  bool get _hasCustomCorners => corners != null && corners!.isNotEmpty;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final app_settings.AppearanceSettings appearance = ref.watch(
      appearanceProvider,
    );
    final GlassSettings effectiveSettings =
        settings ?? GlassSettings.fromAppearance(appearance, context);
    final app_settings.SurfaceRendering surfaceRendering =
        surfaceRenderingOverride ?? appearance.surfaceRendering;
    final ColorScheme colorScheme = context.colorScheme;
    final SurfaceStyle surface = context.surface;
    final double effectiveRadius =
        surface.radius(size) + (effectiveSettings.borderRadiusDelta ?? 0);

    final ShapeBorder clipShape;
    final Border? border;

    if (borderRadiusOverride != null) {
      clipShape = RoundedRectangleBorder(borderRadius: borderRadiusOverride!);
      border =
          borderOverride ??
          (effectiveSettings.borderWidth > 0
              ? Border.all(
                  color: effectiveSettings.borderColor(context),
                  width: effectiveSettings.borderWidth,
                )
              : null);
    } else {
      clipShape = context.surfaceShape(
        size,
        corners: corners,
        radiusOverride: effectiveRadius,
      );
      border =
          borderOverride ??
          (effectiveSettings.borderWidth > 0
              ? Border.all(
                  color: effectiveSettings.borderColor(context),
                  width: effectiveSettings.borderWidth,
                )
              : null);
    }

    final BorderRadius? effectiveBorderRadius =
        borderRadiusOverride ?? BorderRadius.circular(effectiveRadius);
    final Border? safeBorder = _safeBorderForDecoration(
      border,
      effectiveBorderRadius,
    );

    switch (surfaceRendering) {
      case app_settings.SurfaceRendering.glass:
        return _buildBlur(
          context,
          effectiveRadius,
          clipShape,
          safeBorder,
          effectiveSettings.glassColor(context),
          effectiveSettings,
        );
      case app_settings.SurfaceRendering.blur:
        return _buildBlur(
          context,
          effectiveRadius,
          clipShape,
          safeBorder,
          colorScheme.surfaceContainerHighest.tintStrong,
          effectiveSettings,
        );
      case app_settings.SurfaceRendering.solid:
        return _buildSolid(
          context,
          effectiveRadius,
          clipShape,
          safeBorder,
          colorScheme.surfaceContainer,
          effectiveSettings,
        );
    }
  }

  /// Returns a border safe to use with [BoxDecoration] when [borderRadius] is
  /// non-zero. Flutter asserts that a hairline border (any side with width 0)
  /// can only be drawn when borderRadius is null or zero. When radius is
  /// non-zero and [border] has any zero-width side, returns null to avoid the
  /// assertion; otherwise returns [border] unchanged.
  static Border? _safeBorderForDecoration(
    final Border? border,
    final BorderRadius? borderRadius,
  ) {
    if (border == null) return null;
    final bool radiusIsZero =
        borderRadius == null ||
        (borderRadius.topLeft.x == 0 &&
            borderRadius.topRight.x == 0 &&
            borderRadius.bottomLeft.x == 0 &&
            borderRadius.bottomRight.x == 0);
    if (radiusIsZero) return border;
    final bool hasHairline =
        border.left.width == 0 ||
        border.top.width == 0 ||
        border.right.width == 0 ||
        border.bottom.width == 0;
    if (!hasHairline) return border;
    return null;
  }

  Widget _buildBlur(
    final BuildContext context,
    final double effectiveRadius,
    final ShapeBorder clipShape,
    final Border? border,
    final ui.Color fillColor,
    final GlassSettings effectiveSettings,
  ) {
    final Decoration decoration = borderRadiusOverride != null
        ? BoxDecoration(
            color: fillColor,
            borderRadius: borderRadiusOverride,
            border: border,
          )
        : context.surfaceDecoration(
            size,
            corners: corners,
            color: fillColor,
            border: border,
            radiusOverride: effectiveRadius,
          );

    final Widget blurred = BackdropFilter(
      filter: ui.ImageFilter.blur(
        sigmaX: effectiveSettings.blur,
        sigmaY: effectiveSettings.blur,
      ),
      child: DecoratedBox(decoration: decoration, child: child),
    );

    final Widget content = Stack(
      children: <Widget>[
        blurred,
        _topEdgeSpecular(context, effectiveSettings.specularAlpha),
      ],
    );

    return ClipPath(
      clipper: ShapeBorderClipper(shape: clipShape),
      child: content,
    );
  }

  static const double _kSpecularHeight = 4.0;

  Widget _topEdgeSpecular(
    final BuildContext context,
    final double specularAlpha,
  ) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: _kSpecularHeight,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                colorScheme.onSurface.withValues(alpha: specularAlpha),
                colorScheme.onSurface.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSolid(
    final BuildContext context,
    final double effectiveRadius,
    final ShapeBorder clipShape,
    final Border? border,
    final ui.Color fillColor,
    final GlassSettings effectiveSettings,
  ) {
    final Decoration decoration = borderRadiusOverride != null
        ? BoxDecoration(
            color: fillColor,
            borderRadius: borderRadiusOverride,
            border: border,
          )
        : context.surfaceDecoration(
            size,
            corners: corners,
            color: fillColor,
            border: border,
            radiusOverride: effectiveRadius,
          );

    final Widget content = Stack(
      children: <Widget>[
        DecoratedBox(decoration: decoration, child: child),
        _topEdgeSpecular(context, effectiveSettings.specularAlpha),
      ],
    );

    return ClipPath(
      clipper: ShapeBorderClipper(shape: clipShape),
      child: content,
    );
  }
}
