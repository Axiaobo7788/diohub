import 'package:diohub/common/misc/surface_shape_resolver.dart';
import 'package:diohub/style/surface_style_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// A reusable chip widget for displaying contribution information
///
/// Displays: Icon | Count | label (if provided)
class ContributionInfoChip extends StatelessWidget {
  const ContributionInfoChip({
    required this.icon,
    required this.count,
    this.label,
    required this.color,
    this.onTap,
    super.key,
  });

  /// Icon to display
  final IconData icon;

  /// Count value to display (formatted automatically)
  final int count;

  /// Optional label text to display after count (e.g., "private", "in 5 repos", "reviews")
  final String? label;

  /// Color for the icon and chip styling
  final Color color;

  /// Optional callback when chip is tapped
  final VoidCallback? onTap;

  /// Factory method for commits chip with optional repo count
  factory ContributionInfoChip.commits({
    required int count,
    int repoCount = 0,
    VoidCallback? onTap,
  }) {
    return ContributionInfoChip(
      icon: Octicons.git_commit,
      count: count,
      label: repoCount > 0
          ? 'in $repoCount ${repoCount == 1 ? 'repo' : 'repos'}'
          : null,
      color: const Color(0xFF2196F3),
      onTap: onTap,
    );
  }

  /// Factory method for pull requests chip with optional repo count
  factory ContributionInfoChip.pullRequests({
    required int count,
    int repoCount = 0,
    VoidCallback? onTap,
  }) {
    return ContributionInfoChip(
      icon: Octicons.git_pull_request,
      count: count,
      label: repoCount > 0
          ? 'in $repoCount ${repoCount == 1 ? 'repo' : 'repos'}'
          : null,
      color: const Color(0xFF9C27B0),
      onTap: onTap,
    );
  }

  /// Factory method for issues chip with optional repo count
  factory ContributionInfoChip.issues({
    required int count,
    int repoCount = 0,
    VoidCallback? onTap,
  }) {
    return ContributionInfoChip(
      icon: Octicons.issue_opened,
      count: count,
      label: repoCount > 0
          ? 'in $repoCount ${repoCount == 1 ? 'repo' : 'repos'}'
          : null,
      color: const Color(0xFF4CAF50),
      onTap: onTap,
    );
  }

  /// Factory method for reviews chip with optional repo count
  factory ContributionInfoChip.reviews({
    required int count,
    int repoCount = 0,
    VoidCallback? onTap,
  }) {
    return ContributionInfoChip(
      icon: Octicons.code_review,
      count: count,
      label: repoCount > 0
          ? 'reviews in $repoCount ${repoCount == 1 ? 'repo' : 'repos'}'
          : 'reviews',
      color: const Color(0xFFFF9800),
      onTap: onTap,
    );
  }

  /// Factory method for repositories created chip
  factory ContributionInfoChip.repositories({
    required int count,
    VoidCallback? onTap,
  }) {
    return ContributionInfoChip(
      icon: Octicons.repo,
      count: count,
      label: count == 1 ? 'repo created' : 'repos created',
      color: const Color(0xFF795548),
      onTap: onTap,
    );
  }

  /// Factory method for private/restricted contributions chip
  factory ContributionInfoChip.private({
    required int count,
    required ColorScheme colorScheme,
    VoidCallback? onTap,
  }) {
    return ContributionInfoChip(
      icon: Octicons.lock,
      count: count,
      label: 'private',
      color: colorScheme.tertiary,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final chipContent = Container(
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
            _formatNumber(count),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: 4),
            Text(
              label!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return chipContent;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: theme.surfaceStyle.borderRadius(size: BorderRadiusSize.large),
      child: chipContent,
    );
  }

  String _formatNumber(int number) {
    if (number < 1000) return number.toString();
    if (number < 1000000) return '${(number / 1000).toStringAsFixed(1)}k';
    return '${(number / 1000000).toStringAsFixed(1)}M';
  }
}
