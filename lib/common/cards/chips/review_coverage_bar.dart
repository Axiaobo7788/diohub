import 'package:diohub/common/animations/animated_gradient_bar.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/diff_colors.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/indicator_utils.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mini stacked bar showing PR review composition: approved / changes requested / pending.
///
/// Labels "✓2 ✗1 ○1" and a proportional color bar. Wrapped in [AnimatedGradientBar]
/// for entrance. Returns [SizedBox.shrink] when [summary.isEmpty].
class ReviewCoverageBar extends ConsumerWidget {
  const ReviewCoverageBar({
    required this.summary,
    super.key,
  });

  final ReviewCoverageSummary summary;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    if (summary.isEmpty) {
      return const SizedBox.shrink();
    }
    final AppSpacing spacing = context.spacing;
    final ColorScheme cs = context.colorScheme;
    final TextStyle labelStyle = Theme.of(context)
        .textTheme
        .labelSmall!
        .copyWith(fontWeight: FontWeight.w500);
    final BorderRadius borderRadius = context.radius(RadiusSize.small);

    final double approvedFrac =
        summary.total > 0 ? summary.approved / summary.total : 0;
    final double changesFrac =
        summary.total > 0 ? summary.changesRequested / summary.total : 0;
    final double pendingFrac =
        summary.total > 0 ? summary.pending / summary.total : 0;

    return Container(
      padding: spacing.chipPadding,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: cs.onSurfaceVariant.withValues(alpha: 0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '✓${summary.approved}',
            style: labelStyle.copyWith(color: DiffColors.addition),
          ),
          spacing.tightGap,
          Text(
            '✗${summary.changesRequested}',
            style: labelStyle.copyWith(color: DiffColors.deletion),
          ),
          spacing.tightGap,
          Text(
            '○${summary.pending}',
            style: labelStyle.copyWith(color: cs.onSurfaceVariant),
          ),
          spacing.tightGap,
          Expanded(
            child: AnimatedGradientBar(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: <Color>[
                      DiffColors.addition,
                      DiffColors.addition,
                      DiffColors.deletion,
                      DiffColors.deletion,
                      cs.onSurfaceVariant.withValues(alpha: 0.5),
                      cs.onSurfaceVariant.withValues(alpha: 0.5),
                    ],
                    stops: <double>[
                      0,
                      approvedFrac,
                      approvedFrac,
                      approvedFrac + changesFrac,
                      approvedFrac + changesFrac,
                      1,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
