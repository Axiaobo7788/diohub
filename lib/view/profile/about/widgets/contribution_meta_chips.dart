import 'package:diohub/common/misc/surface_shape_resolver.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/style/surface_style_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Displays metadata chips: private/restricted badge and repository counts
class ContributionMetaChips extends StatelessWidget {
  const ContributionMetaChips({
    required this.contributionResult,
    super.key,
  });

  final ContributionCollectionResult contributionResult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRestrictedContributions =
        contributionResult.hasAnyRestrictedContributions;

    // Aggregate repo counts across all years
    int totalReposWithCommits = 0;
    int totalReposWithIssues = 0;
    int totalReposWithPRs = 0;

    for (final highlight in contributionResult.yearlyHighlights) {
      totalReposWithCommits +=
          highlight.totalRepositoriesWithContributedCommits;
      totalReposWithIssues += highlight.totalRepositoriesWithContributedIssues;
      totalReposWithPRs +=
          highlight.totalRepositoriesWithContributedPullRequests;
    }

    // Only show if there's something to display
    if (!hasRestrictedContributions &&
        totalReposWithCommits == 0 &&
        totalReposWithIssues == 0 &&
        totalReposWithPRs == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: theme.surfaceStyle.borderRadiusMedium(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Private/restricted badge
              if (hasRestrictedContributions)
                _buildChip(
                  context,
                  icon: Octicons.lock,
                  label:
                      'Includes ${contributionResult.totalRestrictedContributions} private/restricted ${contributionResult.totalRestrictedContributions == 1 ? 'contribution' : 'contributions'}',
                  color: theme.colorScheme.tertiary,
                ),

              // Repo count chips
              if (totalReposWithCommits > 0)
                _buildChip(
                  context,
                  icon: Octicons.repo,
                  label:
                      '$totalReposWithCommits ${totalReposWithCommits == 1 ? 'repo' : 'repos'} with commits',
                  color: const Color(0xFF2196F3),
                ),

              if (totalReposWithIssues > 0)
                _buildChip(
                  context,
                  icon: Octicons.issue_opened,
                  label:
                      '$totalReposWithIssues ${totalReposWithIssues == 1 ? 'repo' : 'repos'} with issues',
                  color: const Color(0xFF4CAF50),
                ),

              if (totalReposWithPRs > 0)
                _buildChip(
                  context,
                  icon: Octicons.git_pull_request,
                  label:
                      '$totalReposWithPRs ${totalReposWithPRs == 1 ? 'repo' : 'repos'} with PRs',
                  color: const Color(0xFF9C27B0),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: SurfaceShapeResolver.boxDecoration(
        context,
        size: BorderRadiusSize.large,
        color: color.withOpacity(0.1),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
