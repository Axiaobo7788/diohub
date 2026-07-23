import 'package:diohub/common/misc/collapsible_app_bar.dart';
import 'package:diohub/common/misc/shimmer_bone.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/common/timeline/timeline_shimmer_item.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// Shimmer skeleton for the issue/PR screen.
///
/// Uses the same `DynamicScroll` + `CollapseBar` structure as the loaded
/// issue/PR screen. Shows shimmer placeholders only — no data from identifiers.
class IssuePullScreenSkeleton extends StatelessWidget {
  const IssuePullScreenSkeleton({this.embedded = false, super.key});

  final bool embedded;

  @override
  Widget build(final BuildContext context) {
    final Widget content = SafeArea(
      bottom: false,
      child: DynamicScroll(
        bar: CollapseBar(
          leading: const ShimmerScope(child: ShimmerBone.chip(width: 50)),
          // leadingFollowsTitle: true,
          title: ShimmerScope(
            child: Row(
              children: <Widget>[
                const ShimmerBone.avatar(size: 20),
                context.spacing.itemGap,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const <Widget>[
                    ShimmerBone.label(width: 60),
                    SizedBox(height: 2),
                    ShimmerBone.text(width: 100),
                  ],
                ),
              ],
            ),
          ),
          subtitle: ShimmerScope(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const ShimmerBone.text(),
                context.spacing.tightGap,
                const ShimmerBone.text(width: 180),
              ],
            ),
          ),
          action: ShimmerScope(
            child: IconButton(
              icon: ShimmerBone.icon(size: 24),
              onPressed: null,
            ),
          ),
        ),
        bodySliverBuilder:
            (final BuildContext context, final DynamicScrollMetrics metrics) =>
                <Widget>[
                  SliverToBoxAdapter(
                    child: IgnorePointer(
                      child: Padding(
                        padding: context.spacing.pagePadding,
                        child: _buildHeaderShimmer(context),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: context.spacing.screenPadding,
                      child: const TimelineShimmerList(itemCount: 4),
                    ),
                  ),
                ],
      ),
    );
    return embedded ? content : Scaffold(body: content);
  }

  Widget _buildHeaderShimmer(final BuildContext context) => ShimmerScope(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // State badge + author row
        Row(
          children: <Widget>[
            const ShimmerBone.chip(),
            context.spacing.itemGap,
            ShimmerBone.text(width: 80),
          ],
        ),
        context.spacing.contentGap,

        // Title
        const ShimmerBone.title(),
        context.spacing.tightGap,
        ShimmerBone.title(width: MediaQuery.of(context).size.width * 0.6),
        context.spacing.sectionGap,

        // Body text lines
        ShimmerBone.lines(count: 4, widths: <double?>[null, null, null, 180]),
      ],
    ),
  );
}
