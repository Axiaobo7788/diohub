import 'package:diohub/common/code/app_code_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Code block display using [AppCodeEditor] (re_editor + app theme).
class CodeBlockView extends ConsumerWidget {
  const CodeBlockView(
    this.data, {
    this.language,
    this.showLineNumbers,
    this.highlightedLineRange,
    this.onLineTap,
    super.key,
  });

  final String data;
  final String? language;

  /// When null, defaults to [DiffSettings.showLineNumbers].
  final bool? showLineNumbers;

  /// Optional (startLine, endLine) range (1-based) to highlight.
  final (int, int)? highlightedLineRange;

  /// Called when a line is tapped (1-based line number).
  final void Function(int line)? onLineTap;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return AppCodeEditor(
      code: data,
      language: language ?? 'plaintext',
      readOnly: true,
      showLineNumbers: showLineNumbers,
      highlightedLineRange: highlightedLineRange,
      onLineTap: onLineTap,
      enableFolding: false,
    );
  }
}
