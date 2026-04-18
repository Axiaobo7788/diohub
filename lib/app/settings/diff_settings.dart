import 'package:diohub/app/settings/settings_descriptor.dart';

/// Add/remove line background opacity tier for diff view.
enum DiffHighlightIntensity {
  subtle,
  default_,
  high;

  String get name => switch (this) {
        DiffHighlightIntensity.subtle => 'subtle',
        DiffHighlightIntensity.default_ => 'default',
        DiffHighlightIntensity.high => 'high',
      };

  static DiffHighlightIntensity fromName(final String name) =>
      DiffHighlightIntensity.values.firstWhere(
        (final DiffHighlightIntensity e) => e.name == name,
        orElse: () => DiffHighlightIntensity.default_,
      );
}

/// Display mode for diff view: unified (one column) or split (old | new).
enum DiffDisplayMode {
  unified,
  split;

  String get name => switch (this) {
        DiffDisplayMode.unified => 'unified',
        DiffDisplayMode.split => 'split',
      };

  static DiffDisplayMode fromName(final String name) =>
      DiffDisplayMode.values.firstWhere(
        (final DiffDisplayMode e) => e.name == name,
        orElse: () => DiffDisplayMode.unified,
      );
}

/// Persisted settings for diff/code view (wrap, line numbers, highlight, font scale, code block theme).
class DiffSettings {
  const DiffSettings({
    this.wrapLines = true,
    this.showLineNumbers = true,
    this.highlightIntensity = DiffHighlightIntensity.default_,
    this.codeFontScale = 1.0,
    this.codeBlockTheme = 'auto',
    this.defaultDiffDisplayMode = DiffDisplayMode.unified,
    this.showBlameInline = false,
    this.contextLinesToLoad = 20,
  });

  factory DiffSettings.fromJson(final Map<String, dynamic> json) {
    final dynamic intensity = json['highlightIntensity'];
    final dynamic displayMode = json['defaultDiffDisplayMode'];
    return DiffSettings(
      wrapLines: json['wrapLines'] as bool? ?? true,
      showLineNumbers: json['showLineNumbers'] as bool? ?? true,
      highlightIntensity: intensity is String
          ? DiffHighlightIntensity.fromName(intensity)
          : DiffHighlightIntensity.default_,
      codeFontScale:
          (json['codeFontScale'] as num?)?.toDouble().clamp(0.5, 2.0) ?? 1.0,
      codeBlockTheme: json['codeBlockTheme'] as String? ?? 'auto',
      defaultDiffDisplayMode: displayMode is String
          ? DiffDisplayMode.fromName(displayMode)
          : DiffDisplayMode.unified,
      showBlameInline: json['showBlameInline'] as bool? ?? false,
      contextLinesToLoad:
          (json['contextLinesToLoad'] as num?)?.toInt().clamp(5, 100) ?? 20,
    );
  }

  final bool wrapLines;
  final bool showLineNumbers;
  final DiffHighlightIntensity highlightIntensity;
  final double codeFontScale;

  /// Code/syntax highlight theme id. 'auto' = match app light/dark.
  final String codeBlockTheme;

  /// Default diff layout: unified or split.
  final DiffDisplayMode defaultDiffDisplayMode;

  /// Show blame info in code view gutter when available.
  final bool showBlameInline;

  /// Number of context lines to load when expanding between hunks.
  final int contextLinesToLoad;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'wrapLines': wrapLines,
        'showLineNumbers': showLineNumbers,
        'highlightIntensity': highlightIntensity.name,
        'codeFontScale': codeFontScale,
        'codeBlockTheme': codeBlockTheme,
        'defaultDiffDisplayMode': defaultDiffDisplayMode.name,
        'showBlameInline': showBlameInline,
        'contextLinesToLoad': contextLinesToLoad,
      };

  DiffSettings copyWith({
    final bool? wrapLines,
    final bool? showLineNumbers,
    final DiffHighlightIntensity? highlightIntensity,
    final double? codeFontScale,
    final String? codeBlockTheme,
    final DiffDisplayMode? defaultDiffDisplayMode,
    final bool? showBlameInline,
    final int? contextLinesToLoad,
  }) =>
      DiffSettings(
        wrapLines: wrapLines ?? this.wrapLines,
        showLineNumbers: showLineNumbers ?? this.showLineNumbers,
        highlightIntensity: highlightIntensity ?? this.highlightIntensity,
        codeFontScale: codeFontScale ?? this.codeFontScale,
        codeBlockTheme: codeBlockTheme ?? this.codeBlockTheme,
        defaultDiffDisplayMode:
            defaultDiffDisplayMode ?? this.defaultDiffDisplayMode,
        showBlameInline: showBlameInline ?? this.showBlameInline,
        contextLinesToLoad: contextLinesToLoad ?? this.contextLinesToLoad,
      );
}

Map<String, dynamic> _diffSettingsToJson(final DiffSettings v) => v.toJson();

const SettingsDescriptor<DiffSettings> diffSettingsDescriptor =
    SettingsDescriptor<DiffSettings>(
  key: 'app_diff',
  defaultValue: DiffSettings(),
  fromJson: DiffSettings.fromJson,
  toJson: _diffSettingsToJson,
);
