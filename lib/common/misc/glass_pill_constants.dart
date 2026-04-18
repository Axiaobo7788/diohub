import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';

/// Theme extension for glass pill UI components.
///
/// Centralizes all radius sizes, paddings, and margins used across
/// collapsible app bar, tab bar, and sticky headers.
///
/// All spacing values can be configured via the theme, ensuring visual
/// consistency across all glass pill surfaces.
class GlassPillTheme extends ThemeExtension<GlassPillTheme> {
  const GlassPillTheme({
    this.floatPadding = const EdgeInsets.fromLTRB(6, 3, 6, 2),
    this.sectionFloatInset = const EdgeInsets.symmetric(horizontal: 4),
    this.innerPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.innerPaddingExpanded = const EdgeInsets.all(16),
    this.appBarRadius = RadiusSize.xl,
    this.appBarAttachedCollapsedRadius = RadiusSize.medium,
    this.tabBarRadius = RadiusSize.large,
    this.sectionRadius = RadiusSize.medium,
    this.expandedRadius = RadiusSize.xl,
    this.wrapperRadius = RadiusSize.large,
    this.smallRadius = RadiusSize.small,
    this.metadataSectionRadius = RadiusSize.small,
    this.metadataFloatInset = const EdgeInsets.symmetric(horizontal: 6),
    this.nestedMetadataRadius = RadiusSize.soft,
    this.toolbarCollapsedPadding = const EdgeInsets.all(6),
    this.toolbarExpandedPadding = const EdgeInsets.all(12),
  });

  /// Outer padding when pills are in floating (scrolled under) state.
  /// This is the single source of truth for vertical spacing.
  final EdgeInsets floatPadding;

  /// Extra padding added on top of floatPadding for section-level pills
  /// (sticky/pinned headers). Typically used for additional horizontal insets.
  final EdgeInsets sectionFloatInset;

  /// Outer padding for section-level pills (sticky/pinned headers).
  /// Derived from floatPadding + sectionFloatInset.
  EdgeInsets get sectionFloatPadding => floatPadding + sectionFloatInset;

  /// Inner padding for content inside pills (normal state)
  final EdgeInsets innerPadding;

  /// Inner padding for content inside pills (expanded state, e.g. app bar)
  final EdgeInsets innerPaddingExpanded;

  /// Border radius size for collapsed app bar
  final RadiusSize appBarRadius;

  /// Border radius size for bottom corners of collapsed app bar in attached mode.
  /// Default is [RadiusSize.large]; top corners are always zero when attached.
  final RadiusSize appBarAttachedCollapsedRadius;

  /// Border radius size for tab bar
  final RadiusSize tabBarRadius;

  /// Border radius size for section headers (sticky/pinned)
  final RadiusSize sectionRadius;

  /// Border radius size for expanded pills
  final RadiusSize expandedRadius;

  /// Border radius size for glass wrappers
  final RadiusSize wrapperRadius;

  /// Border radius size for small pills (e.g. scroll-to-top button)
  final RadiusSize smallRadius;

  /// Border radius size for metadata section sticky headers.
  final RadiusSize metadataSectionRadius;

  /// Extra float inset for metadata section pills.
  final EdgeInsets metadataFloatInset;

  /// Border radius size for nested metadata sub-sections.
  final RadiusSize nestedMetadataRadius;

  /// Toolbar pill padding when collapsed. Default: 6.
  final EdgeInsets toolbarCollapsedPadding;

  /// Toolbar pill padding when expanded. Default: 12.
  final EdgeInsets toolbarExpandedPadding;

  /// Derived app bar margins - automatically synced with floatPadding
  /// This ensures the app bar stays visually aligned with other glass pills
  double get appBarHorizontalMargin => floatPadding.left;
  double get appBarExpandedHorizontalMargin => appBarHorizontalMargin + 4;
  double get appBarTopMargin => floatPadding.top;
  double get appBarBottomMargin => floatPadding.bottom;

  /// Derived float padding for metadata section pills.
  EdgeInsets get metadataSectionFloatPadding =>
      floatPadding + metadataFloatInset;

