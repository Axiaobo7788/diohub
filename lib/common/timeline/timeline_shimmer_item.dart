import 'package:diohub/common/misc/shimmer_widget.dart';
import 'package:diohub/style/surface_style_theme.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

/// Reusable shimmer widget for timeline items
/// Mimics the structure of UnifiedTimelineItem with shimmer effects
/// Uses IntrinsicHeight with Row to avoid LayoutBuilder issues while maintaining proper alignment
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
  Widget build(BuildContext context) {
    final indicatorSize = showAvatar ? 30.0 : 24.0;
    final lineColor = context.colorScheme.outlineVariant.withOpacity(0.5);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator column with line
          SizedBox(
            width: indicatorSize,
            child: Column(
              children: [
                // Top line (if not first)
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: lineColor,
                    ),
                  ),
                // Indicator centered
                SizedBox(
                  height: indicatorSize,
                  width: indicatorSize,
                  child: showAvatar
                      ? _buildAvatarShimmer(context, indicatorSize)
                      : _buildIconShimmer(context, indicatorSize),
                ),
                // Bottom line (if not last)
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 24, 0, showAvatar ? 12 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Action header shimmer
                  Padding(
                    padding: EdgeInsets.only(
                      top: actionHeaderTopPadding,
                      bottom: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: _buildActionTextShimmer(context, showAvatar),
                        ),
                        ShimmerWidget.container(
                          height: 12,
                          width: 30,
                          borderRadius: Theme.of(context).surfaceStyle.borderRadiusSmall(),
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
      ),
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

  Widget _buildIconShimmer(BuildContext context, double size) {
    return ShimmerWidget.container(
      height: size,
      width: size,
      borderRadius: BorderRadius.circular(size / 2),
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
            borderRadius: Theme.of(context).surfaceStyle.borderRadiusSmall(),
          ),
          const SizedBox(width: 4),
          ShimmerWidget.container(
            height: 14,
            width: 60,
            borderRadius: Theme.of(context).surfaceStyle.borderRadiusSmall(),
          ),
        ],
      );
    } else {
      // Activity format: just action text
      return ShimmerWidget.container(
        height: 14,
        width: 100,
        borderRadius: Theme.of(context).surfaceStyle.borderRadiusSmall(),
      );
    }
  }

  Widget _buildContentShimmer(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        // Main content card shimmer
        ShimmerWidget.container(
          height: 80,
          borderRadius: Theme.of(context).surfaceStyle.borderRadiusMedium(),
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
    this.showUserHeaders = false,
    super.key,
  });

  final int itemCount;
  final bool showAvatar;
  final EdgeInsets padding;
  final bool showUserHeaders;

  @override
  Widget build(BuildContext context) {
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
          (index) => TimelineShimmerItem(
            showAvatar: showAvatar,
            isFirst: index == 0,
            isLast: index == itemCount - 1,
            actionHeaderTopPadding: index == 0 ? 16.0 : 0.0,
          ),
        ),
      ),
    );
  }

  Widget _buildWithUserHeaders(BuildContext context) {
    // When showing user headers, group items into user groups
    // Show 3-4 user groups with varying items each
    final userGroups = [
      2, // First user has 2 items
      3, // Second user has 3 items
      2, // Third user has 2 items
      1, // Fourth user has 1 item
    ];

    final children = <Widget>[];

    for (var groupIndex = 0; groupIndex < userGroups.length; groupIndex++) {
      final itemsInGroup = userGroups[groupIndex];
      final isFirstGroup = groupIndex == 0;

      // Add user header (mimics _buildUserGroupHeader structure)
      children.add(
        Container(
          margin: EdgeInsets.only(
            top: isFirstGroup ? 0 : 8, // groupSpacing between groups
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildUserHeaderShimmer(context),
          ),
        ),
      );

      // Add spacing between header and first timeline item
      children.add(const SizedBox(height: 16));

      // Add timeline items for this user group
      for (var i = 0; i < itemsInGroup; i++) {
        final isFirstInGroup = i == 0;
        final isLastInGroup = i == itemsInGroup - 1;

        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TimelineShimmerItem(
              showAvatar: false, // Icon-only indicator for events
              isFirst: isFirstInGroup,
              isLast: isLastInGroup,
              actionHeaderTopPadding: isFirstInGroup ? 0.0 : 0.0,
            ),
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

  Widget _buildUserHeaderShimmer(BuildContext context) {
    return Row(
      children: [
        // Avatar shimmer
        ShimmerWidget.container(
          height: 24,
          width: 24,
          borderRadius: Theme.of(context).surfaceStyle.borderRadiusMedium(),
        ),
        const SizedBox(width: 8),
        // Username shimmer
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: ShimmerWidget.container(
            height: 14,
            width: 100,
            borderRadius: Theme.of(context).surfaceStyle.borderRadiusSmall(),
          ),
        ),
      ],
    );
  }
}
