import 'package:diohub/app/settings/diff_settings.dart';
import 'package:diohub/common/code/blame_gutter_indicator.dart';
import 'package:diohub/common/code/code_find_panel.dart';
import 'package:diohub/common/code/code_file_view.dart' show CodeAnnotation;
import 'package:diohub/common/code/code_theme.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/tree_typedefs.dart';
import 'package:diohub/providers/settings/diff_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';

/// Unified code viewing/editing widget: re_editor with app theme, gutters, and find.
///
/// Use for file view, blame tab, inline previews, and markdown code blocks.
/// Shares blame/annotation gutters and theme with diff views.
class AppCodeEditor extends ConsumerStatefulWidget {
  const AppCodeEditor({
    required this.code,
    super.key,
    this.language,
    this.readOnly = true,
    this.blameRanges,
    this.annotations,
    this.highlightedLineRange,
    this.onLineTap,
    this.controller,
    this.repoRef,
    this.showLineNumbers,
    this.wordWrap,
    this.enableFolding = true,
    this.maxHeight,
  });

  final String code;
  final String? language;
  final bool readOnly;
  final List<BlameRange>? blameRanges;
  final List<CodeAnnotation>? annotations;
  final (int, int)? highlightedLineRange;
  final void Function(int lineNumber)? onLineTap;
  final CodeLineEditingController? controller;
  final RepoRef? repoRef;
  final bool? showLineNumbers;
  final bool? wordWrap;
  final bool enableFolding;
  final double? maxHeight;

  @override
  ConsumerState<AppCodeEditor> createState() => _AppCodeEditorState();
}

class _AppCodeEditorState extends ConsumerState<AppCodeEditor> {
  late CodeLineEditingController _controller;
  bool _controllerOwned = false;
  bool _highlightApplied = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = CodeLineEditingController.fromText(widget.code);
      _controllerOwned = true;
    }
    if (widget.highlightedLineRange != null) {
      WidgetsBinding.instance.addPostFrameCallback((final _) {
        if (mounted) _applyHighlightIfNeeded();
      });
    }
  }

  @override
  void didUpdateWidget(final AppCodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (_controllerOwned) {
        _controller.dispose();
      }
      if (widget.controller != null) {
        _controller = widget.controller!;
        _controllerOwned = false;
      } else {
        _controller = CodeLineEditingController.fromText(widget.code);
        _controllerOwned = true;
      }
      _highlightApplied = false;
      WidgetsBinding.instance.addPostFrameCallback((final _) {
        if (mounted) _applyHighlightIfNeeded();
      });
    } else if (widget.controller == null &&
        (widget.code != oldWidget.code ||
            widget.highlightedLineRange != oldWidget.highlightedLineRange)) {
      if (_controllerOwned) {
        _controller.text = widget.code;
      }
      _highlightApplied = false;
      WidgetsBinding.instance.addPostFrameCallback((final _) {
        if (mounted) _applyHighlightIfNeeded();
      });
    }
  }

  @override
  void dispose() {
    if (_controllerOwned) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _applyHighlightIfNeeded() {
    if (_highlightApplied) return;
    final (int, int)? range = widget.highlightedLineRange;
    if (range == null) return;
    final int start = (range.$1 - 1).clamp(0, _controller.lineCount - 1);
    final int end = (range.$2 - 1).clamp(0, _controller.lineCount - 1);
    _controller.selectLines(start, end);
    _controller.makePositionCenterIfInvisible(
      CodeLinePosition(index: start, offset: 0),
    );
    _highlightApplied = true;
  }

  @override
  Widget build(final BuildContext context) {
    final DiffSettings settings = ref.watch(diffSettingsProvider);
    final bool showLineNumbers =
        widget.showLineNumbers ?? settings.showLineNumbers;
    final bool wordWrap = widget.wordWrap ?? settings.wrapLines;
    final Brightness brightness = Theme.of(context).colorScheme.brightness;
    final String lang = widget.language ?? 'plaintext';
    final CodeHighlightTheme highlightTheme =
        codeHighlightTheme(settings.codeBlockTheme, brightness, lang);

    final double fontSize = 12.0 * settings.codeFontScale;
    final CodeEditorStyle style = CodeEditorStyle(
      fontSize: fontSize,
      fontFamily: 'monospace',
      codeTheme: highlightTheme,
    );

    Widget child = CodeEditor(
      controller: _controller,
      style: style,
      readOnly: widget.readOnly,
      wordWrap: wordWrap,
      indicatorBuilder: (
        final BuildContext context,
        final CodeLineEditingController editingController,
        final CodeChunkController chunkController,
        final CodeIndicatorValueNotifier notifier,
      ) {
        final List<Widget> indicators = <Widget>[];
        if (showLineNumbers) {
          indicators.add(
            DefaultCodeLineNumber(
              controller: editingController,
              notifier: notifier,
            ),
          );
        }
        if (widget.blameRanges != null && widget.blameRanges!.isNotEmpty) {
          indicators.add(
            BlameGutterIndicator(
              notifier: notifier,
              blameRanges: widget.blameRanges!,
              repoRef: widget.repoRef,
            ),
          );
        }
        if (widget.annotations != null && widget.annotations!.isNotEmpty) {
          indicators.add(
            AnnotationGutterIndicator(
              notifier: notifier,
              annotations: widget.annotations!,
            ),
          );
        }
        if (widget.enableFolding) {
          indicators.add(
            DefaultCodeChunkIndicator(
              width: 20,
              controller: chunkController,
              notifier: notifier,
            ),
          );
        }
        return Row(
          children: indicators,
        );
      },
      findBuilder: (final BuildContext context,
          final CodeFindController findController, final bool readOnly) {
        return CodeFindPanel(
          controller: findController,
          readOnly: readOnly,
        );
      },
      chunkAnalyzer: widget.enableFolding ? null : const NonCodeChunkAnalyzer(),
    );

    if (widget.maxHeight != null) {
      child = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxHeight!),
        child: child,
      );
    }

    return child;
  }
}
