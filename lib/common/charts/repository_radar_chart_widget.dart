import 'package:diohub/view/profile/about/widgets/activity_overview_section.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// A radar chart widget that displays multiple repositories side-by-side.
///
/// Each repository is shown as a separate shape on the radar chart,
/// making it easy to compare contribution patterns across repositories.
///
/// Example usage:
/// ```dart
/// RepositoryRadarChart(
///   repositories: topRepos.take(5).toList(),
///   maxRepositories: 5,
///   height: 250,
/// )
/// ```
class RepositoryRadarChart extends StatelessWidget {
  const RepositoryRadarChart({
    required this.repositories,
    this.maxRepositories = 5,
    this.height = 200,
    this.width,
    this.showLegend = true,
    super.key,
  });

  /// List of repositories to display
  final List<ContributedRepository> repositories;

  /// Maximum number of repositories to display
  final int maxRepositories;

  /// Height of the chart
  final double height;

  /// Width of the chart (null = full width)
  final double? width;

  /// Whether to show legend with repository names
  final bool showLegend;

  /// Predefined colors for repositories (distinct colors for better visualization)
  static const List<Color> _repositoryColors = [
    Color(0xFF40C463), // GitHub green
    Color(0xFF1E88E5), // Blue
    Color(0xFFE53935), // Red
    Color(0xFFFFB300), // Amber
    Color(0xFF7B1FA2), // Purple
    Color(0xFF00ACC1), // Cyan
    Color(0xFFF4511E), // Orange
    Color(0xFF43A047), // Green
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Filter and limit repositories
    final displayRepos = repositories.take(maxRepositories).toList();

    if (displayRepos.isEmpty) {
      return SizedBox(
        height: height,
        width: width,
        child: Center(
          child: Text(
            'No repositories to display',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // Calculate max value across all repositories and contribution types
    double maxValue = 0;
    for (final repo in displayRepos) {
      final repoMax = [
        repo.commitCount ?? 0,
        repo.issueCount ?? 0,
        repo.pullRequestCount ?? 0,
        repo.reviewCount ?? 0,
      ].reduce((a, b) => a > b ? a : b);
      if (repoMax > maxValue) {
        maxValue = repoMax.toDouble();
      }
    }

    // If all values are 0, show empty state
    if (maxValue == 0) {
      return SizedBox(
        height: height,
        width: width,
        child: Center(
          child: Text(
            'No contributions yet',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // Add some padding to max value for better visualization
    maxValue = maxValue * 1.1;

    // Labels for axes
    const labels = ['Commits', 'Issues', 'Pull Requests', 'Reviews'];

    // Create datasets for each repository
    final dataSets = <RadarDataSet>[];
    for (int i = 0; i < displayRepos.length; i++) {
      final repo = displayRepos[i];
      final color = i < _repositoryColors.length
          ? _repositoryColors[i]
          : _repositoryColors[i % _repositoryColors.length];

      final dataEntries = [
        RadarEntry(value: (repo.commitCount ?? 0).toDouble()),
        RadarEntry(value: (repo.issueCount ?? 0).toDouble()),
        RadarEntry(value: (repo.pullRequestCount ?? 0).toDouble()),
        RadarEntry(value: (repo.reviewCount ?? 0).toDouble()),
      ];

      dataSets.add(
        RadarDataSet(
          dataEntries: dataEntries,
          fillColor: color.withOpacity(0.2),
          borderColor: color,
          borderWidth: 2,
          entryRadius: 3,
        ),
      );
    }

    // Create transparent dataset with max values to set chart scale
    final maxValueEntries = List.generate(
      4,
      (index) => RadarEntry(value: maxValue),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          width: width,
          child: RadarChart(
            RadarChartData(
              dataSets: [
                // Transparent dataset to set scale
                RadarDataSet(
                  dataEntries: maxValueEntries,
                  fillColor: Colors.transparent,
                  borderColor: Colors.transparent,
                  borderWidth: 1,
                ),
                // Repository datasets
                ...dataSets,
              ],
              radarBackgroundColor: Colors.transparent,
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              radarBorderData: BorderSide(
                color: colorScheme.primary.withOpacity(0.3),
                width: 1,
              ),
              titlePositionPercentageOffset: 0.2,
              getTitle: (index, angle) {
                if (index >= labels.length) {
                  return const RadarChartTitle(text: '');
                }
                return RadarChartTitle(
                  text: labels[index],
                );
              },
              titleTextStyle: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
              tickCount: 5,
              ticksTextStyle: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                fontSize: 9,
              ),
              tickBorderData: BorderSide(
                color: colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
        ),
        if (showLegend) ...[
          const SizedBox(height: 12),
          _buildLegend(context, displayRepos),
        ],
      ],
    );
  }

  Widget _buildLegend(
    BuildContext context,
    List<ContributedRepository> repos,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(
        repos.length,
        (index) {
          final repo = repos[index];
          final color = index < _repositoryColors.length
              ? _repositoryColors[index]
              : _repositoryColors[index % _repositoryColors.length];

          // Truncate repository name if too long
          final repoName = repo.name;
          final displayName = repoName.length > 15
              ? '${repoName.substring(0, 15)}...'
              : repoName;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                displayName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
