import 'package:diohub/app/settings/settings_descriptor.dart';
import 'package:diohub/common/misc/liquid_glass_wrapper.dart'
    show GlassSettings;

/// Surface rendering mode for glass-style UI (toolbar, pills, popups).
enum SurfaceRendering {
  glass,
  blur,
  solid;

  String get name => switch (this) {
    SurfaceRendering.glass => 'glass',
    SurfaceRendering.blur => 'blur',
    SurfaceRendering.solid => 'solid',
  };

  static SurfaceRendering fromName(final String name) =>
      SurfaceRendering.values.firstWhere(
        (final SurfaceRendering e) => e.name == name,
        orElse: () => SurfaceRendering.glass,
      );
}

/// App bar layout: floating pill with margin or attached to screen edges.
enum AppBarStyle {
  floating,
  attached;

  String get name => switch (this) {
    AppBarStyle.floating => 'floating',
    AppBarStyle.attached => 'attached',
  };

  static AppBarStyle fromName(final String name) =>
      AppBarStyle.values.firstWhere(
        (final AppBarStyle e) => e.name == name,
        orElse: () => AppBarStyle.floating,
      );
}

/// Single preset that drives all animation-related behavior (duration and toggles).
/// Durations are bounded so nothing feels too slow.
enum AnimationPreset {
  none,
  reduced,
  normal,
  enhanced;

  String get name => switch (this) {
    AnimationPreset.none => 'none',
    AnimationPreset.reduced => 'reduced',
    AnimationPreset.normal => 'normal',
    AnimationPreset.enhanced => 'enhanced',
  };

  static AnimationPreset fromName(final String name) =>
      AnimationPreset.values.firstWhere(
        (final AnimationPreset e) => e.name == name,
        orElse: () => AnimationPreset.normal,
      );

  /// Duration in ms for this preset (bounded; enhanced capped at 380).
  int get durationMs => switch (this) {
    AnimationPreset.none => 0,
    AnimationPreset.reduced => 180,
    AnimationPreset.normal => 300,
    AnimationPreset.enhanced => 380,
  };

  /// Whether spatial/decorative motion must be removed at the application root.
  ///
  /// Both `none` and `reduced` opt out of obvious motion. Components may still
  /// provide immediate color, focus, and selection feedback.
  bool get disableAnimations =>
      this == AnimationPreset.none || this == AnimationPreset.reduced;
  bool get reduceListAnimations =>
      this == AnimationPreset.none || this == AnimationPreset.reduced;
  bool get disableShimmerAnimation =>
      this == AnimationPreset.none || this == AnimationPreset.reduced;
}

/// Appearance and performance-related settings.
///
/// Animation behavior is driven by [animationPreset]; [disableAnimations],
/// [animationDurationMs], [reduceListAnimations], and [disableShimmerAnimation]
/// are derived from it for backward compatibility with consumers.
/// Defaults for glass settings (match [GlassSettings] in liquid_glass_wrapper).
const double kDefaultGlassBlur = 16;
const double kDefaultGlassBorderWidth = 0.5;
const double kDefaultGlassVisibility = 1;
const double kDefaultGlassThickness = 6.5;
const double kDefaultGlassLightIntensity = 0.4;

class AppearanceSettings {
  const AppearanceSettings({
    this.surfaceRendering = SurfaceRendering.glass,
    this.appBarStyle = AppBarStyle.floating,
    this.appBarSurfaceRendering = SurfaceRendering.glass,
    this.appBarGlassBlur,
    this.appBarGlassBorderWidth,
    this.appBarGlassVisibility,
    this.appBarGlassThickness,
    this.appBarGlassLightIntensity,
    this.animationPreset = AnimationPreset.normal,
    this.toolbarMinimizeOnScroll = true,
    this.fuzzyFiltering = false,
    this.glassBlur = kDefaultGlassBlur,
    this.glassBorderWidth = kDefaultGlassBorderWidth,
    this.glassVisibility = kDefaultGlassVisibility,
    this.glassThickness = kDefaultGlassThickness,
    this.glassLightIntensity = kDefaultGlassLightIntensity,
  });

