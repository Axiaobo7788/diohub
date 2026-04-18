import 'package:flutter/material.dart';

/// A lightweight vertical timeline rail that places an [indicator] widget
/// between optional before/after connector lines, with an [endChild] beside it.
///
/// This replaces the `timeline_tile` package's [TimelineTile] to avoid its
/// internal `LayoutBuilder` → `IntrinsicHeight` combination which crashes
/// inside sliver contexts (unbounded height → layout assertion failures).
///
/// Only supports vertical axis with start alignment (indicator on the left,
/// content on the right) — the only configuration used in this codebase.
class TimelineRail extends StatelessWidget {
  const TimelineRail({
    required this.endChild,
    this.isFirst = false,
    this.isLast = false,
    this.indicatorWidth = 25,
    this.indicatorHeight = 25,
    this.indicator,
    this.lineThickness = 2,
    this.lineColor = Colors.grey,
    this.beforeLineThickness,
    this.beforeLineColor,
    this.afterLineThickness,
    this.afterLineColor,
    super.key,
  });

  /// The content widget displayed to the right of the timeline rail.
  final Widget endChild;

  /// Whether this is the first item (no line drawn above the indicator).
  final bool isFirst;

  /// Whether this is the last item (no line drawn below the indicator).
  final bool isLast;

  /// Width of the indicator area (horizontal extent of the rail column).
  final double indicatorWidth;

  /// Height of the indicator widget.
  final double indicatorHeight;

  /// Custom indicator widget. When null, a gap of [indicatorHeight] is used.
  final Widget? indicator;

  /// Default line thickness (used for both before and after unless overridden).
  final double lineThickness;

  /// Default line color (used for both before and after unless overridden).
  final Color lineColor;

  /// Override thickness for the line before the indicator.
  final double? beforeLineThickness;

  /// Override color for the line before the indicator.
  final Color? beforeLineColor;

  /// Override thickness for the line after the indicator.
  final double? afterLineThickness;

  /// Override color for the line after the indicator.
  final Color? afterLineColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _TimelineRailPainter(
        isFirst: isFirst,
        isLast: isLast,
        indicatorWidth: indicatorWidth,
        indicatorHeight: indicatorHeight,
        lineThickness: lineThickness,
        lineColor: lineColor,
        beforeLineThickness: beforeLineThickness,
        beforeLineColor: beforeLineColor,
        afterLineThickness: afterLineThickness,
        afterLineColor: afterLineColor,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Timeline rail column: indicator only (lines drawn by painter).
          SizedBox(
            width: indicatorWidth,
            height: indicatorHeight,
            child: indicator,
          ),

          // Content area.
          Expanded(child: endChild),
        ],
      ),
    );
  }
}

/// Custom painter that draws timeline connector lines.
///
/// Draws vertical lines before and after the indicator, using the actual
/// widget height determined during layout (avoiding IntrinsicHeight).
class _TimelineRailPainter extends CustomPainter {
  _TimelineRailPainter({
    required this.isFirst,
    required this.isLast,
    required this.indicatorWidth,
    required this.indicatorHeight,
    required this.lineThickness,
    required this.lineColor,
    this.beforeLineThickness,
    this.beforeLineColor,
    this.afterLineThickness,
    this.afterLineColor,
  });

  final bool isFirst;
  final bool isLast;
  final double indicatorWidth;
  final double indicatorHeight;
  final double lineThickness;
  final Color lineColor;
  final double? beforeLineThickness;
  final Color? beforeLineColor;
  final double? afterLineThickness;
  final Color? afterLineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = indicatorWidth / 2;
    final double indicatorBottom = indicatorHeight;

    // After line (below indicator to bottom of widget).
    if (!isLast) {
      final paint = Paint()
        ..color = afterLineColor ?? lineColor
        ..strokeWidth = afterLineThickness ?? lineThickness
        ..strokeCap = StrokeCap.butt;
      canvas.drawLine(
        Offset(centerX, indicatorBottom),
        Offset(centerX, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineRailPainter oldDelegate) =>
      isFirst != oldDelegate.isFirst ||
      isLast != oldDelegate.isLast ||
      indicatorWidth != oldDelegate.indicatorWidth ||
      indicatorHeight != oldDelegate.indicatorHeight ||
      lineThickness != oldDelegate.lineThickness ||
      lineColor != oldDelegate.lineColor ||
      beforeLineThickness != oldDelegate.beforeLineThickness ||
      beforeLineColor != oldDelegate.beforeLineColor ||
      afterLineThickness != oldDelegate.afterLineThickness ||
      afterLineColor != oldDelegate.afterLineColor;
}
