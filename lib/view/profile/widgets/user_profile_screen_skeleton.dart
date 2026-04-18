import 'package:diohub/common/misc/collapsible_app_bar.dart';
import 'package:diohub/common/misc/shimmer_bone.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// Shimmer skeleton for the user profile screen.
///
/// Uses the same `DynamicScroll` + `CollapseBar` structure as the loaded
/// profile screen. Shows shimmer placeholders only — no data from identifiers.
class UserProfileScreenSkeleton extends StatelessWidget {
  const UserProfileScreenSkeleton({
    super.key,
  });

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
        bodySliverBuilder:
            (final BuildContext context, final DynamicScrollMetrics metrics) =>
                <Widget>[
          SliverToBoxAdapter(
            child: IgnorePointer(
              child: Padding(
                padding: context.spacing.pagePadding,
                child: _buildBodyShimmer(context),
              ),
            ),
          ),
        ],
      );

  Widget _buildBodyShimmer(final BuildContext context) => ShimmerScope(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Contributions section
            const ShimmerBone.title(width: 180),
            context.spacing.sectionGap,
            const ShimmerBone.block(height: 120),
            context.spacing.spaciousGap,

            // Activity section
            const ShimmerBone.title(width: 150),
            context.spacing.sectionGap,
            ShimmerBone.lines(widths: <double?>[null, null, 180]),
          ],
        ),
      );
}
