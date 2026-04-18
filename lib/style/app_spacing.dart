import 'package:flutter/material.dart';

/// Theme extension for app-wide spacing values.
///
/// Centralizes all spacing constants to ensure visual consistency and make
/// spacing tweakable from a single source. Categorized into:
/// - List layout (horizontal insets, item spacing, bottom padding)
/// - Screen layout (screen padding, page padding, section spacing)
/// - Card layout (content padding inside cards)
/// - Element layout (chip padding, badge padding, etc.)
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    // Category 1: List layout
    this.listInset = const EdgeInsets.symmetric(horizontal: 8),
    this.itemSpacing = 8.0,
    this.listPaddingBottom = 16.0,
    // Category 2: Screen layout
    this.screenPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.pagePadding = const EdgeInsets.all(16),
    this.sectionSpacing = 16.0,
    // Category 3: Card layout
    this.cardContentPadding =
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    // Category 4: Element layout
    this.contentPadding = const EdgeInsets.all(12),
    this.spaciousPadding = const EdgeInsets.all(24),
    this.emptyStatePadding = const EdgeInsets.all(32),
    this.chipPadding = const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    this.badgePadding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    // New tokens
    this.chipGap = 4.0,
    this.inputPadding =
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.tightSpacing = 4.0,
    this.compactSpacing = 6.0,
    this.sheetPadding = const EdgeInsets.fromLTRB(24, 12, 24, 8),
    this.sectionTitlePaddingLarge = const EdgeInsets.fromLTRB(16, 20, 16, 12),
    this.sectionTitlePaddingMedium = const EdgeInsets.fromLTRB(16, 16, 16, 8),
    this.metadataRowStackGap = 4.0,
    this.metadataRowValueTopGap = 5.0,
  });

  // ---------------------------------------------------------------------------
  // Category 1: List layout
  // ---------------------------------------------------------------------------

  /// Horizontal inset for content items in scrollable lists.
  /// Applied by paddingBuilder in InfinitePaginationController.
  /// Default: horizontal 8px (cards sit 8px from screen edge).
  final EdgeInsets listInset;

  /// Vertical spacing between consecutive content items.
  /// Applied by item wrappers or separators.
  /// Default: 8px.
  final double itemSpacing;

  /// Bottom padding after the last item (before safe area).
  /// Safe area is added on top of this by the consumer.
  /// Default: 16px.
  final double listPaddingBottom;

  // ---------------------------------------------------------------------------
  // Category 2: Screen layout
  // ---------------------------------------------------------------------------

  /// Standard horizontal padding for screen-level content.
  /// Used for margins around major sections, search bars, etc.
  /// Default: horizontal 16px.
  final EdgeInsets screenPadding;

  /// Standard padding for full-page content areas.
  /// Used for error states, empty states, loading screens.
  /// Default: all 16px.
  final EdgeInsets pagePadding;

  /// Vertical spacing between major sections (headers, content groups).
  /// Default: 16px.
  final double sectionSpacing;

  // ---------------------------------------------------------------------------
  // Category 3: Card layout
  // ---------------------------------------------------------------------------

  /// Internal padding for card content.
  /// Applied by BorderedContainer as the default.
  /// Default: horizontal 12px, vertical 8px.
  final EdgeInsets cardContentPadding;

  // ---------------------------------------------------------------------------
  // Category 4: Element layout
  // ---------------------------------------------------------------------------

  /// Padding for medium content areas (panels, info sections, stat containers).
  /// Default: all 12px.
  final EdgeInsets contentPadding;

  /// Generous padding for placeholder/status messages that need breathing room.
  /// Default: all 24px.
  final EdgeInsets spaciousPadding;

  /// Large padding for empty states, error views, centered loading indicators.
  /// Default: all 32px.
  final EdgeInsets emptyStatePadding;

  /// Padding inside compact chips and tags.
  /// Default: horizontal 6px, vertical 3px.
  final EdgeInsets chipPadding;

  /// Padding inside tiny badges and count indicators.
  /// Default: horizontal 6px, vertical 2px.
  final EdgeInsets badgePadding;

  /// Horizontal and vertical spacing between chips in Wrap layouts.
  /// Default: 4px.
  final double chipGap;

  /// Padding for text fields, option list rows, search bar inner. Default: 12h, 10v.
  final EdgeInsets inputPadding;

  /// Minimal gap (icons, compact UI). Default: 4px.
  final double tightSpacing;

  /// Medium-density inline gap (between tightSpacing and itemSpacing).
  /// Used for icon-to-text, Wrap spacing, avatar overflow count gaps.
  /// Default: 6px.
  final double compactSpacing;

  /// Standard padding for metadata row-level widgets (label + value rows).
  /// Computed from screenPadding horizontal + cardContentPadding vertical.
  EdgeInsets get metadataRowPadding => EdgeInsets.fromLTRB(
        screenPadding.left,
        cardContentPadding.top,
        screenPadding.right,
        cardContentPadding.bottom,
      );

  /// Bottom sheet / modal content padding. Default: LTRB 24, 12, 24, 8.
  final EdgeInsets sheetPadding;

  /// Section header title padding (large style). Default: LTRB 16, 20, 16, 12.
  final EdgeInsets sectionTitlePaddingLarge;

  /// Section header title padding (medium/small style). Default: LTRB 16, 16, 16, 8.
  final EdgeInsets sectionTitlePaddingMedium;

  /// Vertical gap between label and value in stacked metadata rows.
  /// Default: 4.
  final double metadataRowStackGap;

  /// Vertical gap between label and value content in stacked metadata rows.
  /// Default: 5.
  final double metadataRowValueTopGap;

  @override
  AppSpacing copyWith({
    final EdgeInsets? listInset,
    final double? itemSpacing,
    final double? listPaddingBottom,
    final EdgeInsets? screenPadding,
    final EdgeInsets? pagePadding,
    final double? sectionSpacing,
    final EdgeInsets? cardContentPadding,
    final EdgeInsets? contentPadding,
    final EdgeInsets? spaciousPadding,
    final EdgeInsets? emptyStatePadding,
    final EdgeInsets? chipPadding,
    final EdgeInsets? badgePadding,
    final double? chipGap,
    final EdgeInsets? inputPadding,
    final double? tightSpacing,
    final double? compactSpacing,
    final EdgeInsets? sheetPadding,
    final EdgeInsets? sectionTitlePaddingLarge,
    final EdgeInsets? sectionTitlePaddingMedium,
    final double? metadataRowStackGap,
    final double? metadataRowValueTopGap,
  }) =>
      AppSpacing(
        listInset: listInset ?? this.listInset,
        itemSpacing: itemSpacing ?? this.itemSpacing,
        listPaddingBottom: listPaddingBottom ?? this.listPaddingBottom,
        screenPadding: screenPadding ?? this.screenPadding,
        pagePadding: pagePadding ?? this.pagePadding,
        sectionSpacing: sectionSpacing ?? this.sectionSpacing,
        cardContentPadding: cardContentPadding ?? this.cardContentPadding,
        contentPadding: contentPadding ?? this.contentPadding,
        spaciousPadding: spaciousPadding ?? this.spaciousPadding,
        emptyStatePadding: emptyStatePadding ?? this.emptyStatePadding,
        chipPadding: chipPadding ?? this.chipPadding,
        badgePadding: badgePadding ?? this.badgePadding,
        chipGap: chipGap ?? this.chipGap,
        inputPadding: inputPadding ?? this.inputPadding,
        tightSpacing: tightSpacing ?? this.tightSpacing,
        compactSpacing: compactSpacing ?? this.compactSpacing,
        sheetPadding: sheetPadding ?? this.sheetPadding,
        sectionTitlePaddingLarge:
            sectionTitlePaddingLarge ?? this.sectionTitlePaddingLarge,
        sectionTitlePaddingMedium:
            sectionTitlePaddingMedium ?? this.sectionTitlePaddingMedium,
        metadataRowStackGap: metadataRowStackGap ?? this.metadataRowStackGap,
        metadataRowValueTopGap:
            metadataRowValueTopGap ?? this.metadataRowValueTopGap,
      );

  @override
  AppSpacing lerp(
    covariant final ThemeExtension<AppSpacing>? other,
    final double t,
  ) {
    if (other is! AppSpacing) return this;
    return AppSpacing(
      listInset: EdgeInsets.lerp(listInset, other.listInset, t)!,
      itemSpacing: t < 0.5 ? itemSpacing : other.itemSpacing,
      listPaddingBottom: t < 0.5 ? listPaddingBottom : other.listPaddingBottom,
      screenPadding: EdgeInsets.lerp(screenPadding, other.screenPadding, t)!,
      pagePadding: EdgeInsets.lerp(pagePadding, other.pagePadding, t)!,
      sectionSpacing: t < 0.5 ? sectionSpacing : other.sectionSpacing,
      cardContentPadding:
          EdgeInsets.lerp(cardContentPadding, other.cardContentPadding, t)!,
      contentPadding: EdgeInsets.lerp(contentPadding, other.contentPadding, t)!,
      spaciousPadding:
          EdgeInsets.lerp(spaciousPadding, other.spaciousPadding, t)!,
      emptyStatePadding:
          EdgeInsets.lerp(emptyStatePadding, other.emptyStatePadding, t)!,
      chipPadding: EdgeInsets.lerp(chipPadding, other.chipPadding, t)!,
      badgePadding: EdgeInsets.lerp(badgePadding, other.badgePadding, t)!,
      chipGap: t < 0.5 ? chipGap : other.chipGap,
      inputPadding: EdgeInsets.lerp(inputPadding, other.inputPadding, t)!,
      tightSpacing: t < 0.5 ? tightSpacing : other.tightSpacing,
      compactSpacing: t < 0.5 ? compactSpacing : other.compactSpacing,
      sheetPadding: EdgeInsets.lerp(sheetPadding, other.sheetPadding, t)!,
      sectionTitlePaddingLarge: EdgeInsets.lerp(
        sectionTitlePaddingLarge,
        other.sectionTitlePaddingLarge,
        t,
      )!,
      sectionTitlePaddingMedium: EdgeInsets.lerp(
        sectionTitlePaddingMedium,
        other.sectionTitlePaddingMedium,
        t,
      )!,
      metadataRowStackGap:
          t < 0.5 ? metadataRowStackGap : other.metadataRowStackGap,
      metadataRowValueTopGap:
          t < 0.5 ? metadataRowValueTopGap : other.metadataRowValueTopGap,
    );
  }
}

