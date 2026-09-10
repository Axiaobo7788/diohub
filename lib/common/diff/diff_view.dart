import 'package:diohub/app/settings/diff_settings.dart';
import 'package:diohub/common/diff/diff_config.dart';
import 'package:diohub/common/diff/models.dart';
import 'package:diohub/common/diff/parser.dart';
import 'package:diohub/common/misc/code_block_view.dart';
import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

/// Wrap toggle button for diff/code view (used in AppBar and sheets).
class WrapIconButton extends StatelessWidget {
  const WrapIconButton({
    required this.wrap,
    required this.onWrap,
    super.key,
    this.size = 24,
  });

  final bool wrap;
  final ValueChanged<bool> onWrap;
  final double size;

  @override
  Widget build(final BuildContext context) => TapFeedback(
    onTap: () => onWrap(!wrap),
    child: Padding(
      padding: EdgeInsets.all(size / 2),
      child: Icon(
        Icons.wrap_text_rounded,
        size: size,
        color: context.colorScheme.onSurface.withValues(alpha: wrap ? 1 : 0.5),
      ),
    ),
  );
}

/// Column width constants for diff line layout.
class _DiffLayout {
  static const double lineNumberWidth = 35;
  static const double gapAfterOld = 10;
  static const double gapAfterNew = 5;
  static const double prefixWidth = 5;
  static const double gapBeforeCode = 20;
  static const double rowPadding = 8;
}

/// Single row: old line number, new line number, prefix, code.
class DiffLineRow extends StatelessWidget {
  const DiffLineRow({
    required this.line,
    required this.config,
    this.fileType,
    this.onTap,
    this.isHighlighted = false,
    super.key,
  });

  final DiffLine line;
  final DiffViewConfig config;
  final String? fileType;
  final VoidCallback? onTap;
  final bool isHighlighted;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colorScheme = context.colorScheme;
    final double opacity = _opacityFor(config.highlightIntensity);
    Color bg = _backgroundColor(context, opacity);
    if (isHighlighted) {
      bg = colorScheme.primaryContainer.withValues(alpha: Opacities.tint);
    }

    final TextStyle lineNumStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12 * config.codeFontScale,
      color: colorScheme.onSurface.muted,
    );

    Widget row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _DiffLayout.rowPadding,
        vertical: 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (config.showLineNumbers) ...<Widget>[
            SizedBox(
              width: _DiffLayout.lineNumberWidth,
              child: Text(
                line.oldLineNumber?.toString() ?? '',
                style: lineNumStyle,
              ),
            ),
            const SizedBox(width: _DiffLayout.gapAfterOld),
            SizedBox(
              width: _DiffLayout.lineNumberWidth,
              child: Text(
                line.newLineNumber?.toString() ?? '',
                style: lineNumStyle,
              ),
            ),
            const SizedBox(width: _DiffLayout.gapAfterNew),
          ],
          SizedBox(
            width: _DiffLayout.prefixWidth,
            child: Text(
              line.prefix == '' ? ' ' : line.prefix,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12 * config.codeFontScale,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: _DiffLayout.gapBeforeCode),
          Expanded(
            child: CodeBlockView(
              line.content.isEmpty ? ' ' : line.content,
              language: fileType,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      row = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: row,
      );
    }
    return ColoredBox(color: bg, child: row);
  }

  Color _backgroundColor(final BuildContext context, final double opacity) {
    final ColorScheme colorScheme = context.colorScheme;
    if (line.isAddition) {
      return colorScheme.surface.withValues(alpha: opacity);
    }
    if (line.isRemoval) {
      return colorScheme.surfaceContainerHighest.withValues(alpha: opacity);
    }
    return colorScheme.surface;
  }
}

double _opacityFor(final DiffHighlightIntensity intensity) =>
    switch (intensity) {
      DiffHighlightIntensity.subtle => Opacities.tintSubtle,
      DiffHighlightIntensity.default_ => Opacities.tint,
      DiffHighlightIntensity.high => Opacities.tintMedium,
    };

/// Chunk header bar (e.g. @@ -1,5 +1,6 @@). Optional [contextLines] for expand;
/// when null, expand is not shown (e.g. PR comment without blob).
class DiffChunkHeader extends StatelessWidget {
  const DiffChunkHeader({
    required this.displayHeader,
    this.contextLines,
    this.fileType,
    super.key,
  });

