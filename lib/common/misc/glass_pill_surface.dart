import 'dart:ui' as ui;

import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/common/misc/glass_pill_constants.dart';
import 'package:diohub/common/misc/liquid_glass_wrapper.dart';
import 'package:diohub/providers/settings/appearance_provider.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A rounded surface that transitions between solid color and glass effect.
///
/// This is the lowest-level visual primitive for glass pills. It handles only
/// the visual rendering: `LiquidGlassWrapper` + fading color overlay + border.
/// It does NOT handle padding, margins, or sizing -- those are the caller's
/// responsibility.
///
/// Supports both gradual (scroll-driven) and discrete (bool-flip) transitions
/// via the [animate] flag.
///
/// Example (scroll-driven):
/// ```dart
/// GlassPillSurface(
///   borderRadius: dynamicRadius,
///   glassReveal: 0.7, // 70% glass, 30% solid
///   animate: false, // caller drives the value per frame
///   child: content,
/// )
/// ```
///
/// Example (bool-flip with implicit animation):
/// ```dart
/// GlassPillSurface(
///   borderRadius: BorderRadius.circular(18),
///   glassReveal: isScrolledUnder ? 1.0 : 0.0,
///   animate: true, // TweenAnimationBuilder smooths the transition
///   child: content,
/// )
/// ```
class GlassPillSurface extends ConsumerWidget {
  const GlassPillSurface({
    required this.child,
    required this.borderRadius,
    this.glassReveal = 0.0,
    this.animate = true,
    this.restingColor,
    this.innerPadding,
    this.border,
    super.key,
  }) : assert(
          !(glassReveal == 0.0 && animate),
          'GlassPillSurface created with glassReveal: 0.0 and animate: true. '
          'This renders a fully solid surface. Pass glassReveal: 1.0 for glass, '
          'or animate: false if this is a scroll-driven starting value.',
        );

  /// The content to display inside the glass surface.
  final Widget child;

  /// The border radius for the surface. Clips the glass shape to this radius.
  final BorderRadius borderRadius;

  /// When non-null, use this border instead of building from settings.
  /// Used e.g. for attached app bar (left/right/bottom only, no top).
  final Border? border;

  /// Glass reveal progress: 0.0 = fully solid, 1.0 = fully glass.
  ///
  /// Controls the opacity of the solid color overlay (opacity = 1 - glassReveal)
  /// and the border width (0.0 -> 0.5 as glass reveals).
  final double glassReveal;

  /// Whether to animate the glass reveal with implicit animation.
  ///
  /// - `true`: Wraps opacity in `TweenAnimationBuilder` for smooth transitions
  ///   when [glassReveal] changes. Use for bool-flip consumers.
  /// - `false`: Applies [glassReveal] directly without animation. Use for
  ///   scroll-driven consumers where the value already changes per frame.
  final bool animate;

  /// The solid color when glass is not revealed (defaults to surfaceContainer).
  final Color? restingColor;

  /// Inner padding between surface edge and content.
  /// Defaults to context.glassPill.innerPadding if not provided.
  final EdgeInsets? innerPadding;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final ui.Color color = restingColor ?? colorScheme.surfaceContainer;
    final RadiusSize wrapperRadius = context.glassPill.wrapperRadius;
    final EdgeInsets effectiveInnerPadding =
        innerPadding ?? context.glassPill.innerPadding;
    final GlassSettings base = GlassSettings.fromAppearance(
      ref.watch(appearanceProvider),
      context,
    );

    // Compute delta between animated clip radius and base wrapper radius
    final double baseWrapperRadius = context.surface.radius(wrapperRadius);
    final double radiusDelta = borderRadius.topLeft.x - baseWrapperRadius;

    Widget buildSurface(final double revealProgress) {
      final double solidOpacity = (1.0 - revealProgress).clamp(0.0, 1.0);
      final double borderWidth =
          ui.lerpDouble(0.0, base.borderWidth, revealProgress) ?? 0.0;

      return LiquidGlassWrapper(
        size: wrapperRadius,
        settings: base.copyWith(
          borderWidth: borderWidth,
          borderRadiusDelta: radiusDelta,
          blur: ui.lerpDouble(0, base.blur, revealProgress) ?? 0,
          thickness: ui.lerpDouble(0, base.thickness, revealProgress) ?? 0,
          specularAlpha:
              ui.lerpDouble(0, base.specularAlpha, revealProgress) ?? 0,
        ),
        borderOverride: border,
        borderRadiusOverride: borderRadius,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: color.withValues(alpha: solidOpacity),
                ),
              ),
            ),
            Padding(
              padding: effectiveInnerPadding,
              child: child,
            ),
          ],
        ),
      );
    }

    if (animate) {
      return TweenAnimationBuilder<double>(
        duration: kStateDuration,
        curve: kStateCurve,
        tween: Tween(end: glassReveal),
        builder: (final BuildContext context, final double animatedReveal,
                final _) =>
            buildSurface(animatedReveal),
      );
    }

    return buildSurface(glassReveal);
  }
}
