import 'package:diohub/common/misc/collapsible_app_bar.dart';
import 'package:diohub/common/misc/shimmer_bone.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/common/timeline/timeline_shimmer_item.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
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
  Widget build(final BuildContext context) => DynamicScroll(
        bar: CollapseBar(
          leading: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 44),
            child: const ShimmerScope(child: ShimmerBone.avatar(size: 44)),
          ),
          title: const ShimmerScope(child: ShimmerBone.title(width: 140)),
          subtitle: const ShimmerScope(child: ShimmerBone.label(width: 100)),
          action: const ShimmerScope(
            child: IconButton(
              icon: ShimmerBone.icon(size: 24),
              onPressed: null,
            ),
          ),
        ),
        expanded: (final BuildContext context) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: context.radius(RadiusSize.medium),
            child: Padding(
              padding: context.spacing.cardContentPadding,
              child: ShimmerScope(
                child: Row(
                  children: <Widget>[
                    const ShimmerBone.icon(size: 18),
                    context.spacing.itemGap,
                    const Expanded(child: ShimmerBone.text()),
                  ],
                ),
              ),
            ),
          ),
        ),
        bodySliverBuilder:
            (final BuildContext context, final DynamicScrollMetrics metrics) =>
                <Widget>[
          SliverToBoxAdapter(
            child: IgnorePointer(
              child: TimelineShimmerList(
                itemCount: timelineItemCount,
                showUserHeaders: showTimelineUserHeaders,
                padding: const EdgeInsets.only(bottom: 16),
              ),
            ),
          ),
        ],
      );
}
