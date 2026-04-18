import 'package:diohub/common/code/blame_utils.dart';
import 'package:diohub/common/code/code_file_view.dart' show CodeAnnotation;
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/tree_typedefs.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';

/// Width of the blame gutter when shown.
const double kBlameGutterWidth = 52;

/// Blame gutter widget for use with re_editor's [CodeEditor.indicatorBuilder].
///
/// Listens to [notifier] to get visible paragraphs, maps line numbers to
/// [blameRanges], and paints a colored strip with abbreviated OID. Tap opens
/// the shared blame sheet.
class BlameGutterIndicator extends ConsumerWidget {
  const BlameGutterIndicator({
    required this.notifier,
    required this.blameRanges,
    super.key,
    this.repoRef,
  });

  final CodeIndicatorValueNotifier notifier;
  final List<BlameRange> blameRanges;
  final RepoRef? repoRef;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<CodeIndicatorValue?>(
      valueListenable: notifier,
      builder: (final BuildContext context, final CodeIndicatorValue? value,
          final _) {
        if (value == null || value.paragraphs.isEmpty) {
          return const SizedBox(width: kBlameGutterWidth);
        }
        return SizedBox(
          width: kBlameGutterWidth,
          child: LayoutBuilder(
            builder:
                (final BuildContext context, final BoxConstraints constraints) {
              return Stack(
                children: <Widget>[
                  CustomPaint(
                    size: Size(kBlameGutterWidth, constraints.maxHeight),
                    painter: _BlameGutterPainter(
                      paragraphs: value.paragraphs,
                      blameRanges: blameRanges,
                      scheme: scheme,
                    ),
                  ),
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTapUp: (final TapUpDetails d) {
                        final int? idx = _paragraphIndexAt(
                            d.localPosition.dy, value.paragraphs);
                        if (idx != null) {
                          final int lineNum = value.paragraphs[idx].index + 1;
                          final BlameRange? r =
                              blameRangeForLine(lineNum, blameRanges);
                          if (r != null) {
                            showBlameSheet(context, ref, r, repoRef);
                          }
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  static int? _paragraphIndexAt(
    final double dy,
    final List<CodeLineRenderParagraph> paragraphs,
  ) {
    for (int i = 0; i < paragraphs.length; i++) {
      final CodeLineRenderParagraph p = paragraphs[i];
      if (dy >= p.top && dy < p.bottom) {
        return i;
      }
    }
    return null;
  }
}

class _BlameGutterPainter extends CustomPainter {
  _BlameGutterPainter({
    required this.paragraphs,
    required this.blameRanges,
    required this.scheme,
  });

  final List<CodeLineRenderParagraph> paragraphs;
  final List<BlameRange> blameRanges;
  final ColorScheme scheme;

  @override
  void paint(final Canvas canvas, final Size size) {
    if (paragraphs.isEmpty) {
      return;
    }
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    for (final CodeLineRenderParagraph p in paragraphs) {
      final int lineNum = p.index + 1;
      final BlameRange? range = blameRangeForLine(lineNum, blameRanges);
      if (range != null) {
        final Color bg = blameAgeColor(range.age, scheme);
        canvas.drawRect(
          Rect.fromLTWH(0, p.top, size.width, p.preferredLineHeight),
          Paint()..color = bg,
        );
        textPainter
          ..text = TextSpan(
            text: range.commit.abbreviatedOid,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: scheme.primary,
            ),
          )
          ..layout();
        textPainter.paint(
          canvas,
          Offset(4, p.top + (p.preferredLineHeight - textPainter.height) / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(final _BlameGutterPainter oldDelegate) =>
      oldDelegate.paragraphs != paragraphs ||
      oldDelegate.blameRanges != blameRanges ||
      oldDelegate.scheme != scheme;
}

/// Gutter indicator that shows CI annotation dots (failure/warning/notice) per line.
/// Use with re_editor's [CodeEditor.indicatorBuilder] when [annotations] is non-null.
class AnnotationGutterIndicator extends StatelessWidget {
  const AnnotationGutterIndicator({
    required this.notifier,
    required this.annotations,
    super.key,
  });

  final CodeIndicatorValueNotifier notifier;
  final List<CodeAnnotation> annotations;

  static Color _colorForLevel(final String level, final ColorScheme scheme) {
    return switch (level.toUpperCase()) {
      'FAILURE' => scheme.error,
      'WARNING' => scheme.tertiary,
      _ => scheme.primary,
    };
  }

  static CodeAnnotation? _annotationForLine(
    final int oneBasedLine,
    final List<CodeAnnotation> list,
  ) {
    for (final CodeAnnotation a in list) {
      if (a.line == oneBasedLine) return a;
    }
    return null;
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<CodeIndicatorValue?>(
      valueListenable: notifier,
      builder: (final BuildContext context, final CodeIndicatorValue? value,
          final _) {
        if (value == null || value.paragraphs.isEmpty || annotations.isEmpty) {
          return context.spacing.sectionGap;
        }
        return SizedBox(
          width: 16,
          child: LayoutBuilder(
            builder:
                (final BuildContext context, final BoxConstraints constraints) {
              return CustomPaint(
                size: Size(16, constraints.maxHeight),
                painter: _AnnotationGutterPainter(
                  paragraphs: value.paragraphs,
                  annotations: annotations,
                  scheme: scheme,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _AnnotationGutterPainter extends CustomPainter {
  _AnnotationGutterPainter({
    required this.paragraphs,
    required this.annotations,
    required this.scheme,
  });

  final List<CodeLineRenderParagraph> paragraphs;
  final List<CodeAnnotation> annotations;
  final ColorScheme scheme;

  @override
  void paint(final Canvas canvas, final Size size) {
    for (final CodeLineRenderParagraph p in paragraphs) {
      final int lineNum = p.index + 1;
      final CodeAnnotation? a =
          AnnotationGutterIndicator._annotationForLine(lineNum, annotations);
      if (a != null) {
        final Color color =
            AnnotationGutterIndicator._colorForLevel(a.level, scheme);
        final double centerX = size.width / 2;
        final double centerY = p.top + p.preferredLineHeight / 2;
        canvas.drawCircle(
          Offset(centerX, centerY),
          4,
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(final _AnnotationGutterPainter oldDelegate) =>
      oldDelegate.paragraphs != paragraphs ||
      oldDelegate.annotations != annotations ||
      oldDelegate.scheme != scheme;
}

/// Standalone row widget for a single line's blame gutter (e.g. in diff view per-line).
/// Same visual as BlameGutterIndicator but for one line so CodeLineView can use it.
class BlameGutterRow extends ConsumerWidget {
  const BlameGutterRow({
    required this.blameRange,
    super.key,
    this.repoRef,
  });

  final BlameRange blameRange;
  final RepoRef? repoRef;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color bg = blameAgeColor(blameRange.age, scheme);
    return GestureDetector(
      onTap: () => showBlameSheet(context, ref, blameRange, repoRef),
      child: Container(
        width: kBlameGutterWidth,
        padding: const EdgeInsets.only(right: 4),
        color: bg,
        alignment: Alignment.centerLeft,
        child: Text(
          blameRange.commit.abbreviatedOid,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: scheme.primary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
