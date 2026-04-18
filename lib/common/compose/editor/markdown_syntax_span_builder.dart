import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';

/// Builds styled [TextSpan]s for markdown syntax in compose body.
/// Inline patterns (bold, italic, code, links, mentions) are styled; raw text is preserved in the field.
/// Visual-only — [TextEditingController].text remains plain markdown.
class MarkdownSyntaxSpanBuilder extends SpecialTextSpanBuilder {
  MarkdownSyntaxSpanBuilder({required this.context});
  final BuildContext context;

  /// Combined pattern for inline syntax (order matters: bold before italic, etc.).
  static final RegExp _combinedInline = RegExp(
    r'\*\*(.+?)\*\*|(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)|`([^`]+)`|\[([^\]]+)\]\(([^\)]+)\)|@(\w+)|~~(.+?)~~',
    dotAll: true,
  );

  @override
  TextSpan build(
    String data, {
    TextStyle? textStyle,
    SpecialTextGestureTapCallback? onTap,
  }) {
    if (data.isEmpty) return TextSpan(text: '', style: textStyle);
    final TextStyle baseStyle = textStyle ?? DefaultTextStyle.of(context).style;
    final List<InlineSpan> children = <InlineSpan>[];
    int lastEnd = 0;
    for (final Match m in _combinedInline.allMatches(data)) {
      if (m.start > lastEnd) {
        children.add(TextSpan(text: data.substring(lastEnd, m.start), style: baseStyle));
      }
      final String matchText = m[0]!;
      if (m[1] != null) {
        // **bold**
        children.add(SpecialTextSpan(
          text: m[1]!,
          actualText: matchText,
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (m[2] != null) {
        // *italic*
        children.add(SpecialTextSpan(
          text: m[2]!,
          actualText: matchText,
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (m[3] != null) {
        // `code`
        final Color surface = Theme.of(context).colorScheme.surfaceContainerHighest;
        children.add(SpecialTextSpan(
          text: m[3]!,
          actualText: matchText,
          style: baseStyle.copyWith(
            fontFamily: 'monospace',
            backgroundColor: surface,
          ),
        ));
      } else if (m[4] != null && m[5] != null) {
        // [text](url)
        children.add(SpecialTextSpan(
          text: m[4]!,
          actualText: matchText,
          style: baseStyle.copyWith(
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
        ));
      } else if (m[6] != null) {
        // @mention
        children.add(SpecialTextSpan(
          text: '@${m[6]!}',
          actualText: matchText,
          style: baseStyle.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ));
      } else if (m[7] != null) {
        // ~~strikethrough~~
        children.add(SpecialTextSpan(
          text: m[7]!,
          actualText: matchText,
          style: baseStyle.copyWith(decoration: TextDecoration.lineThrough),
        ));
      }
      lastEnd = m.end;
    }
    if (lastEnd < data.length) {
      children.add(TextSpan(text: data.substring(lastEnd), style: baseStyle));
    }
    return TextSpan(style: baseStyle, children: children.isEmpty ? [TextSpan(text: data, style: baseStyle)] : children);
  }

  @override
  SpecialText? createSpecialText(
    String flag, {
    required int index,
    TextStyle? textStyle,
    SpecialTextGestureTapCallback? onTap,
  }) =>
      null;
}
