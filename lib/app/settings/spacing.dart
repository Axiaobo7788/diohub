import 'package:diohub/app/settings/serialization_helpers.dart';
import 'package:diohub/app/settings/settings_descriptor.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// Persisted spacing settings. Convert to [AppSpacing] for theme.
///
/// Mirrors [AppSpacing] defaults; when theme is built, [toAppSpacing] is used.
class SpacingSettings {
  const SpacingSettings({
    this.listInset = const EdgeInsets.symmetric(horizontal: 8),
    this.itemSpacing = 8.0,
    this.listPaddingBottom = 16.0,
    this.screenPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.pagePadding = const EdgeInsets.all(16),
    this.sectionSpacing = 16.0,
    this.cardContentPadding =
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.contentPadding = const EdgeInsets.all(12),
    this.spaciousPadding = const EdgeInsets.all(24),
    this.emptyStatePadding = const EdgeInsets.all(32),
    this.chipPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.badgePadding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    this.inputPadding =
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.tightSpacing = 4.0,
    this.sheetPadding = const EdgeInsets.fromLTRB(24, 12, 24, 8),
    this.sectionTitlePaddingLarge = const EdgeInsets.fromLTRB(16, 20, 16, 12),
    this.sectionTitlePaddingMedium = const EdgeInsets.fromLTRB(16, 16, 16, 8),
  });

  /// Preset with 0.75× default spacing (tighter layout).
  factory SpacingSettings.compact() {
    const SpacingSettings d = SpacingSettings();
    const double scale = 0.75;
    return SpacingSettings(
      listInset: _scaleEdgeInsets(d.listInset, scale),
      itemSpacing: d.itemSpacing * scale,
      listPaddingBottom: d.listPaddingBottom * scale,
      screenPadding: _scaleEdgeInsets(d.screenPadding, scale),
      pagePadding: _scaleEdgeInsets(d.pagePadding, scale),
      sectionSpacing: d.sectionSpacing * scale,
      cardContentPadding: _scaleEdgeInsets(d.cardContentPadding, scale),
      contentPadding: _scaleEdgeInsets(d.contentPadding, scale),
      spaciousPadding: _scaleEdgeInsets(d.spaciousPadding, scale),
      emptyStatePadding: _scaleEdgeInsets(d.emptyStatePadding, scale),
      chipPadding: _scaleEdgeInsets(d.chipPadding, scale),
      badgePadding: _scaleEdgeInsets(d.badgePadding, scale),
      inputPadding: _scaleEdgeInsets(d.inputPadding, scale),
      tightSpacing: d.tightSpacing * scale,
      sheetPadding: _scaleEdgeInsets(d.sheetPadding, scale),
      sectionTitlePaddingLarge:
          _scaleEdgeInsets(d.sectionTitlePaddingLarge, scale),
      sectionTitlePaddingMedium:
          _scaleEdgeInsets(d.sectionTitlePaddingMedium, scale),
    );
  }

  /// Preset with 1.35× default spacing (more room).
  factory SpacingSettings.spacious() {
    const SpacingSettings d = SpacingSettings();
    const double scale = 1.35;
    return SpacingSettings(
      listInset: _scaleEdgeInsets(d.listInset, scale),
      itemSpacing: d.itemSpacing * scale,
      listPaddingBottom: d.listPaddingBottom * scale,
      screenPadding: _scaleEdgeInsets(d.screenPadding, scale),
      pagePadding: _scaleEdgeInsets(d.pagePadding, scale),
      sectionSpacing: d.sectionSpacing * scale,
      cardContentPadding: _scaleEdgeInsets(d.cardContentPadding, scale),
      contentPadding: _scaleEdgeInsets(d.contentPadding, scale),
      spaciousPadding: _scaleEdgeInsets(d.spaciousPadding, scale),
      emptyStatePadding: _scaleEdgeInsets(d.emptyStatePadding, scale),
      chipPadding: _scaleEdgeInsets(d.chipPadding, scale),
      badgePadding: _scaleEdgeInsets(d.badgePadding, scale),
      inputPadding: _scaleEdgeInsets(d.inputPadding, scale),
      tightSpacing: d.tightSpacing * scale,
      sheetPadding: _scaleEdgeInsets(d.sheetPadding, scale),
      sectionTitlePaddingLarge:
          _scaleEdgeInsets(d.sectionTitlePaddingLarge, scale),
      sectionTitlePaddingMedium:
          _scaleEdgeInsets(d.sectionTitlePaddingMedium, scale),
    );
  }

  static EdgeInsets _scaleEdgeInsets(final EdgeInsets e, final double scale) =>
      EdgeInsets.fromLTRB(
        e.left * scale,
        e.top * scale,
        e.right * scale,
        e.bottom * scale,
      );

