import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/contribution_colors.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// A `Wrap` of contribution-count chips rendered below a repo card.
///
/// Each non-null, non-zero count renders a tinted chip with an icon and label.
/// Returns [SizedBox.shrink] when all counts are null or zero.
class ContributionBreakdownRow extends StatelessWidget {
  const ContributionBreakdownRow({
    this.commits,
    this.reviews,
    this.issues,
    this.pullRequests,
    super.key,
  });

  final int? commits;
  final int? reviews;
  final int? issues;
  final int? pullRequests;

  @override
  Widget build(final BuildContext context) {
    final List<Widget> chips = <Widget>[
      if ((commits ?? 0) > 0)
        _CountChip(
          color: ContributionColors.commit,
          icon: Octicons.git_commit,
          label: '$commits ${commits == 1 ? 'commit' : 'commits'}',
        ),
      if ((reviews ?? 0) > 0)
        _CountChip(
          color: ContributionColors.review,
          icon: Octicons.code_review,
          label: '$reviews ${reviews == 1 ? 'review' : 'reviews'}',
        ),
      if ((issues ?? 0) > 0)
        _CountChip(
          color: ContributionColors.issue,
          icon: Octicons.issue_opened,
          label: '$issues ${issues == 1 ? 'issue' : 'issues'}',
        ),
      if ((pullRequests ?? 0) > 0)
        _CountChip(
          color: ContributionColors.pullRequest,
          icon: Octicons.git_pull_request,
          label: '$pullRequests ${pullRequests == 1 ? 'PR' : 'PRs'}',
        ),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();

    final AppSpacing spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.only(top: spacing.itemSpacing),
      child: Wrap(
        spacing: spacing.tightSpacing,
        runSpacing: spacing.tightSpacing,
        children: chips,
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(final BuildContext context) => Container(
        padding: context.spacing.chipPadding,
        decoration: BoxDecoration(
          color: color.tintMedium,
          borderRadius: context.radius(RadiusSize.medium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 12, color: color),
            context.spacing.tightGap,
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.onSurfaceVariant.strong,
                  ),
            ),
          ],
        ),
      );
}
