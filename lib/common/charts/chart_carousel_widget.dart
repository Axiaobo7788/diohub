import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/common/charts/contribution_calendar_widget.dart';
import 'package:diohub/common/charts/contribution_pie_chart_widget.dart';
import 'package:diohub/common/charts/monthly_bar_chart_widget.dart';
import 'package:diohub/common/charts/repository_bar_chart_widget.dart';
import 'package:diohub/common/charts/repository_radar_chart_widget.dart';
import 'package:diohub/common/charts/time_series_line_chart_widget.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub_models/models/contributions/contribution_day.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';

/// Height reserved for chart legends and page indicators below the chart.
const double _legendAreaHeight = 120;

/// A carousel widget that allows swiping between different contribution charts.
///
/// Displays multiple chart views in a swipeable PageView with page indicators.
class ChartCarousel extends StatefulWidget {
  const ChartCarousel({
    required this.repositories,
    required this.commits,
    required this.issues,
    required this.pullRequests,
    required this.weeks,
    this.reviews,
    this.height = 200,
    super.key,
  });

  /// List of repositories user contributed to
  final List<ContributedRepository> repositories;

  /// Number of commits
  final int commits;

  /// Number of issues
  final int issues;

  /// Number of pull requests
  final int pullRequests;

  /// List of weeks containing daily contribution data
  final List<List<ContributionDay>> weeks;

  /// Optional number of reviews
  final int? reviews;

  /// Height of the chart
  final double height;

  @override
  State<ChartCarousel> createState() => _ChartCarouselState();
}

class _ChartCarouselState extends State<ChartCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    final int page = _pageController.page?.round() ?? 0;
    if (page != _currentPage) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final AppSpacing spacing = context.spacing;

    // Use theme colors instead of hardcoded values
    final Color chartColor = colorScheme.primary;
    final double chartHeight = widget.height;

    // Determine which charts to show
    final List<_ChartItem> charts = <_ChartItem>[];

    // Show repository radar chart if there are repositories
    if (widget.repositories.isNotEmpty) {
      charts.add(
        _ChartItem(
          title: 'Top Repositories',
          chart: RepositoryRadarChart(
            repositories: widget.repositories,
            height: chartHeight,
          ),
        ),
      );
    }

    // Show pie chart for contribution type distribution
    if (widget.commits +
            widget.issues +
            widget.pullRequests +
            (widget.reviews ?? 0) >
        0) {
      charts.add(
        _ChartItem(
          title: 'Distribution',
          chart: ContributionPieChart(
            commits: widget.commits,
            issues: widget.issues,
            pullRequests: widget.pullRequests,
            reviews: widget.reviews,
            height: chartHeight,
          ),
        ),
      );
    }

    // Show monthly bar chart if we have weeks data
    if (widget.weeks.isNotEmpty) {
      charts.add(
        _ChartItem(
          title: 'Monthly',
          chart: MonthlyBarChart(
            weeks: widget.weeks,
            height: chartHeight,
            color: chartColor,
          ),
        ),
      );
    }

    // Show time series line chart if we have weeks data
    if (widget.weeks.isNotEmpty) {
      charts.add(
        _ChartItem(
          title: 'Trends',
          chart: TimeSeriesLineChart(
            weeks: widget.weeks,
            height: chartHeight,
            color: chartColor,
          ),
        ),
      );
    }

    // Show repository bar chart if there are repositories
    if (widget.repositories.isNotEmpty) {
      charts.add(
        _ChartItem(
          title: 'Repositories',
          chart: RepositoryBarChart(
            repositories: widget.repositories,
            maxRepositories: 8,
            height: chartHeight,
            color: chartColor,
          ),
        ),
      );
    }

    // If no charts, show empty state
    if (charts.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'No contribution data available',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // If only one chart, don't show carousel
    if (charts.length <= 1) {
      return charts.first.chart;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Use SizedBox with flexible height to accommodate charts with legends
        SizedBox(
          height: widget.height + _legendAreaHeight,
          child: PageView.builder(
            controller: _pageController,
            clipBehavior: Clip.none, // Prevent clipping of overflow content
            itemCount: charts.length,
            itemBuilder: (final BuildContext context, final int index) {
              final _ChartItem chartItem = charts[index];
              return OverflowBox(
                maxHeight: widget.height + _legendAreaHeight,
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.all(spacing.itemSpacing),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Chart title
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: spacing.compactSpacing * 2,
                        ),
                        child: Text(
                          chartItem.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      // Chart content
                      Flexible(child: chartItem.chart),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: spacing.itemSpacing),
        _buildPageIndicator(context, charts.length),
      ],
    );
  }

  Widget _buildPageIndicator(final BuildContext context, final int pageCount) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppSpacing spacing = context.spacing;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (final int index) {
        final bool isActive = index == _currentPage;
        return GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: kStateDuration,
              curve: kStateCurve,
            );
          },
          child: Container(
            width: isActive ? 24 : 8,
            height: 8,
            margin: EdgeInsets.symmetric(horizontal: spacing.tightSpacing),
            decoration: BoxDecoration(
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.outline.borderO,
              borderRadius: context.radius(RadiusSize.soft),
            ),
          ),
        );
      }),
    );
  }
}

/// Internal class to hold chart data
class _ChartItem {
  const _ChartItem({required this.title, required this.chart});

  final String title;
  final Widget chart;
}
