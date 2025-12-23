import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A wrapper widget that uses NotificationListener to detect pull-to-expand gestures.
///
/// This wrapper wraps any scrollable widget and detects overscroll via ScrollNotifications,
/// making it compatible with RefreshIndicator and other scroll-based widgets.
///
/// The [builder] callback receives the expandable widget that should be placed in your
/// scrollable structure.
///
/// Example:
/// ```dart
/// ExpandOnScrollWrapper(
///   collapsedWidget: (context, progress) => PullToExpandIndicator(
///     pullProgress: progress,
///   ),
///   expandedWidget: (context, onCollapse) => ExpandedContentWidget(
///     onCollapse: onCollapse,
///   ),
///   builder: (context, expandOnScrollWidget) => CustomScrollView(
///     slivers: [
///       SliverToBoxAdapter(child: expandOnScrollWidget),
///       SliverList(...),
///     ],
///   ),
/// )
/// ```
class ExpandOnScrollWrapper extends StatefulWidget {
  const ExpandOnScrollWrapper({
    this.collapsedWidget,
    required this.expandedWidget,
    this.duration = const Duration(milliseconds: 250),
    this.curve = Curves.fastOutSlowIn,
    this.expandThreshold = 200.0,
    this.transitionBuilder,
    required this.builder,
    super.key,
  });

  /// Builder that receives pull progress (0.0 to 1.0) for animating collapsed widget.
  /// progress = 0.0 when not pulling, 1.0 when at expandThreshold.
  /// If null, nothing is shown when collapsed.
  final Widget Function(BuildContext context, double pullProgress)?
      collapsedWidget;

  /// Builder that receives a collapse callback to programmatically collapse the widget.
  final Widget Function(BuildContext context, VoidCallback onCollapse)
      expandedWidget;

  /// Duration of the expand/collapse animation.
  final Duration duration;

  /// Curve for the expand/collapse animation.
  final Curve curve;

  /// Pull distance threshold (in pixels) required to trigger expansion.
  /// Defaults to 200.0 pixels.
  final double expandThreshold;

  /// Custom transition builder for the expand/collapse animation.
  /// If null, defaults to SizeTransition.
  /// The animation parameter goes from 0.0 (collapsed) to 1.0 (expanded).
  final Widget Function(Widget child, Animation<double> animation)?
      transitionBuilder;

  /// Builder that receives the expandOnScrollWidget to place in your scrollable structure.
  ///
  /// The expandable widget should be placed as the first item in your scrollable
  /// (e.g., first sliver in CustomScrollView, first item in ListView).
  final Widget Function(
    BuildContext context,
    Widget expandOnScrollWidget,
  ) builder;

  @override
  State<ExpandOnScrollWrapper> createState() => _ExpandOnScrollWrapperState();
}

class _ExpandOnScrollWrapperState extends State<ExpandOnScrollWrapper> {
  double _pullProgress = 0.0;
  bool _isExpanded = false;
  static const bool _debugLogging = true; // Set to false to disable logs

  void _log(final String message) {
    if (_debugLogging) {
      debugPrint('[ExpandOnScrollWrapper] $message');
    }
  }

