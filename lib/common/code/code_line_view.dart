import 'package:diohub/app/settings/diff_settings.dart';
import 'package:diohub/common/code/blame_gutter_indicator.dart';
import 'package:diohub/common/diff/diff_config.dart';
import 'package:diohub/common/misc/code_block_view.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/tree_typedefs.dart';
import 'package:diohub/providers/settings/diff_settings_provider.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared layout constants for code/diff line layout (single line + gutter).
class CodeLineLayout {
  CodeLineLayout._();

  static const double lineNumberWidth = 35;
  static const double gapAfterOld = 10;
  static const double gapAfterNew = 5;
  static const double prefixWidth = 5;
  static const double gapBeforeCode = 20;
  static const double rowPadding = 8;

  /// Total width for two line-number columns + gaps when line numbers are shown.
  static double get twoColumnLineNumberWidth =>
      lineNumberWidth + gapAfterOld + lineNumberWidth + gapAfterNew;
}

/// Character range (start, end) for word-level diff highlighting within a line.
typedef WordDiffRange = (int start, int end);

double _opacityFor(final DiffHighlightIntensity intensity) => switch (intensity) {
      DiffHighlightIntensity.subtle => Opacities.tintSubtle,
      DiffHighlightIntensity.default_ => Opacities.tint,
      DiffHighlightIntensity.high => Opacities.tintMedium,
    };

/// Atomic widget: one line of code with optional syntax highlighting, prefix, and gutter.
///
/// Used as the building block for file view and diff view.
/// Gutter slots (e.g. add-comment button, blame OID, CI annotation) are passed as
/// [gutterWidgets]. For diff mode use [oldLineNumber]/[newLineNumber]; for single-file
/// use [lineNumber].
class CodeLineView extends ConsumerWidget {
  const CodeLineView({
    required this.content,
    super.key,
    this.lineNumber,
    this.oldLineNumber,
    this.newLineNumber,
    this.language,
    this.prefix,
    this.backgroundColor,
    this.gutterWidgets,
    this.blameRange,
    this.repoRef,
    this.onTap,
    this.onLongPress,
    this.isHighlighted = false,
    this.fontScale = 1.0,
    this.showLineNumber = true,
    this.wordDiffRanges,
    this.config,
  }) : assert(
          lineNumber != null || oldLineNumber != null || newLineNumber != null ||
              !showLineNumber,
          'At least one line number or showLineNumber false',
        );

  final String content;
  final int? lineNumber;
  final int? oldLineNumber;
  final int? newLineNumber;
  final String? language;
  final String? prefix;
  final Color? backgroundColor;
  final List<Widget>? gutterWidgets;
  /// When set, a [BlameGutterRow] is shown for this line (shared with AppCodeEditor blame UI).
  final BlameRange? blameRange;
  final RepoRef? repoRef;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isHighlighted;
  final double fontScale;
  final bool showLineNumber;
  final List<WordDiffRange>? wordDiffRanges;
  final DiffViewConfig? config;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ColorScheme colorScheme = context.colorScheme;
    final DiffViewConfig effectiveConfig = config ?? DiffViewConfig.fromSettings(ref.watch(diffSettingsProvider));
    final double opacity = _opacityFor(effectiveConfig.highlightIntensity);
    Color bg = _resolveBackground(context, opacity);
    if (isHighlighted) {
      bg = colorScheme.primaryContainer.withValues(alpha: Opacities.tint);
    }

