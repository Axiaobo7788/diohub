import 'package:diohub/common/misc/sliver_pinned_overlap_injector.dart';
import 'package:diohub/common/wrappers/liquid_pull_to_refresh_wrapper.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_scroll_to_top/flutter_scroll_to_top.dart';
import 'package:flutter_scroll_to_top/modified_scroll_view.dart' as scrollview;

/// Properties passed by [ScrollToTopWrapper] to integrate with scroll-to-top.
/// When non-null, the scroll view is built via [scrollview.CustomScrollView].
// typedef ScrollViewProperties = scrollview.ScrollViewProperties;

/// A wrapper for [CustomScrollView] that automatically handles common patterns
/// like [SliverOverlapInjector] for [NestedScrollView] integration, pull-to-refresh,
/// and scroll-to-top functionality.
///
/// This wrapper simplifies the usage of [CustomScrollView] by automatically:
/// - Injecting [SliverOverlapInjector] when inside a [NestedScrollView]
/// - Optionally wrapping with pull-to-refresh functionality
/// - Optionally wrapping with scroll-to-top functionality
///
/// Example:
/// ```dart
/// AppCustomScrollView(
///   slivers: [
///     SliverList(
///       delegate: SliverChildBuilderDelegate(
///         (context, index) => ListTile(title: Text('Item $index')),
///         childCount: 100,
///       ),
///     ),
///   ],
/// )
/// ```
///
/// With pull-to-refresh:
/// ```dart
/// AppCustomScrollView(
///   slivers: [...],
///   onRefresh: () async {
///     // Refresh logic
///   },
/// )
/// ```
class AppCustomScrollView extends StatelessWidget {
  /// Creates an [AppCustomScrollView].
  ///
  /// The [slivers] parameter is required and should contain the slivers to display.
  const AppCustomScrollView({
    required this.slivers,
    super.key,
    this.controller,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.center,
    this.anchor = 0.0,
    this.cacheExtent,
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.onRefresh,
    this.disableRefresh = false,
    this.autoInjectOverlap = true,
    this.scrollViewProperties,
  });

  /// When non-null (e.g. from [ScrollToTopWrapper.builder]), the scroll view
  /// is built with [scrollview.CustomScrollView] so scroll-to-top works.
  /// Set by wrappers that build this inside [ScrollToTopWrapper].
  final ScrollViewProperties? scrollViewProperties;

  /// The slivers to display in the scroll view.
  final List<Widget> slivers;

  /// An object that can be used to control the position to which this scroll
  /// view is scrolled.
  final ScrollController? controller;

  /// The axis along which the scroll view scrolls.
  ///
  /// Defaults to [Axis.vertical].
  final Axis scrollDirection;

  /// Whether the scroll view scrolls in the reading direction.
  ///
  /// Defaults to false.
  final bool reverse;

  /// Whether this is the primary scroll view associated with the parent
  /// [PrimaryScrollController].
  ///
  /// Defaults to true when [scrollDirection] is [Axis.vertical] and
  /// [controller] is null.
  final bool? primary;

  /// How the scroll view should respond to user input.
  ///
  /// For example, determines how the scroll view continues to animate after the
  /// user stops dragging the scroll view.
  ///
  /// Defaults to matching platform conventions.
  final ScrollPhysics? physics;

  /// Whether the extent of the scroll view in the [scrollDirection] should be
  /// determined by the contents being viewed.
  ///
  /// Defaults to false.
  final bool shrinkWrap;

  /// The first child in the [CustomScrollView] will be placed as close as
  /// possible to the [center] of the viewport.
  ///
  /// Defaults to null.
  final Key? center;

  /// The relative position of the zero scroll offset.
  ///
  /// Defaults to 0.0.
  final double anchor;

  /// The cache extent used by the scroll view.
  ///
  /// Defaults to [RenderViewport.defaultCacheExtent].
  final double? cacheExtent;

