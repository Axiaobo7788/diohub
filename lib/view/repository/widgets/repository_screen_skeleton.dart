import 'package:diohub/common/misc/collapsible_app_bar.dart';
import 'package:diohub/common/misc/markdown_skeleton.dart';
import 'package:diohub/common/misc/shimmer_bone.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// Shimmer skeleton for the repository screen.
///
/// Uses the same `DynamicScroll` + `CollapseBar` structure as the loaded
/// repository screen to ensure a seamless transition without layout jumps.
class RepositoryScreenSkeleton extends StatelessWidget {
  const RepositoryScreenSkeleton({
    super.key,
  });

  @override
  Widget build(final BuildContext context) => DynamicScroll(
        bar: CollapseBar(
          title: ShimmerScope(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const ShimmerBone.avatar(size: 24),
                context.spacing.itemGap,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const <Widget>[
                    ShimmerBone.title(width: 140),
                    SizedBox(height: 2),
                    ShimmerBone.label(width: 100),
                  ],
                ),
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
        expanded: (final BuildContext context) => ShimmerScope(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const ShimmerBone.text(),
              context.spacing.tightGap,
              ShimmerBone.text(width: MediaQuery.of(context).size.width * 0.7),
            ],
          ),
        ),
        bodySliverBuilder:
            (final BuildContext context, final DynamicScrollMetrics metrics) =>
                <Widget>[
          SliverToBoxAdapter(
            child: IgnorePointer(
              child: Padding(
                padding: context.spacing.pagePadding,
                child: ShimmerScope(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Repo info grid placeholder
                      const ShimmerBone.block(height: 80),
                      context.spacing.sectionGap,
                      // README
                      const MarkdownSkeleton(lineCount: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}
