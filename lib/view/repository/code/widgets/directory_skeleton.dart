import 'package:diohub/common/misc/file_tree_skeleton.dart';
import 'package:diohub/common/misc/shimmer_bone.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';

/// Loading skeleton for the directory list. Wraps [FileTreeSkeleton] in [ShimmerScope].
class DirectorySkeleton extends StatelessWidget {
  const DirectorySkeleton({this.itemCount = 8, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ShimmerScope(
      child: Padding(
        padding: context.spacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: context.spacing.pagePadding,
              decoration: context.surfaceDecoration(
                RadiusSize.medium,
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
              ),
              child: Row(
                children: <Widget>[
                  const ShimmerBone.icon(),
                  context.spacing.itemGap,
                  const Expanded(child: ShimmerBone.text()),
                ],
              ),
            ),
            context.spacing.sectionGap,
            FileTreeSkeleton(itemCount: itemCount),
          ],
        ),
      ),
    );
  }
}
