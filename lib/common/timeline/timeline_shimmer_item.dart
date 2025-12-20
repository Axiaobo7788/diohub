import 'package:diohub/common/misc/shimmer_widget.dart';
import 'package:diohub/common/timeline/timeline_container.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

/// Reusable shimmer widget for timeline items
/// Mimics the structure of UnifiedTimelineItem with shimmer effects
/// Uses a simple Row layout instead of TimelineTile to avoid LayoutBuilder issues
class TimelineShimmerItem extends StatelessWidget {
  const TimelineShimmerItem({
    this.showAvatar = false,
    this.isFirst = false,
    this.isLast = false,
    super.key,
  });

  /// Whether to show avatar indicator (true) or icon-only indicator (false)
  final bool showAvatar;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final indicatorSize = 30.0;
    final lineColor = context.colorScheme.outlineVariant.withOpacity(0.5);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator and line
        SizedBox(
          width: indicatorSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Vertical line
              if (!isFirst || !isLast)
                Positioned(
                  left: indicatorSize / 2 - 0.5,
                  top: isFirst ? indicatorSize / 2 : 0,
                  bottom: isLast ? indicatorSize / 2 : 0,
                  child: Container(
                    width: 1,
                    color: lineColor,
                  ),
                ),
              // Indicator
              SizedBox(
                height: indicatorSize,
                width: indicatorSize,
                child: showAvatar
                    ? _buildAvatarShimmer(context, indicatorSize)
                    : _buildIconShimmer(context),
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 0, showAvatar ? 12 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Action header shimmer
                Padding(
                  padding: EdgeInsets.only(
                    top: showAvatar ? 8 : 16,
                    bottom: 8,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildActionTextShimmer(context, showAvatar),
                      ),
                      const SizedBox(width: 8),
                      ShimmerWidget.container(
                        height: 12,
                        width: 50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                // Content card shimmer
                _buildContentShimmer(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarShimmer(BuildContext context, double size) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Avatar shimmer
        ShimmerWidget.container(
          height: size,
          width: size,
          borderRadius: BorderRadius.circular(size / 2),
        ),
        // Badge shimmer
        Positioned(
          right: -5,
          bottom: -8,
          child: ShimmerWidget.container(
            height: size * 2 / 3,
            width: size * 2 / 3,
            borderRadius: BorderRadius.circular(size / 3),
          ),
        ),
      ],
    );
  }

  Widget _buildIconShimmer(BuildContext context) {
    return ShimmerWidget.container(
      height: 30,
      width: 30,
      borderRadius: BorderRadius.circular(15),
    );
  }

  Widget _buildActionTextShimmer(BuildContext context, bool includeUsername) {
    if (includeUsername) {
      // Events format: "username actionText"
      return Row(
        children: [
          ShimmerWidget.container(
            height: 14,
            width: 80,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(width: 4),
          ShimmerWidget.container(
            height: 14,
            width: 60,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    } else {
      // Activity format: just action text
      return ShimmerWidget.container(
        height: 14,
        width: 100,
        borderRadius: BorderRadius.circular(4),
      );
    }
  }

  Widget _buildContentShimmer(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main content card shimmer
        ShimmerWidget.container(
          height: 80,
          borderRadius: BorderRadius.circular(8),
          highlightColor: context.colorScheme.surfaceVariant.withOpacity(0.5),
        ),
      ],
    );
  }
}

/// Widget that displays multiple timeline shimmer items for loading state
class TimelineShimmerList extends StatelessWidget {
  const TimelineShimmerList({
    this.itemCount = 5,
    this.showAvatar = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    super.key,
  });

  final int itemCount;
  final bool showAvatar;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    // Calculate approximate height needed for shimmer items
    // Each item is roughly 120-140px tall
    const double itemHeight = 130.0;
    const double itemSpacing = 12.0;
    final double totalHeight = (itemCount * itemHeight) +
        ((itemCount - 1) * itemSpacing) +
        padding.vertical;

    // Use SizedBox with explicit height to avoid intrinsic dimension issues
    // SliverFillRemaining needs explicit dimensions, not intrinsic calculations
    return SizedBox(
      height: totalHeight,
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            itemCount,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: TimelineShimmerItem(
                showAvatar: showAvatar,
                isFirst: index == 0,
                isLast: index == itemCount - 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
