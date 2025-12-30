import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/src/base/paged_child_builder_delegate.dart';
import 'package:infinite_scroll_pagination/src/base/paged_layout_builder.dart';
import 'package:infinite_scroll_pagination/src/core/extensions.dart';
import 'package:infinite_scroll_pagination/src/core/paging_state.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// A [SliverList] with pagination capabilities that renders items as slivers.
///
/// Similar to [PagedSliverList] but allows each item to be rendered as
/// multiple slivers instead of a single widget.
///
/// This widget must be wrapped by a [CustomScrollView] when added to the screen.
class PagedSliverListWithSlivers<PageKeyType, ItemType>
    extends StatelessWidget {
  const PagedSliverListWithSlivers({
    required this.state,
    required this.fetchNextPage,
    required this.builderDelegate,
    required this.animationWrapperBuilder,
    required this.itemSliverBuilder,
    this.shrinkWrapFirstPageIndicators = false,
    super.key,
  });

  /// The paging state for this layout.
  final PagingState<PageKeyType, ItemType> state;

  /// A callback function that is triggered to request a new page of data.
  final VoidCallback fetchNextPage;

  /// The delegate for building the UI pieces of scrolling paged listings.
  final PagedChildBuilderDelegate<ItemType> builderDelegate;

  /// A function that returns a Widget→Widget wrapper for a given item index.
  ///
  /// This wrapper can be used to apply animations or other transformations
  /// to the slivers returned by [itemSliverBuilder].
  final Widget Function(Widget) Function(BuildContext context, int index)
      animationWrapperBuilder;

  /// A function that returns a sliver for a given item.
  ///
  /// The function receives:
  /// - [context]: The build context
  /// - [item]: The item to build a sliver for
  /// - [index]: The index of the item
  /// - [animationWrapper]: A function that wraps a widget (from [animationWrapperBuilder])
  ///
  /// Returns a sliver that will be inserted into the scroll view.
  final Widget Function(
    BuildContext context,
    ItemType item,
    int index,
    Widget Function(Widget) animationWrapper,
  ) itemSliverBuilder;

  /// Whether the extent of the first page indicators should be determined by
  /// the contents being viewed.
  ///
  /// If the paged layout builder does not shrink wrap, then the first page
  /// indicators will expand to the maximum allowed size. If the paged layout
  /// builder has unbounded constraints, then [shrinkWrapFirstPageIndicators]
  /// must be true.
  ///
  /// Defaults to false.
  final bool shrinkWrapFirstPageIndicators;

  @override
  Widget build(BuildContext context) {
    return PagedLayoutBuilder<PageKeyType, ItemType>(
      layoutProtocol: PagedLayoutProtocol.sliver,
      state: state,
      fetchNextPage: fetchNextPage,
      builderDelegate: builderDelegate,
      shrinkWrapFirstPageIndicators: shrinkWrapFirstPageIndicators,
      loadingListingBuilder: (
        context,
        itemBuilder,
        itemCount,
        progressIndicatorBuilder,
      ) =>
          _buildSliverListing(
        context,
        itemBuilder,
        itemCount,
        progressIndicatorBuilder,
        null,
      ),
      errorListingBuilder: (
        context,
        itemBuilder,
        itemCount,
        errorIndicatorBuilder,
      ) =>
          _buildSliverListing(
        context,
        itemBuilder,
        itemCount,
        null,
        errorIndicatorBuilder,
      ),
      completedListingBuilder: (
        context,
        itemBuilder,
        itemCount,
        noMoreItemsIndicatorBuilder,
      ) =>
          _buildSliverListing(
        context,
        itemBuilder,
        itemCount,
        null,
        null,
        noMoreItemsIndicatorBuilder: noMoreItemsIndicatorBuilder,
      ),
    );
  }

  Widget _buildSliverListing(
    BuildContext context,
    IndexedWidgetBuilder itemBuilder,
    int itemCount,
    WidgetBuilder? progressIndicatorBuilder,
    WidgetBuilder? errorIndicatorBuilder, {
    WidgetBuilder? noMoreItemsIndicatorBuilder,
  }) {
    // PagedLayoutBuilder guarantees itemCount > 0 and items != null when
    // calling listing builders. First-page states are handled separately.
    final items = state.items!;

    // Build slivers for all items
    final List<Widget> slivers = [];

    // Loop through all items
    for (int index = 0; index < itemCount; index++) {
      // Call itemBuilder once per item (required for pagination logic)
      itemBuilder(context, index);

      // Get the item
      final item = items[index];

      // Get animation wrapper for this index
      final animationWrapper = animationWrapperBuilder(context, index);

      // Build sliver for this item
      final itemSliver = itemSliverBuilder(
        context,
        item,
        index,
        animationWrapper,
      );

      // Append sliver from this item
      slivers.add(itemSliver);
    }

    // Append indicators AFTER items (matching PagedSliverList behavior)
    if (progressIndicatorBuilder != null) {
      slivers.add(
        SliverToBoxAdapter(
          child: progressIndicatorBuilder(context),
        ),
      );
    } else if (errorIndicatorBuilder != null) {
      slivers.add(
        SliverToBoxAdapter(
          child: errorIndicatorBuilder(context),
        ),
      );
    } else if (noMoreItemsIndicatorBuilder != null) {
      slivers.add(
        SliverToBoxAdapter(
          child: noMoreItemsIndicatorBuilder(context),
        ),
      );
    }

    // Return a single MultiSliver containing everything
    return MultiSliver(children: slivers);
  }
}
