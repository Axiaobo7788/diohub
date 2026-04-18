import 'package:diohub/common/misc/shimmer_bone.dart';
import 'package:flutter/material.dart';

/// A shimmer skeleton that suggests a block of text content.
///
/// Renders [lineCount] uniform text-line bones with the last line shorter
/// to hint that the content doesn't fill the full width.
///
/// Must be used within a ShimmerScope.
///
/// Reused by: repository README, markdown_body, issue/PR body preview.
class MarkdownSkeleton extends StatelessWidget {
  const MarkdownSkeleton({
    this.lineCount = 6,
    super.key,
  });

  /// Number of text lines to show.
  final int lineCount;

  @override
  Widget build(final BuildContext context) => ShimmerBone.lines(
        count: lineCount,
        widths: List.generate(
          lineCount,
          (final int i) => i == lineCount - 1 ? 180.0 : null,
        ),
      );
}