  factory SpacingSettings.fromJson(final Map<String, dynamic> json) {
    const SpacingSettings d = SpacingSettings();
    return SpacingSettings(
      listInset: edgeInsetsFromJsonOr(json, 'listInset', d.listInset),
      itemSpacing: doubleFromJsonOr(json, 'itemSpacing', d.itemSpacing),
      listPaddingBottom:
          doubleFromJsonOr(json, 'listPaddingBottom', d.listPaddingBottom),
      screenPadding:
          edgeInsetsFromJsonOr(json, 'screenPadding', d.screenPadding),
      pagePadding: edgeInsetsFromJsonOr(json, 'pagePadding', d.pagePadding),
      sectionSpacing:
          doubleFromJsonOr(json, 'sectionSpacing', d.sectionSpacing),
      cardContentPadding: edgeInsetsFromJsonOr(
        json,
        'cardContentPadding',
        d.cardContentPadding,
      ),
      contentPadding:
          edgeInsetsFromJsonOr(json, 'contentPadding', d.contentPadding),
      spaciousPadding:
          edgeInsetsFromJsonOr(json, 'spaciousPadding', d.spaciousPadding),
      emptyStatePadding:
          edgeInsetsFromJsonOr(json, 'emptyStatePadding', d.emptyStatePadding),
      chipPadding: edgeInsetsFromJsonOr(json, 'chipPadding', d.chipPadding),
      badgePadding: edgeInsetsFromJsonOr(json, 'badgePadding', d.badgePadding),
      inputPadding: edgeInsetsFromJsonOr(json, 'inputPadding', d.inputPadding),
      tightSpacing: doubleFromJsonOr(json, 'tightSpacing', d.tightSpacing),
      sheetPadding: edgeInsetsFromJsonOr(json, 'sheetPadding', d.sheetPadding),
      sectionTitlePaddingLarge: edgeInsetsFromJsonOr(
        json,
        'sectionTitlePaddingLarge',
        d.sectionTitlePaddingLarge,
      ),
      sectionTitlePaddingMedium: edgeInsetsFromJsonOr(
        json,
        'sectionTitlePaddingMedium',
        d.sectionTitlePaddingMedium,
      ),
    );
  }

  final EdgeInsets listInset;
  final double itemSpacing;
  final double listPaddingBottom;
  final EdgeInsets screenPadding;
  final EdgeInsets pagePadding;
  final double sectionSpacing;
  final EdgeInsets cardContentPadding;
  final EdgeInsets contentPadding;
  final EdgeInsets spaciousPadding;
  final EdgeInsets emptyStatePadding;
  final EdgeInsets chipPadding;
  final EdgeInsets badgePadding;
  final EdgeInsets inputPadding;
  final double tightSpacing;
  final EdgeInsets sheetPadding;
  final EdgeInsets sectionTitlePaddingLarge;
  final EdgeInsets sectionTitlePaddingMedium;

  AppSpacing toAppSpacing() => AppSpacing(
        listInset: listInset,
        itemSpacing: itemSpacing,
        listPaddingBottom: listPaddingBottom,
        screenPadding: screenPadding,
        pagePadding: pagePadding,
        sectionSpacing: sectionSpacing,
        cardContentPadding: cardContentPadding,
        contentPadding: contentPadding,
        spaciousPadding: spaciousPadding,
        emptyStatePadding: emptyStatePadding,
        chipPadding: chipPadding,
        badgePadding: badgePadding,
        inputPadding: inputPadding,
        tightSpacing: tightSpacing,
        sheetPadding: sheetPadding,
        sectionTitlePaddingLarge: sectionTitlePaddingLarge,
        sectionTitlePaddingMedium: sectionTitlePaddingMedium,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'listInset': edgeInsetsToJson(listInset),
        'itemSpacing': itemSpacing,
        'listPaddingBottom': listPaddingBottom,
        'screenPadding': edgeInsetsToJson(screenPadding),
        'pagePadding': edgeInsetsToJson(pagePadding),
        'sectionSpacing': sectionSpacing,
        'cardContentPadding': edgeInsetsToJson(cardContentPadding),
        'contentPadding': edgeInsetsToJson(contentPadding),
        'spaciousPadding': edgeInsetsToJson(spaciousPadding),
        'emptyStatePadding': edgeInsetsToJson(emptyStatePadding),
        'chipPadding': edgeInsetsToJson(chipPadding),
        'badgePadding': edgeInsetsToJson(badgePadding),
        'inputPadding': edgeInsetsToJson(inputPadding),
        'tightSpacing': tightSpacing,
        'sheetPadding': edgeInsetsToJson(sheetPadding),
        'sectionTitlePaddingLarge': edgeInsetsToJson(sectionTitlePaddingLarge),
        'sectionTitlePaddingMedium':
            edgeInsetsToJson(sectionTitlePaddingMedium),
      };

  SpacingSettings copyWith({
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
    final EdgeInsets? inputPadding,
    final double? tightSpacing,
    final EdgeInsets? sheetPadding,
    final EdgeInsets? sectionTitlePaddingLarge,
    final EdgeInsets? sectionTitlePaddingMedium,
  }) =>
      SpacingSettings(
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
        inputPadding: inputPadding ?? this.inputPadding,
        tightSpacing: tightSpacing ?? this.tightSpacing,
        sheetPadding: sheetPadding ?? this.sheetPadding,
        sectionTitlePaddingLarge:
            sectionTitlePaddingLarge ?? this.sectionTitlePaddingLarge,
        sectionTitlePaddingMedium:
            sectionTitlePaddingMedium ?? this.sectionTitlePaddingMedium,
      );
}

Map<String, dynamic> _spacingToJson(final SpacingSettings v) => v.toJson();

const SettingsDescriptor<SpacingSettings> spacingDescriptor =
    SettingsDescriptor<SpacingSettings>(
  key: 'app_spacing',
  defaultValue: SpacingSettings(),
  fromJson: SpacingSettings.fromJson,
  toJson: _spacingToJson,
);