/// Extension on ThemeData to access AppSpacing
extension AppSpacingThemeEx on ThemeData {
  AppSpacing get spacing => extension<AppSpacing>() ?? const AppSpacing();
}

/// Convenience extension on BuildContext to access AppSpacing
extension AppSpacingEx on BuildContext {
  AppSpacing get spacing => Theme.of(this).spacing;
}

/// Convenience SizedBox gaps from spacing tokens.
///
/// Each getter returns a square SizedBox; use in [Column] (height applies) or
/// [Row] (width applies). One widget works for both axes.
extension SpacingGaps on AppSpacing {
  /// Gap [tightSpacing] (default 4px). Use in Column or Row.
  SizedBox get tightGap => SizedBox(height: tightSpacing, width: tightSpacing);

  /// Gap [compactSpacing] (default 6px). Use in Column or Row.
  SizedBox get compactGap =>
      SizedBox(height: compactSpacing, width: compactSpacing);

  /// Gap [itemSpacing] (default 8px). Use in Column or Row.
  SizedBox get itemGap => SizedBox(height: itemSpacing, width: itemSpacing);

  /// Gap [sectionSpacing] (default 16px). Use in Column or Row.
  SizedBox get sectionGap =>
      SizedBox(height: sectionSpacing, width: sectionSpacing);

  /// Gap [chipGap] (default 4px). Use in Column or Row.
  SizedBox get chipGapSized => SizedBox(height: chipGap, width: chipGap);

  /// Gap from [contentPadding] (default 12px). Use in Column or Row.
  SizedBox get contentGap => SizedBox(
        height: contentPadding.top,
        width: contentPadding.left,
      );

  /// Gap from [spaciousPadding] (default 24px). Use in Column or Row.
  SizedBox get spaciousGap => SizedBox(
        height: spaciousPadding.top,
        width: spaciousPadding.left,
      );
}
