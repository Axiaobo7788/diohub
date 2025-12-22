import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

/// A wrapper widget for [LiquidPullToRefresh] that provides sensible defaults
/// and easy configuration options.
///
/// This wrapper simplifies the usage of [LiquidPullToRefresh] by providing
/// common configuration options with sensible defaults while still allowing
/// full customization when needed.
class PullToRefreshWrapper extends StatelessWidget {
  /// Creates a [PullToRefreshWrapper].
  ///
  /// The [onRefresh] callback must be provided and should return a [Future]
  /// that completes when the refresh operation is finished.
  ///
  /// The [child] widget should be a scrollable widget (e.g., [ListView],
  /// [GridView], [CustomScrollView], etc.).
  const PullToRefreshWrapper({
    required this.onRefresh,
    required this.child,
    super.key,
    this.color,
    this.backgroundColor,
    this.showChildOpacityTransition = false,
    this.height = 50.0,
  });

  /// Callback function that is called when the user pulls to refresh.
  ///
  /// This should return a [Future] that completes when the refresh operation
  /// is finished.
  final Future<void> Function() onRefresh;

  /// The widget to wrap with pull-to-refresh functionality.
  ///
  /// This should typically be a scrollable widget.
  final Widget child;

  /// The color of the refresh indicator.
  ///
  /// If not provided, defaults to the theme's primary color.
  final Color? color;

  /// The background color of the refresh indicator.
  ///
  /// If not provided, defaults to transparent.
  final Color? backgroundColor;

  /// Whether to show opacity transition for the child widget during refresh.
  ///
  /// Defaults to `true`.
  final bool showChildOpacityTransition;

  /// The height of the refresh indicator.
  ///
  /// Defaults to `80.0`.
  final double height;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      // color: color ?? colorScheme.primary,
      // animSpeedFactor: 2.0,
      // springAnimationDurationInMilliseconds: 500,
      // backgroundColor: backgroundColor ?? Colors.transparent,
      // showChildOpacityTransition: showChildOpacityTransition,
      // height: height,
      child: child,
    );
  }
}
