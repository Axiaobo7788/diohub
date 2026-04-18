import 'package:diohub_models/models/repositories/punch_card_entry.dart';
import 'package:flutter/material.dart';

/// Heatmap showing commit frequency by day-of-week (Y) and hour-of-day (X).
///
/// Renders a 7×24 grid where color intensity corresponds to commit count.
class PunchCardHeatmap extends StatelessWidget {
  const PunchCardHeatmap({
    required this.entries,
    this.height = 180,
    this.color,
    this.showLabels = true,
    super.key,
  });

  /// Punch card entries (168 buckets: 7 days × 24 hours).
  final List<PunchCardEntry> entries;

  final double height;

  /// Base color for the heatmap cells. Defaults to [ColorScheme.primary].
  final Color? color;

  /// Whether to show day and hour labels on axes.
  final bool showLabels;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color baseColor = color ?? colorScheme.primary;

    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, height),
          painter: _PunchCardPainter(
            entries: entries,
            baseColor: baseColor,
            labelColor: colorScheme.onSurfaceVariant,
            labelStyle: Theme.of(context).textTheme.labelSmall,
            showLabels: showLabels,
          ),
        );
      },
    );
  }
}

class _PunchCardPainter extends CustomPainter {
  _PunchCardPainter({
    required this.entries,
    required this.baseColor,
    required this.labelColor,
    required this.labelStyle,
    required this.showLabels,
  });

  final List<PunchCardEntry> entries;
  final Color baseColor;
  final Color labelColor;
  final TextStyle? labelStyle;
  final bool showLabels;

  static const List<String> _dayNames = <String>[
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  @override
  void paint(final Canvas canvas, final Size size) {
    final Map<int, Map<int, int>> grid = <int, Map<int, int>>{};
    for (int d = 0; d < 7; d++) {
      grid[d] = <int, int>{};
      for (int h = 0; h < 24; h++) {
        grid[d]![h] = 0;
      }
    }
    for (final PunchCardEntry e in entries) {
      if (e.day >= 0 && e.day < 7 && e.hour >= 0 && e.hour < 24) {
        grid[e.day]![e.hour] = (grid[e.day]![e.hour] ?? 0) + e.commits;
      }
    }

    int maxCommits = 0;
    for (final Map<int, int> row in grid.values) {
      for (final int c in row.values) {
        if (c > maxCommits) maxCommits = c;
      }
    }
    if (maxCommits == 0) maxCommits = 1;

    const double labelReserve = 32;
    final double cellWidth = (size.width - labelReserve) / 24;
    final double cellHeight =
        (size.height - (showLabels ? labelReserve : 0)) / 7;

    for (int day = 0; day < 7; day++) {
      for (int hour = 0; hour < 24; hour++) {
        final int commits = grid[day]![hour] ?? 0;
        final double opacity = commits / maxCommits;
        final double x = labelReserve + hour * cellWidth;
        final double y = day * cellHeight + (showLabels ? labelReserve : 0);
        final RRect rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 1, y + 1, cellWidth - 2, cellHeight - 2),
          const Radius.circular(2),
        );
        canvas.drawRRect(
          rect,
          Paint()
            ..color = baseColor.withOpacity(opacity * 0.9)
            ..style = PaintingStyle.fill,
        );
      }
    }

    if (showLabels && labelStyle != null) {
      final TextPainter textPainter = TextPainter(
        textDirection: TextDirection.ltr,
      );
      for (int day = 0; day < 7; day++) {
        textPainter.text = TextSpan(
          text: _dayNames[day],
          style: labelStyle!.copyWith(color: labelColor, fontSize: 10),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
              2,
              day * cellHeight +
                  (labelReserve) +
                  (cellHeight - textPainter.height) / 2),
        );
      }
      for (int hour = 0; hour < 24; hour += 3) {
        textPainter.text = TextSpan(
          text: '$hour',
          style: labelStyle!.copyWith(color: labelColor, fontSize: 9),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            labelReserve +
                hour * cellWidth +
                (cellWidth - textPainter.width) / 2,
            2,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant final _PunchCardPainter oldDelegate) =>
      oldDelegate.entries != entries ||
      oldDelegate.baseColor != baseColor ||
      oldDelegate.showLabels != showLabels;
}
