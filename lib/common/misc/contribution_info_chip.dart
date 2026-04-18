import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/contribution_colors.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// A reusable chip widget for displaying contribution information
///
/// Displays: Icon | Count | label (if provided)
class ContributionInfoChip extends StatelessWidget {
  const ContributionInfoChip({
    required this.icon,
    required this.count,
    required this.color,
    this.label,
    this.onTap,
    super.key,
  });

  /// Factory method for commits chip with optional repo count
  factory ContributionInfoChip.commits({
    required final int count,
    final int repoCount = 0,
    final VoidCallback? onTap,
  }) =>
      ContributionInfoChip(
        icon: Octicons.git_commit,
        count: count,
        label: repoCount > 0
            ? 'in $repoCount ${repoCount == 1 ? 'repo' : 'repos'}'
            : null,
        color: ContributionColors.commit,
        onTap: onTap,
      );

  /// Factory method for pull requests chip with optional repo count
  factory ContributionInfoChip.pullRequests({
    required final int count,
    final int repoCount = 0,
    final VoidCallback? onTap,
  }) =>
      ContributionInfoChip(
        icon: Octicons.git_pull_request,
        count: count,
        label: repoCount > 0
            ? 'in $repoCount ${repoCount == 1 ? 'repo' : 'repos'}'
            : null,
        color: ContributionColors.pullRequest,
        onTap: onTap,
      );

  /// Factory method for issues chip with optional repo count
  factory ContributionInfoChip.issues({
    required final int count,
    final int repoCount = 0,
    final VoidCallback? onTap,
  }) =>
      ContributionInfoChip(
        icon: Octicons.issue_opened,
        count: count,
        label: repoCount > 0
            ? 'in $repoCount ${repoCount == 1 ? 'repo' : 'repos'}'
            : null,
        color: ContributionColors.issue,
        onTap: onTap,
      );

  /// Factory method for reviews chip with optional repo count
  factory ContributionInfoChip.reviews({
    required final int count,
    final int repoCount = 0,
    final VoidCallback? onTap,
  }) =>
      ContributionInfoChip(
        icon: Octicons.code_review,
        count: count,
        label: repoCount > 0
            ? 'reviews in $repoCount ${repoCount == 1 ? 'repo' : 'repos'}'
            : 'reviews',
        color: ContributionColors.review,
        onTap: onTap,
      );

  /// Factory method for repositories created chip
  factory ContributionInfoChip.repositories({
    required final int count,
    final VoidCallback? onTap,
  }) =>
      ContributionInfoChip(
        icon: Octicons.repo,
        count: count,
        label: count == 1 ? 'repo created' : 'repos created',
        color: ContributionColors.repo,
        onTap: onTap,
      );

  /// Factory method for private/restricted contributions chip
  factory ContributionInfoChip.private({
    required final int count,
    required final ColorScheme colorScheme,
    final VoidCallback? onTap,
  }) =>
      ContributionInfoChip(
        icon: Octicons.lock,
        count: count,
        label: 'private',
        color: colorScheme.tertiary,
        onTap: onTap,
      );

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

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final AppSpacing spacing = context.spacing;

    final Container chipContent = Container(
      padding: spacing.chipPadding,
      decoration: context.surfaceDecoration(
        RadiusSize.large,
        color: color.subtle,
        border: Border.all(
          color: color.borderO,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          spacing.compactGap,
          Text(
            _formatNumber(count),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (label != null) ...<Widget>[
            spacing.tightGap,
            Text(
              label!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.secondary,
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

    return TapFeedback(
      onTap: onTap,
      size: RadiusSize.large,
      child: chipContent,
    );
  }

  String _formatNumber(final int number) {
    if (number < 1000) return number.toString();
    if (number < 1000000) return '${(number / 1000).toStringAsFixed(1)}k';
    return '${(number / 1000000).toStringAsFixed(1)}M';
  }
}
