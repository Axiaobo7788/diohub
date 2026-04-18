import 'package:diohub/app/settings/diff_settings.dart';
import 'package:diohub/common/code/code_theme.dart';
import 'package:diohub/providers/settings/diff_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One line in the mini diff preview.
class _DiffLine {
  const _DiffLine(this.text, {required this.kind});
  final String text;
  final _DiffKind kind;
}

enum _DiffKind { removed, added, context }

final List<_DiffLine> _sampleLines = <_DiffLine>[
  const _DiffLine("  import 'dart:math';", kind: _DiffKind.removed),
  const _DiffLine("  import 'dart:convert';", kind: _DiffKind.added),
  const _DiffLine('', kind: _DiffKind.context),
  const _DiffLine('  void main() {', kind: _DiffKind.added),
  const _DiffLine('    print(jsonDecode(\'{"hello": "world"}\'));',
      kind: _DiffKind.added),
];

/// Contextual preview for Diff & Code section: ~5-line mini diff with line numbers and wrap.
/// Respects wrapLines, showLineNumbers, highlightIntensity, codeFontScale, codeBlockTheme.
class DiffCodeContextPreview extends ConsumerWidget {
  const DiffCodeContextPreview({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final DiffSettings diff = ref.watch(diffSettingsProvider);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextStyle baseMono = theme.textTheme.bodySmall!.copyWith(
      fontFamily: 'monospace',
      fontSize:
          (theme.textTheme.bodySmall!.fontSize ?? 12) * diff.codeFontScale,
    );
    final Map<String, TextStyle> highlightTheme = codeBlockThemeMap(
      diff.codeBlockTheme,
      Theme.of(context).colorScheme.brightness,
    );
    final TextStyle? rootStyle = highlightTheme['root'];
    final TextStyle codeStyle = baseMono.copyWith(
      color: rootStyle?.color ?? colorScheme.onSurface,
    );

    final double intensityOpacity = switch (diff.highlightIntensity) {
      DiffHighlightIntensity.subtle => 0.25,
      DiffHighlightIntensity.default_ => 0.4,
      DiffHighlightIntensity.high => 0.6,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < _sampleLines.length; i++) ...[
          _DiffCodeRow(
            lineNumber: diff.showLineNumbers ? i + 1 : null,
            line: _sampleLines[i],
            codeStyle: codeStyle,
            lineNumberStyle: theme.textTheme.labelSmall!.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontFamily: 'monospace',
            ),
            colorScheme: colorScheme,
            intensityOpacity: intensityOpacity,
            wrapLines: diff.wrapLines,
          ),
        ],
      ],
    );
  }

}

class _DiffCodeRow extends StatelessWidget {
  const _DiffCodeRow({
    required this.lineNumber,
    required this.line,
    required this.codeStyle,
    required this.lineNumberStyle,
    required this.colorScheme,
    required this.intensityOpacity,
    required this.wrapLines,
  });

  final int? lineNumber;
  final _DiffLine line;
  final TextStyle codeStyle;
  final TextStyle lineNumberStyle;
  final ColorScheme colorScheme;
  final double intensityOpacity;
  final bool wrapLines;

  @override
  Widget build(final BuildContext context) {
    final Color stripColor = switch (line.kind) {
      _DiffKind.removed =>
        colorScheme.error.withValues(alpha: intensityOpacity),
      _DiffKind.added =>
        colorScheme.primary.withValues(alpha: intensityOpacity),
      _DiffKind.context => Colors.transparent,
    };

    final Widget codeContent = Text(
      line.text.isEmpty ? ' ' : line.text,
      style: codeStyle,
      maxLines: wrapLines ? 3 : 1,
      overflow: wrapLines ? TextOverflow.visible : TextOverflow.ellipsis,
      softWrap: wrapLines,
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (lineNumber != null)
            Container(
              width: 24,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '$lineNumber',
                style: lineNumberStyle,
              ),
            ),
          Container(
            width: 4,
            color: stripColor,
          ),
          Expanded(
            child: codeContent,
          ),
        ],
      ),
    );
  }
}
