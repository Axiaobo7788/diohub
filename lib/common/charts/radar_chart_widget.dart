import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// A reusable radar (spider) chart widget for visualizing multivariate data.
///
/// This widget can be used to display:
/// - Contribution distribution (commits, PRs, issues)
/// - Skill assessments
/// - Performance metrics
/// - Any multi-dimensional data
///
/// Example usage:
/// ```dart
/// RadarChartWidget(
///   data: [58, 17, 25],
///   labels: ['Commits', 'Issues', 'Pull Requests'],
///   maxValue: 100,
///   fillColor: Colors.blue.withOpacity(0.3),
///   strokeColor: Colors.blue,
/// )
/// ```
class RadarChartWidget extends StatelessWidget {
  const RadarChartWidget({
    required this.data,
    required this.labels,
    this.maxValue,
    this.fillColor,
    this.strokeColor,
    this.pointColor,
    this.labelStyle,
    this.showLabels = true,
    this.showGrid = true,
    this.gridColor,
    this.gridStrokeWidth = 1.0,
    this.strokeWidth = 2.0,
    this.pointRadius = 4.0,
    this.height = 200,
    this.width,
    super.key,
  }) : assert(
          data.length == labels.length,
          'Data and labels must have the same length',
        );

  /// The data values to display (one per axis)
  final List<double> data;

  /// The labels for each axis
  final List<String> labels;

  /// Maximum value for the chart (defaults to max of data or 100)
  final double? maxValue;

  /// Color for the filled area
  final Color? fillColor;

  /// Color for the stroke/border
  final Color? strokeColor;

  /// Color for the data points
  final Color? pointColor;

  /// Style for axis labels
  final TextStyle? labelStyle;

  /// Whether to show axis labels
  final bool showLabels;

  /// Whether to show grid lines
  final bool showGrid;

  /// Color for grid lines
  final Color? gridColor;

  /// Width of grid lines
  final double gridStrokeWidth;

  /// Width of the data stroke
  final double strokeWidth;

  /// Radius of data points
  final double pointRadius;

  /// Height of the chart
  final double height;

  /// Width of the chart (null = full width)
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate max value - use provided maxValue or default to 100
    final calculatedMax = maxValue ?? 100.0;

    // Default colors from theme
    final defaultFillColor = fillColor ?? colorScheme.primary.withOpacity(0.3);
    final defaultStrokeColor = strokeColor ?? colorScheme.primary;
    final defaultGridColor = gridColor ?? colorScheme.outline.withOpacity(0.2);
    final defaultLabelStyle = labelStyle ??
        theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        );

    // Create data entries - normalize to 0-100 scale
    final dataEntries = data
        .map((value) => RadarEntry(value: value.clamp(0.0, calculatedMax)))
        .toList();

    // Create transparent dataset with max values to set the chart scale
    // This ensures the chart always scales to calculatedMax (100) even if actual data is lower
    final maxValueEntries = List.generate(
      dataEntries.length,
      (index) => RadarEntry(value: calculatedMax),
    );

    return SizedBox(
      height: height,
      width: width,
      child: RadarChart(
        RadarChartData(
          dataSets: [
            // Transparent dataset with max values to set the scale (invisible but affects max)
            RadarDataSet(
              dataEntries: [
                RadarEntry(value: 125),
                RadarEntry(value: 125),
                RadarEntry(value: 125),
                RadarEntry(value: 125),
              ],
              fillColor: Colors.transparent,
              borderColor: Colors.transparent,
              borderWidth: 1,
              // entryRadius: 3,
            ),
            // Actual data dataset
            RadarDataSet(
              dataEntries: dataEntries,
              fillColor: defaultFillColor,
              borderColor: defaultStrokeColor,
              borderWidth: strokeWidth,
              entryRadius: pointRadius,
            ),
          ],
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(
            show: showGrid,
            border: Border.all(
              color: defaultGridColor,
              width: gridStrokeWidth,
            ),
          ),
          radarBorderData: BorderSide(
            color: defaultStrokeColor.withOpacity(0.3),
            width: gridStrokeWidth,
          ),
          titlePositionPercentageOffset: 0.2,
          getTitle: (index, angle) {
            if (!showLabels || index >= labels.length) {
              return RadarChartTitle(text: '');
            }
            return RadarChartTitle(
              text: labels[index],
              // angle: angle,
              // positionPercentageOffset: -0.3,
            );
          },

          titleTextStyle: defaultLabelStyle,
          tickCount: 5,

          ticksTextStyle: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withOpacity(0.6),
            fontSize: 10,
          ),
          // radarTouchData: RadarTouchData(enabled: false),
          tickBorderData: BorderSide(
            color: defaultGridColor,
            width: gridStrokeWidth,
          ),
        ),
      ),
    );
  }
}

/// A radar chart widget specifically for contribution distribution.
///
/// This is a convenience wrapper around [RadarChartWidget] with
/// contribution-specific defaults and percentage formatting.
class ContributionRadarChart extends StatelessWidget {
  const ContributionRadarChart({
    required this.commits,
    required this.issues,
    required this.pullRequests,
    this.reviews,
    this.height = 200,
    this.width,
    this.color,
    super.key,
  });

  /// Number of commits
  final int commits;

  /// Number of issues
  final int issues;

  /// Number of pull requests
  final int pullRequests;

  /// Optional number of reviews
  final int? reviews;

  /// Height of the chart
  final double height;

  /// Width of the chart
  final double? width;

  /// Primary color for the chart
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final total = commits + issues + pullRequests + (reviews ?? 0);

    if (total == 0) {
      return SizedBox(
        height: height,
        width: width,
        child: Center(
          child: Text(
            'No contributions yet',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    // Calculate percentages
    final commitsPercent = (commits / total * 100);
    final issuesPercent = (issues / total * 100);
    final prsPercent = (pullRequests / total * 100);
    final reviewsPercent = reviews != null ? (reviews! / total * 100) : null;

    final data = reviewsPercent != null
        ? [commitsPercent, issuesPercent, prsPercent, reviewsPercent]
        : [commitsPercent, issuesPercent, prsPercent];

    final labels = reviewsPercent != null
        ? ['Commits', 'Issues', 'Pull Requests', 'Reviews']
        : ['Commits', 'Issues', 'Pull Requests'];

    return RadarChartWidget(
      data: data,
      labels: labels,
      maxValue: 100,
      fillColor: color?.withOpacity(0.3),
      strokeColor: color,
      pointColor: color,
      height: height,
      width: width,
    );
  }
}
