import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/common/misc/glass_pill_constants.dart';
import 'package:diohub/common/misc/glass_pill_surface.dart';
import 'package:diohub/common/wrappers/inner_box_scrolled_provider.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';

/// Resolved styling for a glass pill.
///
/// Captures all padding, radius, and color values needed to render a
/// [GlassPill]. The primary constructor resolves defaults from
/// [GlassPillTheme] via the provided [BuildContext], so callers only need
/// to specify the values they want to override.
///
/// ```dart
/// // Theme defaults (section-style):
/// GlassPillStyle(context)
///
/// // Compact resting, spacious floating:
/// GlassPillStyle(context, restingInnerPadding: EdgeInsets.zero)
///
/// // Named variant for tab bars:
/// GlassPillStyle.tabBar(context)
/// ```
@immutable
class GlassPillStyle {
  /// Creates a section-style glass pill, resolving unspecified values from
  /// the [GlassPillTheme] on [context].
  ///
  /// This is the default style used for pinned/sticky headers (search
  /// summaries, date headers, org banners). For tab-bar-specific defaults
  /// use [GlassPillStyle.tabBar].
  GlassPillStyle(
    final BuildContext context, {
    final EdgeInsets? floatingPadding,
    final EdgeInsets? restingPadding,
    final EdgeInsets? floatingInnerPadding,
    final EdgeInsets? restingInnerPadding,
    final BorderRadius? floatingRadius,
    final BorderRadius? restingRadius,
    this.restingColor,
  })  : floatingPadding =
            floatingPadding ?? context.glassPill.sectionFloatPadding,
        restingPadding = restingPadding ??
            EdgeInsets.symmetric(
              horizontal: context.glassPill.floatPadding.left,
            ),
        floatingInnerPadding =
            floatingInnerPadding ?? context.glassPill.innerPadding,
        restingInnerPadding =
            restingInnerPadding ?? context.glassPill.innerPadding,
        floatingRadius =
            floatingRadius ?? context.radius(context.glassPill.sectionRadius),
        restingRadius =
            restingRadius ?? context.radius(context.glassPill.sectionRadius);

  /// Private const constructor used by [copyWith] and named factories
  /// where all values are already resolved.
  const GlassPillStyle._({
    required this.floatingPadding,
    required this.restingPadding,
    required this.floatingInnerPadding,
    required this.restingInnerPadding,
    required this.floatingRadius,
    required this.restingRadius,
    this.restingColor,
  });

  /// Alias for the primary constructor for call-site clarity.
  ///
  /// Resolves padding and radius from [GlassPillTheme] using section-level
  /// defaults (same as the unnamed constructor).
  factory GlassPillStyle.section(
    final BuildContext context, {
    final Color? restingColor,
  }) =>
      GlassPillStyle(context, restingColor: restingColor);

  /// Metadata section style for sticky headers in the pull-to-expand area.
  ///
  /// Uses tighter radius and wider inset than the default section style,
  /// creating a compact, information-dense look.
  factory GlassPillStyle.metadataSection(
    final BuildContext context, {
    final Color? restingColor,
  }) {
    final GlassPillTheme pill = context.glassPill;
    return GlassPillStyle._(
      floatingPadding: pill.metadataSectionFloatPadding,
      restingPadding: EdgeInsets.symmetric(
        horizontal: pill.floatPadding.left,
      ),
      floatingInnerPadding: pill.innerPadding,
      restingInnerPadding: pill.innerPadding,
      floatingRadius: context.radius(pill.metadataSectionRadius),
      restingRadius: context.radius(pill.metadataSectionRadius),
      restingColor: restingColor,
    );
  }

  /// Tab bar style that animates from full-width/sharp to inset/rounded.
  ///
  /// Resolves padding and radius from [GlassPillTheme].
  /// When [attached] is true (app bar style is attached), uses zero padding
  /// and soft radius to match the app bar. Uses compact vertical inner padding
  /// (4) so the tab bar takes less height.
  factory GlassPillStyle.tabBar(
    final BuildContext context, {
    final Color? restingColor,
    final bool attached = false,
  }) {
    const double tabBarVerticalPadding = 4.0;
    final GlassPillTheme pill = context.glassPill;
    final EdgeInsets inner = EdgeInsets.only(
      top: tabBarVerticalPadding,
      bottom: tabBarVerticalPadding,
    );
    return GlassPillStyle._(
      floatingPadding: attached ? EdgeInsets.zero : pill.floatPadding,
      restingPadding: EdgeInsets.zero,
      floatingInnerPadding: inner,
      restingInnerPadding: inner,
      floatingRadius: attached
          ? context.radius(RadiusSize.soft)
          : context.radius(pill.tabBarRadius),
      restingRadius: BorderRadius.zero,
      restingColor: restingColor ?? Theme.of(context).colorScheme.surface,
    );
  }

  /// Dock pill style: zero inner padding so the pill widget owns content padding.
  ///
  /// Use for nav bar pills, action dock pills, and companion row. Pills apply
  /// their own padding (e.g. 12h, 8v) to avoid double stacking.
  factory GlassPillStyle.dockPill(
    final BuildContext context, {
    final Color? restingColor,
  }) {
    final GlassPillTheme pill = context.glassPill;
    return GlassPillStyle._(
      floatingPadding: pill.sectionFloatPadding,
      restingPadding: EdgeInsets.symmetric(horizontal: pill.floatPadding.left),
      floatingInnerPadding: EdgeInsets.zero,
      restingInnerPadding: EdgeInsets.zero,
      floatingRadius: context.radius(pill.sectionRadius),
      restingRadius: context.radius(pill.sectionRadius),
      restingColor: restingColor,
    );
  }

