import 'package:diohub/app/settings/diff_settings.dart';
import 'package:diohub/common/diff/diff.dart' show DiffView;
import 'package:diohub/common/diff/diff_view.dart' show DiffView;

/// Runtime config for [DiffView]: wrap, line numbers, highlight, font scale.
///
/// Built from [DiffSettings] via [fromSettings]; callers can override per screen.
class DiffViewConfig {
  const DiffViewConfig({
    this.wrap = true,
    this.showLineNumbers = true,
    this.highlightIntensity = DiffHighlightIntensity.default_,
    this.codeFontScale = 1.0,
  });

  factory DiffViewConfig.fromSettings(final DiffSettings settings) =>
      DiffViewConfig(
        wrap: settings.wrapLines,
        showLineNumbers: settings.showLineNumbers,
        highlightIntensity: settings.highlightIntensity,
        codeFontScale: settings.codeFontScale,
      );

  final bool wrap;
  final bool showLineNumbers;
  final DiffHighlightIntensity highlightIntensity;
  final double codeFontScale;

  DiffViewConfig copyWith({
    final bool? wrap,
    final bool? showLineNumbers,
    final DiffHighlightIntensity? highlightIntensity,
    final double? codeFontScale,
  }) =>
      DiffViewConfig(
        wrap: wrap ?? this.wrap,
        showLineNumbers: showLineNumbers ?? this.showLineNumbers,
        highlightIntensity: highlightIntensity ?? this.highlightIntensity,
        codeFontScale: codeFontScale ?? this.codeFontScale,
      );
}
