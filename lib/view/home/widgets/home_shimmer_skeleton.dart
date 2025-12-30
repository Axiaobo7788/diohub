import 'package:diohub/common/misc/shimmer_widget.dart';
import 'package:diohub/common/timeline/timeline_shimmer_item.dart';
import 'package:flutter/material.dart';

/// Reusable shimmer skeleton that mimics the HomeScreen layout.
/// Shows profile card shimmer, search bar shimmer, and timeline shimmer list.
class HomeShimmerSkeleton extends StatelessWidget {
  const HomeShimmerSkeleton({
    this.timelineItemCount = 5,
    this.showTimelineUserHeaders = true,
    super.key,
  });

  /// Number of timeline shimmer items to display
  final int timelineItemCount;

  /// Whether to show user headers in the timeline shimmer
  final bool showTimelineUserHeaders;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Profile card shimmer
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar shimmer
                    ShimmerWidget.container(
                      height: 56,
                      width: 56,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Name shimmer
                          ShimmerWidget.container(
                            height: 20,
                            width: 150,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 8),
                          // Username shimmer
                          ShimmerWidget.container(
                            height: 16,
                            width: 120,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search bar shimmer
                ShimmerWidget.container(
                  height: 48,
                  borderRadius: BorderRadius.circular(24),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        // Timeline shimmer list
        SliverToBoxAdapter(
          child: TimelineShimmerList(
            itemCount: timelineItemCount,
            showAvatar: false,
            showUserHeaders: showTimelineUserHeaders,
            padding: const EdgeInsets.only(bottom: 16),
          ),
        ),
      ],
    );
  }
}


