import 'package:flutter/material.dart';

/// A generic wrapper to show N card skeletons for pagination first-page loading.
///
/// Works with existing shimmer card widgets like `IssuePullLoadingCard`,
/// `RepoCardLoading.buildLoading()`, etc.
///
/// Example:
/// ```dart
/// ListCardShimmerList(
///   itemCount: 5,
///   itemBuilder: (_) => const IssuePullLoadingCard(),
/// )
/// ```
class ListCardShimmerList extends StatelessWidget {
  const ListCardShimmerList({
    required this.itemBuilder,
    this.itemCount = 4,
    this.separatorHeight = 1,
    this.padding,
    super.key,
  });

  /// Builder function for each card shimmer item.
  final WidgetBuilder itemBuilder;

  /// Number of shimmer cards to display.
  final int itemCount;

  /// Height of separator between cards (0 for no separator).
  final double separatorHeight;

  /// Optional padding around the entire list.
  final EdgeInsets? padding;

  @override
  Widget build(final BuildContext context) {
    final List<Widget> children = <Widget>[];

    for (int i = 0; i < itemCount; i++) {
      children.add(itemBuilder(context));

      // Add separator between items (but not after the last one)
      if (i < itemCount - 1 && separatorHeight > 0) {
        children.add(SizedBox(height: separatorHeight));
      }
    }

    final Column column = Column(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );

    if (padding != null) {
      return Padding(
        padding: padding!,
        child: column,
      );
    }

    return column;
  }
}
