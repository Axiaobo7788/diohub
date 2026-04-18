import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

/// Tiny 4-bar mini sparkline for last 4 weeks of contribution activity.
///
/// [weeklyContributions] should have length 4 (weekly totals). Returns
/// [SizedBox.shrink] if empty or all zeros. Max bar height 16px, bar width 4px, gap 2px.
class UserActivityIndicator extends StatelessWidget {
  const UserActivityIndicator({
    required this.weeklyContributions,
    super.key,
  });

  final List<int> weeklyContributions;

  static const double barWidth = 4;
  static const double gap = 2;
  static const double maxHeight = 16;

  @override
  Widget build(final BuildContext context) {
    if (weeklyContributions.isEmpty || weeklyContributions.length != 4) {
      return const SizedBox.shrink();
    }
    final int maxVal = weeklyContributions.fold<int>(
      1,
      (final int a, final int b) => a > b ? a : b,
    );
    if (maxVal <= 0) {
      return const SizedBox.shrink();
    }
    final ColorScheme cs = context.colorScheme;
    final Color barColor = cs.primary.withValues(alpha: 0.7);

    return SizedBox(
      height: maxHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          for (int i = 0; i < 4; i++) ...<Widget>[
            if (i > 0) SizedBox(width: gap),
            Container(
              width: barWidth,
              height: maxVal > 0
                  ? (weeklyContributions[i] / maxVal * maxHeight)
                      .clamp(2.0, maxHeight)
                  : 2,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
