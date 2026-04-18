import 'package:diohub/app/settings/dashboard_settings.dart';
import 'package:diohub/common/misc/shimmer_bone.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// Builds shimmer skeleton for dashboard sections based on settings.
List<Widget> buildDashboardShimmer(DashboardSettings settings) {
  final visibleSections = settings.sectionOrder.where(settings.isVisible).toList();

  return [
    ShimmerScope(
      child: Builder(
        builder: (context) {
          final spacing = context.spacing;
          final List<Widget> shimmers = [];

          for (final (index, id) in visibleSections.indexed) {
            final topPadding = index == 0 ? spacing.sectionSpacing : spacing.sectionSpacing;
            
            switch (id) {
              case DashboardSectionId.stats:
                shimmers.add(Padding(
                  padding: spacing.screenPadding.copyWith(top: topPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ShimmerBone(height: 16, width: 100),
                      spacing.compactGap,
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: spacing.itemSpacing,
                        crossAxisSpacing: spacing.itemSpacing,
                        childAspectRatio: 2,
                        children: List.generate(
                          4,
                          (_) => const ShimmerBone(height: 60),
                        ),
                      ),
                    ],
                  ),
                ));

              case DashboardSectionId.contributions:
                shimmers.add(Padding(
                  padding: spacing.screenPadding.copyWith(top: topPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ShimmerBone(height: 16, width: 150),
                      spacing.compactGap,
                      Row(
                        children: List.generate(
                          7,
                          (i) => Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: i < 6 ? spacing.itemSpacing : 0,
                              ),
                              child: const ShimmerBone(height: 40),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ));

              default:
                final limit = settings.limitFor(id);
                shimmers.add(Padding(
                  padding: spacing.screenPadding.copyWith(top: topPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ShimmerBone(height: 16, width: 120),
                      spacing.compactGap,
                      ...List.generate(
                        limit,
                        (_) => Padding(
                          padding: EdgeInsets.only(bottom: spacing.itemSpacing),
                          child: const ShimmerBone(height: 80),
                        ),
                      ),
                    ],
                  ),
                ));
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: shimmers,
          );
        },
      ),
    ),
  ];
}
