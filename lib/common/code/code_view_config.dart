import 'package:diohub/app/settings/diff_settings.dart';
import 'package:diohub/common/diff/diff_config.dart';

/// Runtime config for code file view: extends [DiffViewConfig] with blame,
/// annotations, and minimap toggles.
class CodeViewConfig extends DiffViewConfig {
  const CodeViewConfig({
    super.wrap,
    super.showLineNumbers,
    super.highlightIntensity,
    super.codeFontScale,
    this.showBlame = false,
    this.showAnnotations = false,
    this.showMinimap = false,
  });

  factory CodeViewConfig.fromSettings(final DiffSettings settings) =>
      CodeViewConfig(
        wrap: settings.wrapLines,
        showLineNumbers: settings.showLineNumbers,
        highlightIntensity: settings.highlightIntensity,
        codeFontScale: settings.codeFontScale,
      );

  final bool showBlame;
  final bool showAnnotations;
  final bool showMinimap;

  @override
  CodeViewConfig copyWith({
    final bool? wrap,
    final bool? showLineNumbers,
    final DiffHighlightIntensity? highlightIntensity,
    final double? codeFontScale,
    final bool? showBlame,
    final bool? showAnnotations,
    final bool? showMinimap,
  }) =>
      CodeViewConfig(
        wrap: wrap ?? this.wrap,
        showLineNumbers: showLineNumbers ?? this.showLineNumbers,
        highlightIntensity: highlightIntensity ?? this.highlightIntensity,
        codeFontScale: codeFontScale ?? this.codeFontScale,
        showBlame: showBlame ?? this.showBlame,
        showAnnotations: showAnnotations ?? this.showAnnotations,
        showMinimap: showMinimap ?? this.showMinimap,
      );
}