  factory AppearanceSettings.fromJson(final Map<String, dynamic> json) {
    final style = json['surfaceStyle'];
    final SurfaceRendering surfaceRendering = style is String
        ? SurfaceRendering.fromName(style)
        : SurfaceRendering.glass;
    final AppBarStyle appBarStyle = json['appBarStyle'] is String
        ? AppBarStyle.fromName(json['appBarStyle'] as String)
        : AppBarStyle.floating;
    final SurfaceRendering appBarSurfaceRendering =
        json['appBarSurfaceRendering'] is String
        ? SurfaceRendering.fromName(json['appBarSurfaceRendering'] as String)
        : SurfaceRendering.glass;
    final AnimationPreset preset = json['animationPreset'] is String
        ? AnimationPreset.fromName(json['animationPreset'] as String)
        : AnimationPreset.normal;
    final double glassBlur =
        (json['glassBlur'] as num?)?.toDouble() ?? kDefaultGlassBlur;
    final double glassBorderWidth =
        (json['glassBorderWidth'] as num?)?.toDouble() ??
        kDefaultGlassBorderWidth;
    final double glassVisibility =
        (json['glassVisibility'] as num?)?.toDouble() ??
        kDefaultGlassVisibility;
    final double glassThickness =
        (json['glassThickness'] as num?)?.toDouble() ?? kDefaultGlassThickness;
    final double glassLightIntensity =
        (json['glassLightIntensity'] as num?)?.toDouble() ??
        kDefaultGlassLightIntensity;
    final bool fuzzyFiltering = json['fuzzyFiltering'] as bool? ?? false;
    final double? appBarGlassBlur = (json['appBarGlassBlur'] as num?)
        ?.toDouble();
    final double? appBarGlassBorderWidth =
        (json['appBarGlassBorderWidth'] as num?)?.toDouble();
    final double? appBarGlassVisibility =
        (json['appBarGlassVisibility'] as num?)?.toDouble();
    final double? appBarGlassThickness = (json['appBarGlassThickness'] as num?)
        ?.toDouble();
    final double? appBarGlassLightIntensity =
        (json['appBarGlassLightIntensity'] as num?)?.toDouble();

    return AppearanceSettings(
      surfaceRendering: surfaceRendering,
      appBarStyle: appBarStyle,
      appBarSurfaceRendering: appBarSurfaceRendering,
      appBarGlassBlur: appBarGlassBlur,
      appBarGlassBorderWidth: appBarGlassBorderWidth,
      appBarGlassVisibility: appBarGlassVisibility,
      appBarGlassThickness: appBarGlassThickness,
      appBarGlassLightIntensity: appBarGlassLightIntensity,
      animationPreset: preset,
      toolbarMinimizeOnScroll: json['toolbarMinimizeOnScroll'] as bool? ?? true,
      fuzzyFiltering: fuzzyFiltering,
      glassBlur: glassBlur,
      glassBorderWidth: glassBorderWidth,
      glassVisibility: glassVisibility,
      glassThickness: glassThickness,
      glassLightIntensity: glassLightIntensity,
    );
  }

  final SurfaceRendering surfaceRendering;
  final AppBarStyle appBarStyle;

  /// Surface style for the app bar (glass, blur, or solid). Independent of [surfaceRendering].
  final SurfaceRendering appBarSurfaceRendering;

  final double? appBarGlassBlur;
  final double? appBarGlassBorderWidth;
  final double? appBarGlassVisibility;
  final double? appBarGlassThickness;
  final double? appBarGlassLightIntensity;

  final AnimationPreset animationPreset;

  /// When true, the floating toolbar minimizes when the user scrolls down.
  final bool toolbarMinimizeOnScroll;

  /// When true, client-side text filtering uses fuzzy matching instead of exact substring.
  final bool fuzzyFiltering;

  /// Blur strength for glass/blur surfaces (used when not solid).
  final double glassBlur;

  /// Border width for all surface styles.
  final double glassBorderWidth;

  /// Opacity/visibility of glass/blur effect (0.5–1.0).
  final double glassVisibility;

  /// Glass-only: thickness of the liquid glass layer.
  final double glassThickness;

  /// Glass-only: light intensity of the liquid glass layer.
  final double glassLightIntensity;