  bool _handleScrollNotification(final ScrollNotification notification) {
    _log('Received notification: ${notification.runtimeType}');

    // Handle overscroll (pull down) - this is the key!
    if (notification is OverscrollNotification) {
      final ScrollMetrics metrics = notification.metrics;
      _log('OverscrollNotification: overscroll=${notification.overscroll}, '
          'pixels=${metrics.pixels}, axis=${metrics.axis}');

      // Only handle vertical overscroll
      if (metrics.axis != Axis.vertical) {
        _log('Ignoring: not vertical axis');
        return false;
      }

      // Overscroll.overscroll is negative when pulling down
      final double overscroll = notification.overscroll;
      _log('Overscroll value: $overscroll');

      if (overscroll < 0) {
        final double pullDistance = overscroll.abs();
        final double progress =
            (pullDistance / widget.expandThreshold).clamp(0.0, 1.0);
        _log(
            'Pull detected: distance=$pullDistance, progress=$progress, threshold=${widget.expandThreshold}');

        if (_pullProgress != progress) {
          _log('Updating pull progress: $_pullProgress -> $progress');
          setState(() {
            _pullProgress = progress;
          });
        }

        // Expand when threshold reached
        if (pullDistance >= widget.expandThreshold && !_isExpanded) {
          _log('Threshold reached! Expanding...');
          HapticFeedback.mediumImpact();
          setState(() {
            _isExpanded = true;
          });
        }
      }
      return false; // Don't consume, let RefreshIndicator work
    }

    // Handle scroll updates to detect pull and reset
    if (notification is ScrollUpdateNotification) {
      final ScrollMetrics metrics = notification.metrics;
      _log('ScrollUpdateNotification: pixels=${metrics.pixels}, '
          'scrollDelta=${notification.scrollDelta}, '
          'depth=${notification.depth}');

      // Check if we're at the top and pulling down (pixels < 0)
      if (metrics.pixels < 0) {
        final double pullDistance = metrics.pixels.abs();
        final double progress =
            (pullDistance / widget.expandThreshold).clamp(0.0, 1.0);
        _log(
            'Pull detected (pixels < 0): distance=$pullDistance, progress=$progress');

        if (_pullProgress != progress) {
          _log('Updating pull progress: $_pullProgress -> $progress');
          setState(() {
            _pullProgress = progress;
          });
        }

        // Expand when threshold reached
        if (pullDistance >= widget.expandThreshold && !_isExpanded) {
          _log('Threshold reached! Expanding...');
          HapticFeedback.mediumImpact();
          setState(() {
            _isExpanded = true;
          });
        }
      } else if (metrics.pixels >= 0 && _pullProgress > 0 && !_isExpanded) {
        // Only reset pull progress if NOT expanded
        // If expanded, keep it expanded (only collapse via onCollapse callback)
        _log('Resetting pull progress: pixels >= 0');
        setState(() {
          _pullProgress = 0.0;
        });
      }
      return false;
    }

    // Handle scroll metrics to reset state when scrolled back to top
    if (notification is ScrollMetricsNotification) {
      _log('ScrollMetricsNotification: pixels=${notification.metrics.pixels}, '
          'minScrollExtent=${notification.metrics.minScrollExtent}, '
          'maxScrollExtent=${notification.metrics.maxScrollExtent}');

      // Only reset pull progress if NOT expanded
      // If expanded, keep it expanded (only collapse via onCollapse callback)
      if (notification.metrics.pixels >= 0 &&
          _pullProgress > 0 &&
          !_isExpanded) {
        _log('Resetting pull progress: pixels >= 0');
        setState(() {
          _pullProgress = 0.0;
        });
      }
      return false;
    }

    // Handle scroll start
    if (notification is ScrollStartNotification) {
      final ScrollMetrics metrics = notification.metrics;
      _log(
          'ScrollStartNotification: pixels=${metrics.pixels}, depth=${notification.depth}');
      return false;
    }

    // Handle scroll end
    if (notification is ScrollEndNotification) {
      final ScrollMetrics metrics = notification.metrics;
      _log('ScrollEndNotification: pixels=${metrics.pixels}');
      return false;
    }

    return false;
  }

  void _collapse() {
    _log('Collapsing...');
    setState(() {
      _isExpanded = false;
      _pullProgress = 0.0;
    });
  }

  @override
  void initState() {
    super.initState();
    _log('ExpandOnScrollWrapper initialized');
    _log('Expand threshold: ${widget.expandThreshold}px');
  }

  @override
  Widget build(final BuildContext context) {
    _log(
        'Building with pullProgress: $_pullProgress, isExpanded: $_isExpanded');

    // Create the expandable widget with current state
    final _ExpandOnScrollContent expandOnScrollWidget = _ExpandOnScrollContent(
      pullProgress: _pullProgress.clamp(0.0, 1.0),
      isExpanded: _isExpanded,
      onCollapse: _collapse,
      collapsedWidget: widget.collapsedWidget,
      expandedWidget: widget.expandedWidget,
      duration: widget.duration,
      curve: widget.curve,
      transitionBuilder: widget.transitionBuilder,
    );

    // Wrap with NotificationListener and pass widget to builder
    // The NotificationListener must wrap the scrollable to catch notifications
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: widget.builder(context, expandOnScrollWidget),
    );
  }
}

class _ExpandOnScrollContent extends StatelessWidget {
  const _ExpandOnScrollContent({
    required this.pullProgress,
    required this.isExpanded,
    required this.onCollapse,
    this.collapsedWidget,
    required this.expandedWidget,
    required this.duration,
    required this.curve,
    this.transitionBuilder,
  });

  final double pullProgress;
  final bool isExpanded;
  final VoidCallback onCollapse;
  final Widget Function(BuildContext context, double pullProgress)?
      collapsedWidget;
  final Widget Function(BuildContext context, VoidCallback onCollapse)
      expandedWidget;
  final Duration duration;
  final Curve curve;
  final Widget Function(Widget child, Animation<double> animation)?
      transitionBuilder;

  @override
  Widget build(final BuildContext context) {
    // If no collapsed widget, show expanded widget directly or nothing
    if (collapsedWidget == null) {
      return isExpanded
          ? expandedWidget(context, onCollapse)
          : const SizedBox.shrink();
    }

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      transitionBuilder: transitionBuilder ??
          (final Widget child, final Animation<double> animation) => SizeTransition(
              sizeFactor: animation,
              axisAlignment: 1,
              child: child,
            ),
      child: isExpanded
          ? KeyedSubtree(
              key: const ValueKey('expanded'),
              child: expandedWidget(context, onCollapse),
            )
          : KeyedSubtree(
              key: const ValueKey('collapsed'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: collapsedWidget!(context, pullProgress),
              ),
            ),
    );
  }
}
