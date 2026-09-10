import 'package:diohub/app/settings/diff_settings.dart';
import 'package:diohub/common/code/code_line_view.dart';
import 'package:diohub/common/code/inline_thread_card.dart';
import 'package:diohub/common/diff/diff_config.dart';
import 'package:diohub/common/diff/diff_view.dart' show DiffChunkHeader;
import 'package:diohub/common/diff/models.dart';
import 'package:diohub/common/diff/parser.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single-file diff view built from [CodeLineView], with optional inline
/// review threads, context expansion, and hunk collapse.
class DiffFileView extends ConsumerWidget {
  const DiffFileView({
    required this.config,
    super.key,
    this.parsedDiff,
    this.patch,
    this.fileType,
    this.mode = DiffDisplayMode.unified,
    this.threads,
    this.onAddComment,
    this.highlightedLines,
    this.viewedState,
    this.limitLines,
    this.compact = false,
    this.onExpandRequested,
    this.collapsibleHunks = false,
  }) : assert(
         parsedDiff != null || patch != null,
         'Either parsedDiff or patch must be provided',
       );

  final ParsedDiff? parsedDiff;
  final String? patch;
  final DiffViewConfig config;
  final String? fileType;
  final DiffDisplayMode mode;
  final List<InlineThreadData>? threads;
  final void Function(DiffLineTapDetails details, DiffSide side)? onAddComment;
  final Set<DiffLineKey>? highlightedLines;
  final bool? viewedState;
  final int? limitLines;
  final bool compact;
  final VoidCallback? onExpandRequested;
  final bool collapsibleHunks;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ParsedDiff diff = parsedDiff ?? parseUnifiedDiffCached(patch);
    if (diff.isEmpty) {
      return Padding(
        padding: context.spacing.cardContentPadding,
        child: Text(
          'No diff',
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurface.muted,
          ),
        ),
      );
    }

    if (mode == DiffDisplayMode.split) {
      return _buildSplitView(context, diff);
    }
    return _buildUnifiedView(context, diff);
  }

  Widget _buildUnifiedView(final BuildContext context, final ParsedDiff diff) {
    final double maxWidth = _maxContentWidth(context, diff);
    final List<Widget> columnChildren = <Widget>[];

    for (int chunkIndex = 0; chunkIndex < diff.hunks.length; chunkIndex++) {
      final DiffHunk hunk = diff.hunks[chunkIndex];
      final List<DiffLine> lines = buildDiffLines(hunk.info, hunk.rawLines);
      final int? effectiveLimit = limitLines;
      final List<DiffLine> displayLines =
          effectiveLimit != null && lines.length > effectiveLimit
          ? lines.sublist(0, effectiveLimit)
          : lines;
      final bool isTruncated =
          effectiveLimit != null && lines.length > effectiveLimit;

      if (!compact && hunk.displayHeader != null) {
        columnChildren.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DiffChunkHeader(
              displayHeader: hunk.displayHeader!,
              fileType: fileType,
            ),
          ),
        );
      }
      if (compact && hunk.displayHeader != null) {
        columnChildren.add(
          Padding(
            padding: const EdgeInsets.only(
              left: CodeLineLayout.rowPadding,
              right: CodeLineLayout.rowPadding,
              bottom: 4,
            ),
            child: Text(
              hunk.displayHeader!,
              style: context.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: context.colorScheme.onSurface.muted,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }

      for (int i = 0; i < displayLines.length; i++) {
        final DiffLine line = displayLines[i];
        final DiffLineKey key = (line.oldLineNumber, line.newLineNumber);
        columnChildren.add(
          CodeLineView(
            content: line.content,
            oldLineNumber: line.oldLineNumber,
            newLineNumber: line.newLineNumber,
            language: fileType,
            prefix: line.prefix,
            onTap: onAddComment != null
                ? () {
                    final DiffSide side = line.newLineNumber != null
                        ? DiffSide.right
                        : DiffSide.left;
                    onAddComment!(
                      DiffLineTapDetails(
                        oldLineNumber: line.oldLineNumber,
                        newLineNumber: line.newLineNumber,
                        prefix: line.prefix,
                      ),
                      side,
                    );
                  }
                : null,
            isHighlighted: highlightedLines?.contains(key) ?? false,
            fontScale: config.codeFontScale,
            showLineNumber: config.showLineNumbers,
            config: config,
          ),
        );
        _addThreadCardsAfterLine(
          columnChildren: columnChildren,
          context: context,
          line: line,
        );
      }

      if (isTruncated) {
        columnChildren.add(
          Padding(
            padding: context.spacing.cardContentPadding,
            child: GestureDetector(
              onTap: onExpandRequested,
              child: Text(
                '...Tap to view whole diff.',
                style: context.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: context.colorScheme.primary,
                ),
              ),
            ),
          ),
        );
      }
    }

    final Widget listChild = ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: columnChildren,
    );

    final bool isUnviewed = viewedState == false;
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest.withValues(
          alpha: Opacities.tintSubtle,
        ),
        borderRadius: context.radius(RadiusSize.medium),
        border: Border.all(
          color: isUnviewed
              ? context.colorScheme.primary.withValues(alpha: 0.4)
              : context.colorScheme.outlineVariant.borderO,
          width: isUnviewed ? 1.5 : 1,
        ),
      ),
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: config.wrap ? MediaQuery.of(context).size.width : maxWidth,
          child: listChild,
        ),
      ),
    );
  }

  void _addThreadCardsAfterLine({
    required final List<Widget> columnChildren,
    required final BuildContext context,
    required final DiffLine line,
  }) {
    final List<InlineThreadData>? threadList = threads;
    if (threadList == null) {
      return;
    }
    for (final InlineThreadData t in threadList) {
      final bool matchRight =
          t.side == DiffSide.right && line.newLineNumber == t.line;
      final bool matchLeft =
          t.side == DiffSide.left && line.oldLineNumber == t.line;
      if (matchRight || matchLeft) {
        columnChildren.add(InlineThreadCard(data: t, compact: compact));
      }
    }
  }

  Widget _buildSplitView(final BuildContext context, final ParsedDiff diff) =>
      _buildUnifiedView(context, diff);

  double _maxContentWidth(final BuildContext context, final ParsedDiff diff) {
    int maxChars = 0;
    for (final DiffHunk hunk in diff.hunks) {
      for (final String raw in hunk.rawLines) {
        if (raw.length > maxChars) {
          maxChars = raw.length;
        }
      }
    }
    return (maxChars * 10)
        .clamp(200.0, MediaQuery.of(context).size.width * 2)
        .toDouble();
  }
}