  @override
  GlassPillTheme copyWith({
    final EdgeInsets? floatPadding,
    final EdgeInsets? sectionFloatInset,
    final EdgeInsets? innerPadding,
    final EdgeInsets? innerPaddingExpanded,
    final RadiusSize? appBarRadius,
    final RadiusSize? appBarAttachedCollapsedRadius,
    final RadiusSize? tabBarRadius,
    final RadiusSize? sectionRadius,
    final RadiusSize? expandedRadius,
    final RadiusSize? wrapperRadius,
    final RadiusSize? smallRadius,
    final RadiusSize? metadataSectionRadius,
    final EdgeInsets? metadataFloatInset,
    final RadiusSize? nestedMetadataRadius,
    final EdgeInsets? toolbarCollapsedPadding,
    final EdgeInsets? toolbarExpandedPadding,
  }) =>
      GlassPillTheme(
        floatPadding: floatPadding ?? this.floatPadding,
        sectionFloatInset: sectionFloatInset ?? this.sectionFloatInset,
        innerPadding: innerPadding ?? this.innerPadding,
        innerPaddingExpanded: innerPaddingExpanded ?? this.innerPaddingExpanded,
        appBarRadius: appBarRadius ?? this.appBarRadius,
        appBarAttachedCollapsedRadius:
            appBarAttachedCollapsedRadius ?? this.appBarAttachedCollapsedRadius,
        tabBarRadius: tabBarRadius ?? this.tabBarRadius,
        sectionRadius: sectionRadius ?? this.sectionRadius,
        expandedRadius: expandedRadius ?? this.expandedRadius,
        wrapperRadius: wrapperRadius ?? this.wrapperRadius,
        smallRadius: smallRadius ?? this.smallRadius,
        metadataSectionRadius:
            metadataSectionRadius ?? this.metadataSectionRadius,
        metadataFloatInset: metadataFloatInset ?? this.metadataFloatInset,
        nestedMetadataRadius: nestedMetadataRadius ?? this.nestedMetadataRadius,
        toolbarCollapsedPadding:
            toolbarCollapsedPadding ?? this.toolbarCollapsedPadding,
        toolbarExpandedPadding:
            toolbarExpandedPadding ?? this.toolbarExpandedPadding,
      );

  @override
  GlassPillTheme lerp(
    covariant final ThemeExtension<GlassPillTheme>? other,
    final double t,
  ) {
    if (other is! GlassPillTheme) return this;
    return GlassPillTheme(
      floatPadding: EdgeInsets.lerp(floatPadding, other.floatPadding, t)!,
      sectionFloatInset:
          EdgeInsets.lerp(sectionFloatInset, other.sectionFloatInset, t)!,
      innerPadding: EdgeInsets.lerp(innerPadding, other.innerPadding, t)!,
      innerPaddingExpanded:
          EdgeInsets.lerp(innerPaddingExpanded, other.innerPaddingExpanded, t)!,
      appBarRadius: t < 0.5 ? appBarRadius : other.appBarRadius,
      appBarAttachedCollapsedRadius: t < 0.5
          ? appBarAttachedCollapsedRadius
          : other.appBarAttachedCollapsedRadius,
      tabBarRadius: t < 0.5 ? tabBarRadius : other.tabBarRadius,
      sectionRadius: t < 0.5 ? sectionRadius : other.sectionRadius,
      expandedRadius: t < 0.5 ? expandedRadius : other.expandedRadius,
      wrapperRadius: t < 0.5 ? wrapperRadius : other.wrapperRadius,
      smallRadius: t < 0.5 ? smallRadius : other.smallRadius,
      metadataSectionRadius:
          t < 0.5 ? metadataSectionRadius : other.metadataSectionRadius,
      metadataFloatInset:
          EdgeInsets.lerp(metadataFloatInset, other.metadataFloatInset, t)!,
      nestedMetadataRadius:
          t < 0.5 ? nestedMetadataRadius : other.nestedMetadataRadius,
      toolbarCollapsedPadding: EdgeInsets.lerp(
        toolbarCollapsedPadding,
        other.toolbarCollapsedPadding,
        t,
      )!,
      toolbarExpandedPadding: EdgeInsets.lerp(
        toolbarExpandedPadding,
        other.toolbarExpandedPadding,
        t,
      )!,
    );
  }
}

/// Extension on ThemeData to access GlassPillTheme
extension GlassPillThemeEx on ThemeData {
  GlassPillTheme get glassPill =>
      extension<GlassPillTheme>() ?? const GlassPillTheme();
}

/// Convenience extension on BuildContext to access GlassPillTheme
extension GlassPillThemeContextEx on BuildContext {
  GlassPillTheme get glassPill => Theme.of(this).glassPill;
}
