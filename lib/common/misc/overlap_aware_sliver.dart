import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// A widget that wraps a normal widget in a SliverPinnedHeader and adds padding
/// when it's scrolling under the NestedScrollView header pinned content.
///
/// Structure: SliverLayoutBuilder -> SliverPinnedHeader -> Normal Widget with padding
///
/// This is useful for pinned headers in the body that need to appear below
/// the header pinned content instead of behind it.
///
/// Usage:
/// ```dart
/// CustomScrollView(
///   slivers: [
///     SliverOverlapInjector(handle: overlapHandle),
///     OverlapAwareSliver(
///       headerHeight: kToolbarHeight, // Height of pinned header in NSV
///       child: Container(
///         child: YourPinnedContent(),
///       ),
///     ),
///   ],
/// )
/// ```
class OverlapAwareSliver extends StatelessWidget {
  const OverlapAwareSliver({
    required this.child,
    required this.headerHeight,
    this.paddingBuilder,
    super.key,
  });

  /// The normal widget to wrap in a SliverPinnedHeader
  final Widget child;

  /// Height of the pinned header in the NestedScrollView header
  /// (e.g., tab bar height)
  final double headerHeight;

  /// Optional builder for custom padding calculation.
  /// Receives the header height and should return the padding to apply.
  /// If null, defaults to EdgeInsets.only(top: headerHeight)
  final EdgeInsets Function(double headerHeight)? paddingBuilder;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        // Check if this pinned header is pinned (scrollOffset is 0 or very small)
        // When scrollOffset is 0, the header is pinned at the top
        final isPinned = constraints.scrollOffset <= 0.1;

print('isPinned: $isPinned');
print('headerHeight: $headerHeight');
print('constraints.scrollOffset: ${constraints.scrollOffset}');
print('constraints.overlap: ${constraints.overlap}');
print('constraints.remainingPaintExtent: ${constraints.remainingPaintExtent}');
print('constraints.remainingCacheExtent: ${constraints.remainingCacheExtent}');
print('constraints.remainingCacheExtent: ${constraints.remainingCacheExtent}');
        // Calculate padding - only apply when pinned
        final padding = isPinned
            ? (paddingBuilder != null
                ? paddingBuilder!(headerHeight)
                : EdgeInsets.only(top: headerHeight))
            : EdgeInsets.zero;

        // Return SliverPinnedHeader with padded/unpadded child
        return SliverPinnedHeader(
          child: Padding(
            padding: padding,
            child: child,
          ),
        );
      },
    );
  }
}