  /// The number of children that will contribute semantic information.
  ///
  /// Defaults to null.
  final int? semanticChildCount;

  /// Determines the way that drag start behavior is handled.
  ///
  /// Defaults to [DragStartBehavior.start].
  final DragStartBehavior dragStartBehavior;

  /// [ScrollViewKeyboardDismissBehavior] the defines how this [ScrollView] will
  /// dismiss the keyboard automatically.
  ///
  /// Defaults to [ScrollViewKeyboardDismissBehavior.manual].
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// Restoration ID to save and restore the scroll offset of the scrollable.
  ///
  /// Defaults to null.
  final String? restorationId;

  /// The content will be clipped (or not) according to this option.
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  /// Callback function that is called when the user pulls to refresh.
  ///
  /// If provided, the scroll view will be wrapped with pull-to-refresh
  /// functionality. The callback should return a [Future] that completes when
  /// the refresh operation is finished.
  final Future<void> Function()? onRefresh;

  /// Whether to disable pull-to-refresh functionality.
  ///
  /// Defaults to false. If [onRefresh] is null, this has no effect.
  final bool disableRefresh;

  /// Whether to automatically inject [SliverOverlapInjector] when inside a
  /// [NestedScrollView].
  ///
  /// Defaults to true. Set to false if you want to manually handle overlap
  /// injection or if you're not using [NestedScrollView].
  final bool autoInjectOverlap;

  @override
  Widget build(final BuildContext context) {
    // Fetch overlap handle from NestedScrollView if available and auto-inject is enabled
    final SliverOverlapAbsorberHandle? overlapHandle = autoInjectOverlap
        ? ExtendedNestedScrollView.maybeSliverOverlapAbsorberHandleFor(context)
        : null;

    // Build the slivers list with overlap injector if needed
    final List<Widget> finalSlivers = <Widget>[
      if (overlapHandle != null)
        SliverPinnedOverlapInjector(handle: overlapHandle),
      ...slivers,
    ];

    // Build the CustomScrollView
    Widget buildScrollView(final ScrollViewProperties? properties) {
      if (properties != null) {
        return scrollview.CustomScrollView(
          properties: properties,
          physics: physics,
          shrinkWrap: shrinkWrap,
          center: center,
          anchor: anchor,
          cacheExtent: cacheExtent,
          semanticChildCount: semanticChildCount,
          dragStartBehavior: dragStartBehavior,
          keyboardDismissBehavior: keyboardDismissBehavior,
          restorationId: restorationId,
          clipBehavior: clipBehavior,
          slivers: finalSlivers,
        );
      } else {
        return CustomScrollView(
          controller: controller,
          scrollDirection: scrollDirection,
          reverse: reverse,
          primary: primary,
          physics: physics,
          shrinkWrap: shrinkWrap,
          center: center,
          anchor: anchor,
          cacheExtent: cacheExtent,
          semanticChildCount: semanticChildCount,
          dragStartBehavior: dragStartBehavior,
          keyboardDismissBehavior: keyboardDismissBehavior,
          restorationId: restorationId,
          clipBehavior: clipBehavior,
          slivers: finalSlivers,
        );
      }
    }

    // Wrap with pull-to-refresh if onRefresh is provided
    Widget buildWithRefresh(final ScrollViewProperties? properties) {
      final Widget scrollView = buildScrollView(properties);

      if (onRefresh != null && !disableRefresh) {
        return PullToRefreshWrapper(
          onRefresh: onRefresh!,
          child: scrollView,
        );
      }

      return scrollView;
    }

    return buildWithRefresh(scrollViewProperties);
  }
}

extension AppScrollViewExtension on Widget {
  SliverToBoxAdapter toSliverToBoxAdapter() => SliverToBoxAdapter(child: this);
  SliverFillRemaining toSliverFillRemaining() =>
      SliverFillRemaining(child: this);
}