  /// Derived from [animationPreset].
  bool get disableAnimations => animationPreset.disableAnimations;

  /// Derived from [animationPreset] (bounded duration in ms).
  int get animationDurationMs => animationPreset.durationMs;

  /// Derived from [animationPreset].
  bool get reduceListAnimations => animationPreset.reduceListAnimations;

  /// Derived from [animationPreset].
  bool get disableShimmerAnimation => animationPreset.disableShimmerAnimation;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'surfaceStyle': surfaceRendering.name,
    'appBarStyle': appBarStyle.name,
    'appBarSurfaceRendering': appBarSurfaceRendering.name,
    if (appBarGlassBlur != null) 'appBarGlassBlur': appBarGlassBlur,
    if (appBarGlassBorderWidth != null)
      'appBarGlassBorderWidth': appBarGlassBorderWidth,
    if (appBarGlassVisibility != null)
      'appBarGlassVisibility': appBarGlassVisibility,
    if (appBarGlassThickness != null)
      'appBarGlassThickness': appBarGlassThickness,
    if (appBarGlassLightIntensity != null)
      'appBarGlassLightIntensity': appBarGlassLightIntensity,
    'animationPreset': animationPreset.name,
    'toolbarMinimizeOnScroll': toolbarMinimizeOnScroll,
    'fuzzyFiltering': fuzzyFiltering,
    'glassBlur': glassBlur,
    'glassBorderWidth': glassBorderWidth,
    'glassVisibility': glassVisibility,
    'glassThickness': glassThickness,
    'glassLightIntensity': glassLightIntensity,
  };

  AppearanceSettings copyWith({
    final SurfaceRendering? surfaceRendering,
    final AppBarStyle? appBarStyle,
    final SurfaceRendering? appBarSurfaceRendering,
    final double? appBarGlassBlur,
    final double? appBarGlassBorderWidth,
    final double? appBarGlassVisibility,
    final double? appBarGlassThickness,
    final double? appBarGlassLightIntensity,
    final AnimationPreset? animationPreset,
    final bool? toolbarMinimizeOnScroll,
    final bool? fuzzyFiltering,
    final double? glassBlur,
    final double? glassBorderWidth,
    final double? glassVisibility,
    final double? glassThickness,
    final double? glassLightIntensity,
  }) => AppearanceSettings(
    surfaceRendering: surfaceRendering ?? this.surfaceRendering,
    appBarStyle: appBarStyle ?? this.appBarStyle,
    appBarSurfaceRendering:
        appBarSurfaceRendering ?? this.appBarSurfaceRendering,
    appBarGlassBlur: appBarGlassBlur ?? this.appBarGlassBlur,
    appBarGlassBorderWidth:
        appBarGlassBorderWidth ?? this.appBarGlassBorderWidth,
    appBarGlassVisibility: appBarGlassVisibility ?? this.appBarGlassVisibility,
    appBarGlassThickness: appBarGlassThickness ?? this.appBarGlassThickness,
    appBarGlassLightIntensity:
        appBarGlassLightIntensity ?? this.appBarGlassLightIntensity,
    animationPreset: animationPreset ?? this.animationPreset,
    toolbarMinimizeOnScroll:
        toolbarMinimizeOnScroll ?? this.toolbarMinimizeOnScroll,
    fuzzyFiltering: fuzzyFiltering ?? this.fuzzyFiltering,
    glassBlur: glassBlur ?? this.glassBlur,
    glassBorderWidth: glassBorderWidth ?? this.glassBorderWidth,
    glassVisibility: glassVisibility ?? this.glassVisibility,
    glassThickness: glassThickness ?? this.glassThickness,
    glassLightIntensity: glassLightIntensity ?? this.glassLightIntensity,
  );
}

Map<String, dynamic> _appearanceToJson(final AppearanceSettings v) =>
    v.toJson();

const SettingsDescriptor<AppearanceSettings> appearanceDescriptor =
    SettingsDescriptor<AppearanceSettings>(
      key: 'app_appearance',
      defaultValue: AppearanceSettings(),
      fromJson: AppearanceSettings.fromJson,
      toJson: _appearanceToJson,
    );
