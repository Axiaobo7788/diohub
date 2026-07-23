import 'package:diohub/app/settings/diff_settings.dart';
import 'package:diohub/common/code/code_theme.dart';
import 'package:diohub/providers/settings/diff_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_highlight/languages/all.dart' as re_highlight_languages;
import 'package:re_highlight/re_highlight.dart';

/// Lightweight, intrinsically-sized syntax-highlighted code.
///
/// A full code editor requires finite width and height. Markdown and diff
/// rows deliberately size themselves from their contents, so embedding an
/// editor here leaves its flex/render viewport children unconstrained. Keep
/// the editor for dedicated file/edit screens and use a plain text renderer
/// for static code.
class CodeBlockView extends ConsumerWidget {
  const CodeBlockView(
    this.data, {
    this.language,
    this.showLineNumbers,
    super.key,
  });

  final String data;
  final String? language;

  /// Static markdown and diff rows do not show line numbers unless requested.
  final bool? showLineNumbers;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final DiffSettings settings = ref.watch(diffSettingsProvider);
    final Brightness brightness = Theme.of(context).colorScheme.brightness;
    final TextStyle baseStyle = TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
      fontFamily: 'monospace',
      fontSize: 12 * settings.codeFontScale,
    );
    final TextSpan codeSpan = _highlightedSpan(
      data,
      language ?? 'plaintext',
      baseStyle,
      codeBlockThemeMap(settings.codeBlockTheme, brightness),
    );
    final Widget code = Text.rich(codeSpan);

    if (showLineNumbers != true) {
      return code;
    }

    final int lineCount = '\n'.allMatches(data).length + 1;
    final double gutterWidth = (lineCount.toString().length * 8 + 16)
        .toDouble();
    final Widget gutter = SizedBox(
      width: gutterWidth,
      child: Text(
        List<String>.generate(
          lineCount,
          (final int index) => '${index + 1}',
        ).join('\n'),
        textAlign: TextAlign.right,
        style: baseStyle.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        final List<Widget> children = <Widget>[
          gutter,
          const SizedBox(width: 12),
          if (constraints.hasBoundedWidth) Expanded(child: code) else code,
        ];
        return Row(
          mainAxisSize: constraints.hasBoundedWidth
              ? MainAxisSize.max
              : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        );
      },
    );
  }
}

TextSpan _highlightedSpan(
  final String code,
  final String requestedLanguage,
  final TextStyle baseStyle,
  final Map<String, TextStyle> theme,
) {
  final String language =
      re_highlight_languages.builtinAllLanguages.containsKey(requestedLanguage)
      ? requestedLanguage
      : 'plaintext';
  final Mode? mode = re_highlight_languages.builtinAllLanguages[language];
  if (mode == null || code.length > 200000) {
    return TextSpan(text: code, style: baseStyle);
  }

  try {
    final Highlight highlighter = Highlight()..registerLanguage(language, mode);
    final HighlightResult result = highlighter.highlight(
      code: code,
      language: language,
    );
    final TextSpanRenderer renderer = TextSpanRenderer(baseStyle, theme);
    result.render(renderer);
    return renderer.span ?? TextSpan(text: code, style: baseStyle);
  } on Object {
    return TextSpan(text: code, style: baseStyle);
  }
}
