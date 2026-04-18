import 'package:contribution_heatmap/contribution_heatmap.dart';
import 'package:diohub/common/animations/chart_entrance.dart';
import 'package:diohub_models/models/contributions/contribution_day.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/contribution_colors.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub_models/models/contributions/contribution_day.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A reusable contribution calendar widget (GitHub-style heatmap).
///
/// This widget wraps the contribution_heatmap library for high-performance rendering.
/// It maintains the same API as before but uses an optimized library implementation.
///
/// Example usage:
/// ```dart
/// ContributionCalendarWidget(
///   weeks: contributionWeeks,
///   onDayTap: (day) => showDayDetails(day),
/// )
/// ```
class ContributionCalendarWidget extends ConsumerStatefulWidget {
  const ContributionCalendarWidget({
    required this.weeks,
    this.colors,
    this.onDayTap,
    this.onDayLongPress,
    this.showMonthLabels = true,
    this.showDayLabels = true,
    this.cellSize = 25.0,
    this.cellSpacing = 2.0,
    this.monthLabelHeight = 20.0,
    this.dayLabelWidth = 20.0,
    this.legendColors,
    this.showLegend = true,
    this.legendLabels = const <String>['Less', 'More'],
    this.shouldScroll = false,
    super.key,
  });

  /// List of weeks, each containing days
  /// Each week should have 7 days (Mon-Sun)
  final List<List<ContributionDay>> weeks;

  /// Color scheme for contribution levels (ignored - using library's green scheme)
  /// Kept for API compatibility
  final List<Color>? colors;

  /// Callback when a day is tapped
  final void Function(ContributionDay day)? onDayTap;

  /// Callback when a day is long-pressed (not supported by library, ignored)
  final void Function(ContributionDay day)? onDayLongPress;

  /// Whether to show month labels above the calendar
  final bool showMonthLabels;

  /// Whether to show day labels (Mon, Tue, etc.) on the left
  final bool showDayLabels;

  /// Size of each calendar cell in pixels
  final double cellSize;

  /// Spacing between cells in pixels
  final double cellSpacing;

  /// Height reserved for month labels (ignored - library handles this)
  final double monthLabelHeight;

  /// Width reserved for day labels (ignored - library handles this)
  final double dayLabelWidth;

  /// Colors for the legend (ignored - using library's colors)
  final List<Color>? legendColors;

  /// Whether to show the legend (not supported by library, ignored)
  final bool showLegend;

  /// Labels for the legend (not supported by library, ignored)
  final List<String> legendLabels;

  /// Whether the calendar should be horizontally scrollable
  /// Set to true for multi-year ranges (>1 year)
  final bool shouldScroll;

  @override
  ConsumerState<ContributionCalendarWidget> createState() =>
      _ContributionCalendarWidgetState();
}

