import 'package:diohub/style/opacities.dart';
import 'package:flutter/material.dart';

/// Generic timeline widget with left and right children
/// Useful for layouts where you want content on both sides of the timeline
class LeftRightTimelineItem extends StatelessWidget {
  const LeftRightTimelineItem({
    required this.leftChild,
    required this.rightChild,
    this.isFirst = false,
    this.isLast = false,
    // Layout customization
    this.leftWidth = 80.0,
    this.lineThickness = 2.0,
    this.dotSize = 12.0,
    this.horizontalPadding = 16.0,
    this.verticalPadding = 8.0,
    // Styling
    this.dotColor,
    this.lineColor,
    this.dotBorderColor,
    // Alignment
    this.leftAlignment = CrossAxisAlignment.end,
    this.rightAlignment = CrossAxisAlignment.start,
    super.key,
  });

  /// Widget to display on the left side of the timeline
  final Widget leftChild;

  /// Widget to display on the right side of the timeline
  final Widget rightChild;

  /// Whether this is the first item in the timeline
  final bool isFirst;

  /// Whether this is the last item in the timeline
  final bool isLast;

  /// Width of the left child area
  final double leftWidth;

  /// Thickness of the timeline line
  final double lineThickness;

  /// Size of the timeline dot
  final double dotSize;

  /// Horizontal padding around the timeline line
  final double horizontalPadding;

  /// Vertical padding around the entire item
  final double verticalPadding;

  /// Color of the timeline dot (defaults to primary color)
  final Color? dotColor;

  /// Color of the timeline line (defaults to outlineVariant with opacity)
  final Color? lineColor;

  /// Color of the timeline dot border (defaults to surface color)
  final Color? dotBorderColor;

  /// Alignment of the left child column
  final CrossAxisAlignment leftAlignment;

  /// Alignment of the right child column
  final CrossAxisAlignment rightAlignment;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color effectiveDotColor = dotColor ?? theme.colorScheme.primary;
    final Color effectiveLineColor =
        lineColor ?? theme.colorScheme.outlineVariant.hinted;
    final Color effectiveDotBorderColor =
        dotBorderColor ?? theme.colorScheme.surface;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: CustomPaint(
        foregroundPainter: _LeftRightTimelinePainter(
          isFirst: isFirst,
          isLast: isLast,
          leftWidth: leftWidth,
          dotSize: dotSize,
          horizontalPadding: horizontalPadding,
          lineThickness: lineThickness,
          lineColor: effectiveLineColor,
          dotColor: effectiveDotColor,
          dotBorderColor: effectiveDotBorderColor,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Left side
            SizedBox(
              width: leftWidth,
              child: Column(
                crossAxisAlignment: leftAlignment,
                children: <Widget>[leftChild],
              ),
            ),

            // Timeline dot placeholder (actual dot drawn by painter)
            SizedBox(
              width: dotSize + (horizontalPadding * 2),
              height: dotSize,
            ),

            // Right side
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: horizontalPadding),
                child: Column(
                  crossAxisAlignment: rightAlignment,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[rightChild],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter that draws the timeline rail and dot for LeftRightTimelineItem.
///
/// Draws vertical lines before and after the dot, and the dot itself,
/// using the actual widget height determined during layout.
class _LeftRightTimelinePainter extends CustomPainter {
  _LeftRightTimelinePainter({
    required this.isFirst,
    required this.isLast,
    required this.leftWidth,
    required this.dotSize,
    required this.horizontalPadding,
    required this.lineThickness,
    required this.lineColor,
    required this.dotColor,
    required this.dotBorderColor,
  });

  final bool isFirst;
  final bool isLast;
  final double leftWidth;
  final double dotSize;
  final double horizontalPadding;
  final double lineThickness;
  final Color lineColor;
  final Color dotColor;
  final Color dotBorderColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate the center X position of the timeline rail
    final double centerX = leftWidth + horizontalPadding + (dotSize / 2);
    final double dotCenterY = dotSize / 2;

    // Draw top line (if not first)
    if (!isFirst) {
      final linePaint = Paint()
        ..color = lineColor
        ..strokeWidth = lineThickness
        ..strokeCap = StrokeCap.butt;
      canvas.drawLine(
        Offset(centerX, 0),
        Offset(centerX, dotCenterY),
        linePaint,
      );
    }

    // Draw bottom line (if not last)
    if (!isLast) {
      final linePaint = Paint()
        ..color = lineColor
        ..strokeWidth = lineThickness
        ..strokeCap = StrokeCap.butt;
      canvas.drawLine(
        Offset(centerX, dotCenterY),
        Offset(centerX, size.height),
        linePaint,
      );
    }

    // Draw the timeline dot with border
    final dotRadius = dotSize / 2;
    
    // Draw dot background
    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, dotCenterY), dotRadius, dotPaint);

    // Draw dot border
    final borderPaint = Paint()
      ..color = dotBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(centerX, dotCenterY), dotRadius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _LeftRightTimelinePainter oldDelegate) =>
      isFirst != oldDelegate.isFirst ||
      isLast != oldDelegate.isLast ||
      leftWidth != oldDelegate.leftWidth ||
      dotSize != oldDelegate.dotSize ||
      horizontalPadding != oldDelegate.horizontalPadding ||
      lineThickness != oldDelegate.lineThickness ||
      lineColor != oldDelegate.lineColor ||
      dotColor != oldDelegate.dotColor ||
      dotBorderColor != oldDelegate.dotBorderColor;
}
