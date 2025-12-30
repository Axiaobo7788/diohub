import 'package:diohub/common/charts/contribution_calendar_widget.dart';
import 'package:diohub/common/charts/contribution_pie_chart_widget.dart';
import 'package:diohub/common/charts/monthly_bar_chart_widget.dart';
import 'package:diohub/common/charts/repository_bar_chart_widget.dart';
import 'package:diohub/common/charts/repository_radar_chart_widget.dart';
import 'package:diohub/common/charts/time_series_line_chart_widget.dart';
import 'package:diohub/view/profile/about/widgets/activity_overview_section.dart';
import 'package:flutter/material.dart';

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
    final page = _pageController.page?.round() ?? 0;
    if (page != _currentPage) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use theme colors instead of hardcoded values
    final chartColor = colorScheme.primary;
    final chartHeight = widget.height;

    // Determine which charts to show
    final charts = <_ChartItem>[];

    // Show repository radar chart if there are repositories
    if (widget.repositories.isNotEmpty) {
      charts.add(
        _ChartItem(
          title: 'Top Repositories',
          chart: RepositoryRadarChart(
            repositories: widget.repositories,
            maxRepositories: 5,
            height: chartHeight,
            showLegend: true,
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
            groupBy: TimeGrouping.daily,
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
      children: [
        // Use SizedBox with flexible height to accommodate charts with legends
        SizedBox(
          height: widget.height + 120, // Extra space for legends/indicators
          child: PageView.builder(
            controller: _pageController,
            clipBehavior: Clip.none, // Prevent clipping of overflow content
            itemCount: charts.length,
            itemBuilder: (context, index) {
              final chartItem = charts[index];
              return OverflowBox(
                maxHeight: widget.height + 120,
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chart title
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          chartItem.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      // Chart content
                      Flexible(
                        child: chartItem.chart,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        _buildPageIndicator(context, charts.length),
      ],
    );
  }

  Widget _buildPageIndicator(BuildContext context, int pageCount) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
        (index) {
          final isActive = index == _currentPage;
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              width: isActive ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Internal class to hold chart data
class _ChartItem {
  const _ChartItem({
    required this.title,
    required this.chart,
  });

  final String title;
  final Widget chart;
}