class _ContributionCalendarWidgetState
    extends ConsumerState<ContributionCalendarWidget> {
  // Cached conversion results - only recalculate when weeks change
  List<ContributionEntry>? _cachedEntries;
  DateTime? _cachedMinDate;
  DateTime? _cachedMaxDate;
  Map<String, ContributionDay>? _cachedDayMap; // For O(1) lookup in onCellTap
  List<List<ContributionDay>>? _cachedWeeks;
  double? _cachedCalendarWidth;

  void _updateCacheIfNeeded() {
    // Only recalculate if weeks have changed
    if (_cachedWeeks == widget.weeks && _cachedEntries != null) {
      return;
    }

    // Convert weeks format to entries format for the library
    final List<ContributionEntry> entries = <ContributionEntry>[];
    final Map<String, ContributionDay> dayMap = <String, ContributionDay>{};
    DateTime? minDate;
    DateTime? maxDate;

    for (final List<ContributionDay> week in widget.weeks) {
      for (final ContributionDay day in week) {
        entries.add(ContributionEntry(day.date, day.count));

        // Create a key for O(1) lookup: "YYYY-MM-DD"
        final String dateKey =
            '${day.date.year}-${day.date.month}-${day.date.day}';
        dayMap[dateKey] = day;

        if (minDate == null || day.date.isBefore(minDate)) {
          minDate = day.date;
        }
        if (maxDate == null || day.date.isAfter(maxDate)) {
          maxDate = day.date;
        }
      }
    }

    _cachedEntries = entries;
    _cachedMinDate = minDate;
    _cachedMaxDate = maxDate;
    _cachedDayMap = dayMap;
    _cachedWeeks = widget.weeks;
    _cachedCalendarWidth =
        widget.weeks.length * (widget.cellSize + widget.cellSpacing);
  }

  @override
  Widget build(final BuildContext context) {
    // Update cache if needed (only recalculates when weeks change)
    _updateCacheIfNeeded();

    // Build the heatmap widget with high-contrast color scheme
    // Using HeatmapColor.blue for better contrast differences
    final ContributionHeatmap heatmap = ContributionHeatmap(
      entries: _cachedEntries!,
      minDate: _cachedMinDate,
      maxDate: _cachedMaxDate,
      cellSize: widget.cellSize,
      cellSpacing: widget.cellSpacing,
      // splittedMonthView: true,
      showCellDate: true,
      showMonthLabels: widget.showMonthLabels,
      weekdayLabel: WeekdayLabel.none,

      heatmapColor: HeatmapColor.blue, // Higher contrast than green
      onCellTap: widget.onDayTap != null
          ? (final DateTime date, final int value) {
              // O(1) lookup using cached map
              final String dateKey = '${date.year}-${date.month}-${date.day}';
              final ContributionDay? day = _cachedDayMap![dateKey];
              if (day != null) {
                widget.onDayTap!(day);
              }
            }
          : null,
    );

    // Use cached calendar width
    final double calendarWidth = _cachedCalendarWidth!;

    // Wrap heatmap in scrollable container if needed
    // Use LayoutBuilder to handle overflow on small screens
    final LayoutBuilder heatmapWidget = LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        // If shouldScroll is true, always make it scrollable
        if (widget.shouldScroll) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: heatmap,
          );
        }

        // If calendar is wider than available space, make it scrollable
        if (calendarWidth > constraints.maxWidth) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: heatmap,
          );
        }

        // Fits on screen - use ConstrainedBox to ensure it respects max width
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth),
          child: heatmap,
        );
      },
    );

    // Build legend if enabled
    if (widget.showLegend) {
      final AppSpacing spacing = context.spacing;
      return ChartEntrance(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            heatmapWidget,
            Padding(
              padding: EdgeInsets.only(top: spacing.itemSpacing),
              child: _buildLegend(context),
            ),
          ],
        ),
      );
    }

    return ChartEntrance(child: heatmapWidget);
  }

  // Cached legend widget - only rebuilds when cellSize or legendLabels change
  Widget? _cachedLegend;
  double? _cachedLegendCellSize;
  List<String>? _cachedLegendLabels;

  /// Build the legend showing color gradient with "Less" and "More" labels
  Widget _buildLegend(final BuildContext context) {
    // Cache legend widget - only rebuild when cellSize or legendLabels change
    if (_cachedLegend == null ||
        _cachedLegendCellSize != widget.cellSize ||
        _cachedLegendLabels != widget.legendLabels) {
      final ThemeData theme = Theme.of(context);
      final AppSpacing spacing = context.spacing;
      final TextStyle? textStyle = theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontSize: 10,
      );

      // Legend gradient aligned with contribution primary (commit blue).
      // HeatmapColor.blue is used for the grid; legend uses a similar blue scale.
      final Color baseBlue = ContributionColors.commit;
      final List<Color> legendColors = <Color>[
        baseBlue.withOpacity(0.12),
        baseBlue.withOpacity(0.35),
        baseBlue.withOpacity(0.58),
        baseBlue.withOpacity(0.82),
        baseBlue,
      ];

      // Pre-build color containers list
      final List<Container> colorContainers = legendColors
          .map(
            (final Color color) => Container(
              width: widget.cellSize,
              height: widget.cellSize,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: context.radius(RadiusSize.soft),
              ),
            ),
          )
          .toList();

      _cachedLegend = Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (widget.legendLabels.isNotEmpty)
            Text(widget.legendLabels.first, style: textStyle),
          spacing.tightGap,
          ...colorContainers,
          if (widget.legendLabels.length > 1) ...<Widget>[
            spacing.tightGap,
            Text(widget.legendLabels.last, style: textStyle),
          ],
        ],
      );
      _cachedLegendCellSize = widget.cellSize;
      _cachedLegendLabels = widget.legendLabels;
    }

    return _cachedLegend!;
  }
}
