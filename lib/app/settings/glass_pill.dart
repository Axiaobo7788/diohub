import 'package:diohub/app/settings/settings_descriptor.dart';
import 'package:diohub/common/misc/glass_pill_constants.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';

/// Density preset for glass pill padding/margins.
enum PillDensity {
  compact, // 0.7×
  default_, // 1.0×
  spacious, // 1.4×
}

/// Radius scale — applied to SurfaceStyle.radii map values.
enum RadiusScale {
  tight, // 0.6×
  default_, // 1.0×
  roomy, // 1.5×
}

/// User-facing settings for glass pill theme (density and radius scale).
/// Converts to [GlassPillTheme] via [toGlassPillTheme]; radius scale is
/// applied to [SurfaceStyle.radii] separately.
class GlassPillSettings {
  const GlassPillSettings({
    this.density = PillDensity.default_,
    this.radiusScale = RadiusScale.default_,
  });

  final PillDensity density;
  final RadiusScale radiusScale;

  double get _densityScale => switch (density) {
        PillDensity.compact => 0.7,
        PillDensity.default_ => 1.0,
        PillDensity.spacious => 1.4,
      };

  double get _radiusMultiplier => switch (radiusScale) {
        RadiusScale.tight => 0.6,
        RadiusScale.default_ => 1.0,
        RadiusScale.roomy => 1.5,
      };

  /// Build a [GlassPillTheme] from these settings.
  /// All EdgeInsets fields are scaled by density; radii are unchanged
  /// (they resolve through SurfaceStyle.radii which is scaled separately).
  GlassPillTheme toGlassPillTheme() {
    const GlassPillTheme d = GlassPillTheme();
    final double s = _densityScale;
    return GlassPillTheme(
      floatPadding: _scale(d.floatPadding, s),
      sectionFloatInset: _scale(d.sectionFloatInset, s),
      innerPadding: _scale(d.innerPadding, s),
      innerPaddingExpanded: _scale(d.innerPaddingExpanded, s),
      metadataFloatInset: _scale(d.metadataFloatInset, s),
      toolbarCollapsedPadding: _scale(d.toolbarCollapsedPadding, s),
      toolbarExpandedPadding: _scale(d.toolbarExpandedPadding, s),
      appBarRadius: d.appBarRadius,
      appBarAttachedCollapsedRadius: d.appBarAttachedCollapsedRadius,
      tabBarRadius: d.tabBarRadius,
      sectionRadius: d.sectionRadius,
      expandedRadius: d.expandedRadius,
      wrapperRadius: d.wrapperRadius,
      smallRadius: d.smallRadius,
      metadataSectionRadius: d.metadataSectionRadius,
      nestedMetadataRadius: d.nestedMetadataRadius,
    );
  }

  /// Scale SurfaceStyle radii map by radiusScale multiplier.
  /// Called separately since SurfaceStyle is a different ThemeExtension.
  Map<RadiusSize, double> scaleRadii(final Map<RadiusSize, double> base) {
    if (_radiusMultiplier == 1.0) return base;
    return base.map((final RadiusSize k, final double v) =>
        MapEntry<RadiusSize, double>(k, v * _radiusMultiplier));
  }

  static EdgeInsets _scale(final EdgeInsets e, final double s) =>
      EdgeInsets.fromLTRB(
        e.left * s,
        e.top * s,
        e.right * s,
        e.bottom * s,
      );

  factory GlassPillSettings.fromJson(final Map<String, dynamic> json) {
    return GlassPillSettings(
      density: PillDensity.values.firstWhere(
        (final PillDensity e) => e.name == json['density'],
        orElse: () => PillDensity.default_,
      ),
      radiusScale: RadiusScale.values.firstWhere(
        (final RadiusScale e) => e.name == json['radiusScale'],
        orElse: () => RadiusScale.default_,
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'density': density.name,
        'radiusScale': radiusScale.name,
      };

  GlassPillSettings copyWith({
    final PillDensity? density,
    final RadiusScale? radiusScale,
  }) =>
      GlassPillSettings(
        density: density ?? this.density,
        radiusScale: radiusScale ?? this.radiusScale,
      );
}

Map<String, dynamic> _glassPillToJson(final GlassPillSettings v) => v.toJson();

const SettingsDescriptor<GlassPillSettings> glassPillDescriptor =
    SettingsDescriptor<GlassPillSettings>(
  key: 'glass_pill_settings',
  defaultValue: GlassPillSettings(),
  fromJson: GlassPillSettings.fromJson,
  toJson: _glassPillToJson,
);
