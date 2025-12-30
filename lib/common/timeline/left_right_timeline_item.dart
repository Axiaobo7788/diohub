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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveDotColor = dotColor ?? theme.colorScheme.primary;
    final effectiveLineColor = lineColor ??
        theme.colorScheme.outlineVariant.withOpacity(0.5);
    final effectiveDotBorderColor =
        dotBorderColor ?? theme.colorScheme.surface;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side
            SizedBox(
              width: leftWidth,
              child: Column(
                crossAxisAlignment: leftAlignment,
                children: [leftChild],
              ),
            ),

            // Timeline line column
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                children: [
                  // Top line (if not first)
                  if (!isFirst)
                    Expanded(
                      child: Container(
                        width: lineThickness,
                        color: effectiveLineColor,
                      ),
                    ),
                  // Timeline dot
                  Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: effectiveDotColor,
                      border: Border.all(
                        color: effectiveDotBorderColor,
                        width: 2,
                      ),
                    ),
                  ),
                  // Bottom line (if not last)
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: lineThickness,
                        color: effectiveLineColor,
                      ),
                    ),
                ],
              ),
            ),

            // Right side
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: horizontalPadding),
                child: Column(
                  crossAxisAlignment: rightAlignment,
                  mainAxisSize: MainAxisSize.min,
                  children: [rightChild],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