  /// Outer padding when the pill is in the floating (scrolled-under) state.
  final EdgeInsets floatingPadding;

  /// Outer padding when the pill is in the resting state.
  final EdgeInsets restingPadding;

  /// Inner padding between surface edge and content in the floating state.
  final EdgeInsets floatingInnerPadding;

  /// Inner padding between surface edge and content in the resting state.
  final EdgeInsets restingInnerPadding;

  /// Border radius when the pill is in the floating state.
  final BorderRadius floatingRadius;

  /// Border radius when the pill is in the resting state.
  final BorderRadius restingRadius;

  /// Solid color overlay when the pill is in the resting state.
  ///
  /// When null, [GlassPillSurface] falls back to [ColorScheme.surfaceContainerLow].
  final Color? restingColor;

  /// Creates a copy with the given fields replaced.
  GlassPillStyle copyWith({
    final EdgeInsets? floatingPadding,
    final EdgeInsets? restingPadding,
    final EdgeInsets? floatingInnerPadding,
    final EdgeInsets? restingInnerPadding,
    final BorderRadius? floatingRadius,
    final BorderRadius? restingRadius,
    final Color? restingColor,
  }) =>
      GlassPillStyle._(
        floatingPadding: floatingPadding ?? this.floatingPadding,
        restingPadding: restingPadding ?? this.restingPadding,
        floatingInnerPadding: floatingInnerPadding ?? this.floatingInnerPadding,
        restingInnerPadding: restingInnerPadding ?? this.restingInnerPadding,
        floatingRadius: floatingRadius ?? this.floatingRadius,
        restingRadius: restingRadius ?? this.restingRadius,
        restingColor: restingColor ?? this.restingColor,
      );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is GlassPillStyle &&
          runtimeType == other.runtimeType &&
          floatingPadding == other.floatingPadding &&
          restingPadding == other.restingPadding &&
          floatingInnerPadding == other.floatingInnerPadding &&
          restingInnerPadding == other.restingInnerPadding &&
          floatingRadius == other.floatingRadius &&
          restingRadius == other.restingRadius &&
          restingColor == other.restingColor;

  @override
  int get hashCode => Object.hash(
        floatingPadding,
        restingPadding,
        floatingInnerPadding,
        restingInnerPadding,
        floatingRadius,
        restingRadius,
        restingColor,
      );
}

/// A pill-shaped surface that animates between resting (solid color) and
/// floating (glass effect) states.
///
/// All styling is resolved by the provided [GlassPillStyle], which defaults
/// to theme values via [BuildContext]:
///
/// ```dart
/// GlassPill(
///   style: GlassPillStyle(context),
///   isFloating: isScrolledUnder,
///   child: header,
/// )
/// ```
///
/// Override individual values directly in the constructor:
///
/// ```dart
/// GlassPill(
///   style: GlassPillStyle(context, restingInnerPadding: EdgeInsets.zero),
///   isFloating: true,
///   child: content,
/// )
/// ```
///
/// Inner padding is lerped between states just like outer padding and radius.
class GlassPill extends StatelessWidget {
  const GlassPill({
    required this.style,
    required this.isFloating,
    required this.child,
    super.key,
  });

  /// The resolved styling for this pill.
  final GlassPillStyle style;

  /// Whether the pill is in the floating (glass) or resting (solid) state.
  final bool isFloating;

  /// The content to display inside the pill.
  final Widget child;

  @override
  Widget build(final BuildContext context) => TweenAnimationBuilder<double>(
        duration: kStateDuration,
        curve: kStateCurve,
        tween: Tween(end: isFloating ? 1.0 : 0.0),
        builder: (final BuildContext context, final double t, final _) =>
            Padding(
          padding:
              EdgeInsets.lerp(style.restingPadding, style.floatingPadding, t)!,
          child: GlassPillSurface(
            borderRadius: BorderRadius.lerp(
              style.restingRadius,
              style.floatingRadius,
              t,
            )!,
            glassReveal: t,
            animate: false,
            restingColor: style.restingColor,
            innerPadding: EdgeInsets.lerp(
              style.restingInnerPadding,
              style.floatingInnerPadding,
              t,
            ),
            child: child,
          ),
        ),
      );
}

/// Reusable pill that shows solid when resting and glass when content has
/// scrolled under, reading [InnerBoxScrolledProvider.of](context) internally.
///
/// Use under [InnerBoxScrolledProvider]; the widget reads the value and
/// builds [GlassPill] with the correct isFloating state.
///
/// Example:
/// ```dart
/// ScrollUnderGlass(
///   style: GlassPillStyle.section(context),
///   child: MyHeaderContent(),
/// )
/// ```
class ScrollUnderGlass extends StatelessWidget {
  const ScrollUnderGlass({
    required this.child,
    this.style,
    super.key,
  });

  /// Glass pill styling. Defaults to [GlassPillStyle.section] when null.
  final GlassPillStyle? style;

  final Widget child;

  @override
  Widget build(final BuildContext context) {
    final bool isFloating = InnerBoxScrolledProvider.of(context);
    final GlassPillStyle effectiveStyle =
        style ?? GlassPillStyle.section(context);
    return GlassPill(
      style: effectiveStyle,
      isFloating: isFloating,
      child: child,
    );
  }
}