  final String displayHeader;
  final List<String>? contextLines;
  final String? fileType;

  @override
  Widget build(final BuildContext context) {
    final bool canExpand = contextLines != null && contextLines!.isNotEmpty;
    return Container(
      padding: context.spacing.cardContentPadding,
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHigh.withValues(
          alpha: Opacities.tint,
        ),
        borderRadius: context.radius(RadiusSize.small),
        border: Border.all(
          color: context.colorScheme.outlineVariant.borderO,
          width: 0.5,
        ),
      ),
      child: Row(
        children: <Widget>[
          if (canExpand)
            Icon(
              Icons.expand_more,
              size: 18,
              color: context.colorScheme.onSurface.secondary,
            ),
          if (canExpand) SizedBox(width: context.spacing.chipPadding.left),
          Expanded(
            child: Text(
              displayHeader,
              style: context.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: context.colorScheme.onSurface.secondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Config-driven diff view. Takes [ParsedDiff] (or [patch] string) and [config].
/// Optional [limitLines] for inline snippet; [onExpandRequested] when user taps to see full diff.
/// [onLineTap] fires when a line is tapped (e.g. for PR review threads).
/// [highlightedLines] marks which lines to highlight (e.g. lines with review comments).
/// [viewedState] when false shows an unviewed accent (PR file list).
class DiffView extends StatelessWidget {
  const DiffView({
    required this.config,
    super.key,
    this.parsedDiff,
    this.patch,
    this.fileType,
    this.limitLines,
    this.onExpandRequested,
    this.onLineTap,
    this.highlightedLines,
    this.viewedState,
    this.compact = false,
  }) : assert(parsedDiff != null || patch != null);

  final ParsedDiff? parsedDiff;
  final String? patch;
  final DiffViewConfig config;
  final String? fileType;
  final int? limitLines;
  final VoidCallback? onExpandRequested;
  final ValueChanged<DiffLineTapDetails>? onLineTap;
  final Set<DiffLineKey>? highlightedLines;
  final bool? viewedState;
  final bool compact;

  @override
  Widget build(final BuildContext context) {
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

    final double maxWidth = _maxContentWidth(context, diff);
    final SingleChildScrollView child = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: config.wrap ? MediaQuery.of(context).size.width : maxWidth,
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: diff.hunks.length,
          itemBuilder: (final BuildContext context, final int chunkIndex) {
            final DiffHunk hunk = diff.hunks[chunkIndex];
            final List<DiffLine> lines = buildDiffLines(
              hunk.info,
              hunk.rawLines,
            );
            final int? effectiveLimit = limitLines;
            final List<DiffLine> displayLines =
                effectiveLimit != null && lines.length > effectiveLimit
                ? lines.sublist(0, effectiveLimit)
                : lines;
            final bool isTruncated =
                effectiveLimit != null && lines.length > effectiveLimit;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (!compact && hunk.displayHeader != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DiffChunkHeader(
                      displayHeader: hunk.displayHeader!,
                      fileType: fileType,
                    ),
                  ),
                if (compact && hunk.displayHeader != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: _DiffLayout.rowPadding,
                      right: _DiffLayout.rowPadding,
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
                ...displayLines.map((final DiffLine line) {
                  final DiffLineKey key = (
                    line.oldLineNumber,
                    line.newLineNumber,
                  );
                  return DiffLineRow(
                    line: line,
                    config: config,
                    fileType: fileType,
                    onTap: onLineTap != null
                        ? () => onLineTap!(
                            DiffLineTapDetails(
                              oldLineNumber: line.oldLineNumber,
                              newLineNumber: line.newLineNumber,
                              prefix: line.prefix,
                            ),
                          )
                        : null,
                    isHighlighted: highlightedLines?.contains(key) ?? false,
                  );
                }),
                if (isTruncated) ...<Widget>[
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
                ],
              ],
            );
          },
        ),
      ),
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
      child: child,
    );
  }

  double _maxContentWidth(final BuildContext context, final ParsedDiff diff) {
    int maxChars = 0;
    for (final DiffHunk hunk in diff.hunks) {
      for (final String line in hunk.rawLines) {
        if (line.length > maxChars) maxChars = line.length;
      }
    }
    return (maxChars * 10)
        .clamp(200.0, MediaQuery.of(context).size.width * 2)
        .toDouble();
  }
}
