import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/shimmer_bone.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

/// Reusable shimmer widget for timeline items
/// Mimics the structure of UnifiedTimelineItem with shimmer effects
/// Uses CustomPaint to draw timeline connector lines, avoiding IntrinsicHeight issues.
/// Must be used within a ShimmerScope.
class TimelineShimmerItem extends StatelessWidget {
  const TimelineShimmerItem({
    this.showAvatar = false,
    this.isFirst = false,
    this.isLast = false,
    this.actionHeaderTopPadding = 16.0,
    super.key,
  });

  /// Whether to show avatar indicator (true) or icon-only indicator (false)
  final bool showAvatar;
  final bool isFirst;
  final bool isLast;
  final double actionHeaderTopPadding;

  @override
  Widget build(final BuildContext context) {
    final double indicatorSize = showAvatar ? 30.0 : 24.0;
    final Color lineColor = context.colorScheme.outlineVariant.hinted;

    return ShimmerScope(
      child: CustomPaint(
        foregroundPainter: _TimelineShimmerPainter(
          isFirst: isFirst,
          isLast: isLast,
          indicatorSize: indicatorSize,
          lineColor: lineColor,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Timeline indicator (lines drawn by painter)
            SizedBox(
              width: indicatorSize,
              height: indicatorSize,
              child: ShimmerBone.avatar(size: indicatorSize),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 0, showAvatar ? 12 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Action header shimmer
                    Padding(
                      padding: EdgeInsets.only(
                        top: actionHeaderTopPadding,
                        bottom: 8,
                      ),
                      child: const ShimmerBone.text(width: 120),
                    ),
                    // Content card shimmer — sized to match repo/issue/PR cards in timeline
                    BorderedContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const ShimmerBone.avatar(size: 24),
                              context.spacing.itemGap,
                              const ShimmerBone.label(width: 100),
                            ],
                          ),
                          context.spacing.itemGap,
                          const ShimmerBone.title(width: 200),
                          context.spacing.itemGap,
                          const ShimmerBone.text(),
                          context.spacing.tightGap,
                          const ShimmerBone.text(width: 180),
                          context.spacing.itemGap,
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: const <Widget>[
                              ShimmerBone.chip(width: 50),
                              ShimmerBone.chip(width: 40),
                              ShimmerBone.chip(width: 45),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter that draws timeline connector lines for shimmer items.
class _TimelineShimmerPainter extends CustomPainter {
  _TimelineShimmerPainter({
    required this.isFirst,
    required this.isLast,
    required this.indicatorSize,
    required this.lineColor,
  });

  final bool isFirst;
  final bool isLast;
  final double indicatorSize;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = indicatorSize / 2;
    final double indicatorBottom = indicatorSize;
    const double lineThickness = 1.0;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = lineThickness
      ..strokeCap = StrokeCap.butt;

    // Bottom line (if not last)
    if (!isLast) {
      canvas.drawLine(
        Offset(centerX, indicatorBottom),
        Offset(centerX, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineShimmerPainter oldDelegate) =>
      isFirst != oldDelegate.isFirst ||
      isLast != oldDelegate.isLast ||
      indicatorSize != oldDelegate.indicatorSize ||
      lineColor != oldDelegate.lineColor;
}

/// Widget that displays multiple timeline shimmer items for loading state.
///
/// Default horizontal padding matches [AppSpacing.listInset] (8px) so the
/// shimmer has the same horizontal insets as the loaded content.
class TimelineShimmerList extends StatelessWidget {
  const TimelineShimmerList({
    this.itemCount = 5,
    this.showAvatar = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
    this.showUserHeaders = false,
    super.key,
  });

  final int itemCount;
  final bool showAvatar;
  final EdgeInsets padding;
  final bool showUserHeaders;

  @override
  Widget build(final BuildContext context) {
    if (showUserHeaders) {
      return _buildWithUserHeaders(context);
    }

    // Use Column to stack timeline items without SizedBox height constraint
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          itemCount,
          (final int index) => TimelineShimmerItem(
            showAvatar: showAvatar,
            isFirst: index == 0,
            isLast: index == itemCount - 1,
            actionHeaderTopPadding: index == 0 ? 16.0 : 0.0,
          ),
        ),
      ),
    );
  }

  Widget _buildWithUserHeaders(final BuildContext context) {
    // When showing user headers, group items into user groups
    // Show 3-4 user groups with varying items each
    final List<int> userGroups = <int>[
      2, // First user has 2 items
      3, // Second user has 3 items
      2, // Third user has 2 items
      1, // Fourth user has 1 item
    ];

    final List<Widget> children = <Widget>[];

    for (int groupIndex = 0; groupIndex < userGroups.length; groupIndex++) {
      final int itemsInGroup = userGroups[groupIndex];
      final bool isFirstGroup = groupIndex == 0;

      // Add user header (mimics _buildUserGroupHeader structure)
      children.add(
        Container(
          margin: EdgeInsets.only(
            top: isFirstGroup ? 0 : context.spacing.itemSpacing,
          ),
          child: Padding(
            padding: EdgeInsets.only(top: context.spacing.itemSpacing),
            child: _buildUserHeaderShimmer(context),
          ),
        ),
      );

      // Add spacing between header and first timeline item
      children.add(SizedBox(height: context.spacing.itemSpacing));

      // Add timeline items for this user group
      for (int i = 0; i < itemsInGroup; i++) {
        final bool isFirstInGroup = i == 0;
        final bool isLastInGroup = i == itemsInGroup - 1;

        children.add(
          TimelineShimmerItem(
            isFirst: isFirstInGroup,
            isLast: isLastInGroup,
            actionHeaderTopPadding: isFirstInGroup ? 0.0 : 0.0,
          ),
        );
      }
    }

    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildUserHeaderShimmer(final BuildContext context) => ShimmerScope(
        child: Row(
          children: <Widget>[
            // Avatar shimmer - fixed to be circular instead of medium radius
            const ShimmerBone.avatar(size: 24),
            context.spacing.itemGap,
            // Username shimmer
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: ShimmerBone.text(width: 100),
            ),
          ],
        ),
      );
}