    final double fontSize = 12 * fontScale;
    final TextStyle lineNumStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: fontSize,
      color: colorScheme.onSurface.withValues(alpha: Opacities.muted),
    );

    final List<Widget> rowChildren = <Widget>[];

    if (blameRange != null) {
      rowChildren.add(
        BlameGutterRow(
          blameRange: blameRange!,
          repoRef: repoRef,
        ),
      );
    }
    if (gutterWidgets != null && gutterWidgets!.isNotEmpty) {
      rowChildren.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: gutterWidgets!
            .map((final Widget w) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: CodeLineLayout.lineNumberWidth,
                    ),
                    child: w,
                  ),
                ),
            )
            .toList(),
      ),);
    }

    if (showLineNumber) {
      if (oldLineNumber != null || newLineNumber != null) {
        rowChildren.addAll(<Widget>[
          SizedBox(
            width: CodeLineLayout.lineNumberWidth,
            child: Text(
              oldLineNumber?.toString() ?? '',
              style: lineNumStyle,
            ),
          ),
          const SizedBox(width: CodeLineLayout.gapAfterOld),
          SizedBox(
            width: CodeLineLayout.lineNumberWidth,
            child: Text(
              newLineNumber?.toString() ?? '',
              style: lineNumStyle,
            ),
          ),
          const SizedBox(width: CodeLineLayout.gapAfterNew),
        ]);
      } else if (lineNumber != null) {
        rowChildren.addAll(<Widget>[
          SizedBox(
            width: CodeLineLayout.lineNumberWidth,
            child: Text(
              lineNumber.toString(),
              style: lineNumStyle,
            ),
          ),
          const SizedBox(width: CodeLineLayout.gapAfterOld),
        ]);
      }
    }

    if (prefix != null && prefix!.isNotEmpty) {
      rowChildren
        ..add(
          SizedBox(
            width: CodeLineLayout.prefixWidth,
            child: Text(
              prefix == ' ' ? ' ' : prefix!,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: fontSize,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        )
        ..add(const SizedBox(width: CodeLineLayout.gapBeforeCode));
    }

    Widget codeContent = CodeBlockView(
      content.isEmpty ? ' ' : content,
      language: language,
      showLineNumbers: false,
    );

    if (wordDiffRanges != null && wordDiffRanges!.isNotEmpty) {
      codeContent = _WordDiffOverlay(
        content: content,
        ranges: wordDiffRanges!,
        fontSize: fontSize,
        child: codeContent,
      );
    }

    rowChildren.add(Expanded(child: codeContent));

    Widget row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CodeLineLayout.rowPadding,
        vertical: 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rowChildren,
      ),
    );

    if (onTap != null || onLongPress != null) {
      row = GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        behavior: HitTestBehavior.opaque,
        child: row,
      );
    }

    return ColoredBox(
      color: backgroundColor ?? bg,
      child: row,
    );
  }

  Color _resolveBackground(final BuildContext context, final double opacity) {
    if (backgroundColor != null) {
      return backgroundColor!;
    }
    final ColorScheme colorScheme = context.colorScheme;
    if (prefix == '+') {
      return colorScheme.surface.withValues(alpha: opacity);
    }
    if (prefix == '-') {
      return colorScheme.surfaceContainerHighest.withValues(alpha: opacity);
    }
    return colorScheme.surface;
  }
}

/// Paints highlight regions over the code line for word-level diff.
/// [ranges] are (start, end) character indices; highlight uses theme primaryContainer.
class _WordDiffOverlay extends StatelessWidget {
  const _WordDiffOverlay({
    required this.content,
    required this.ranges,
    required this.fontSize,
    required this.child,
  });

  final String content;
  final List<WordDiffRange> ranges;
  final double fontSize;
  final Widget child;

  @override
  Widget build(final BuildContext context) =>
      Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        child,
        LayoutBuilder(
          builder: (final BuildContext context, final BoxConstraints constraints) =>
              CustomPaint(
                size: Size(constraints.maxWidth, 20),
                painter: _WordDiffPainter(
                  content: content,
                  ranges: ranges,
                  fontSize: fontSize,
                  color: context.colorScheme.primaryContainer.withValues(
                    alpha: Opacities.tint,
                  ),
                ),
              ),
        ),
      ],
    );
}

class _WordDiffPainter extends CustomPainter {
  _WordDiffPainter({
    required this.content,
    required this.ranges,
    required this.fontSize,
    required this.color,
  });

  final String content;
  final List<WordDiffRange> ranges;
  final double fontSize;
  final Color color;

  @override
  void paint(final Canvas canvas, final Size size) {
    if (content.isEmpty) {
      return;
    }
    final double charWidth =
        size.width / content.length.clamp(1, content.length);
    final Paint paint = Paint()..color = color;
    for (final (int start, int end) in ranges) {
      final int s = start.clamp(0, content.length);
      final int e = end.clamp(0, content.length);
      if (s >= e) {
        continue;
      }
      canvas.drawRect(
        Rect.fromLTWH(s * charWidth, 0, (e - s) * charWidth, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant final CustomPainter oldDelegate) => false;
}
