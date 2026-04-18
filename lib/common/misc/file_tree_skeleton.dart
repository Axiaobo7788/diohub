import 'package:diohub/common/misc/shimmer_bone.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// A shimmer skeleton that mimics a file tree structure.
///
/// Shows shimmer placeholders for folder/file icons and filenames
/// at varying indentation levels, matching the typical layout of a
/// code browser's file tree.
///
/// Must be used within a ShimmerScope.
///
/// Used by: code browser tab.
class FileTreeSkeleton extends StatelessWidget {
  const FileTreeSkeleton({
    this.itemCount = 10,
    super.key,
  });

  /// Number of file/folder items to show.
  final int itemCount;

  @override
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          itemCount,
          (final int index) {
            // Vary filename widths to look more natural
            final double nameWidth = _getNameWidth(index, context);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: <Widget>[
                  // Icon container (circular, matches BrowserListTile)
                  const ShimmerBone.avatar(size: 32),
                  context.spacing.contentGap,
                  // Filename placeholder
                  Expanded(child: ShimmerBone.text(width: nameWidth)),
                  // Chevron icon
                  const ShimmerBone.icon(size: 18),
                ],
              ),
            );
          },
        ),
      );

  /// Returns varying name widths to look more natural.
  double _getNameWidth(final int index, final BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    const List<double> widthFactors = <double>[
      0.4,
      0.3,
      0.35,
      0.45,
      0.25,
      0.5,
      0.3,
      0.4,
      0.35,
      0.3
    ];
    return screenWidth * widthFactors[index % widthFactors.length];
  }
}
