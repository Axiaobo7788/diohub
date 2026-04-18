import 'package:diohub/common/code/app_code_editor.dart';
import 'package:diohub/common/code/code_view_config.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/tree_typedefs.dart';
import 'package:diohub/providers/settings/diff_settings_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// CI check annotation for a line (or range). Used to show warning/error dots in gutter.
class CodeAnnotation {
  const CodeAnnotation({
    required this.line,
    required this.message,
    this.title,
    this.level = 'NOTICE',
  });

  final int line;
  final String message;
  final String? title;
  final String level; // FAILURE, WARNING, NOTICE
}

/// Full file view backed by [AppCodeEditor]: blame gutter, annotations, find, scroll-to-line.
///
/// Same public API as before; [scrollController] and [searchQuery] are not wired to the
/// editor (re_editor manages scroll and find internally). [initialScrollToLine] is
/// applied via [highlightedLineRange] when [highlightedLineRange] is null.
class CodeFileView extends ConsumerWidget {
  const CodeFileView({
    required this.lines,
    super.key,
    this.language,
    this.config,
    this.highlightedLineRange,
    this.blameRanges,
    this.annotations,
    this.onLineTap,
    this.scrollController,
    this.initialScrollToLine,
    this.searchQuery,
    this.showMinimap = false,
    this.repoRef,
  });

  final List<String> lines;
  final String? language;
  final CodeViewConfig? config;
  final (int, int)? highlightedLineRange;
  final List<BlameRange>? blameRanges;
  final List<CodeAnnotation>? annotations;
  final void Function(int lineNumber)? onLineTap;
  final ScrollController? scrollController;
  final int? initialScrollToLine;
  final String? searchQuery;
  final bool showMinimap;
  /// When set, blame popup shows "View Commit".
  final RepoRef? repoRef;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final CodeViewConfig effectiveConfig = config ??
        CodeViewConfig.fromSettings(ref.watch(diffSettingsProvider));
    final int lineCount = lines.length;
    if (lineCount == 0) {
      final ThemeData theme = Theme.of(context);
      return Center(
        child: Text(
          'Empty file',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final String code = lines.join('\n');
    final (int, int)? effectiveHighlight = highlightedLineRange ??
        (initialScrollToLine != null
            ? (initialScrollToLine!.clamp(1, lineCount),
                initialScrollToLine!.clamp(1, lineCount))
            : null);
    final List<BlameRange>? showBlame =
        effectiveConfig.showBlame ? blameRanges : null;
    final List<CodeAnnotation>? showAnnotations =
        effectiveConfig.showAnnotations ? annotations : null;

    return Padding(
      padding: context.spacing.screenPadding,
      child: AppCodeEditor(
        code: code,
        language: language ?? 'plaintext',
        readOnly: true,
        showLineNumbers: effectiveConfig.showLineNumbers,
        wordWrap: effectiveConfig.wrap,
        blameRanges: showBlame,
        annotations: showAnnotations,
        highlightedLineRange: effectiveHighlight,
        onLineTap: onLineTap,
        repoRef: repoRef,
      ),
    );
  }
}
