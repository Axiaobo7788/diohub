import 'package:diohub/style/surface_style_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef ExpandableScrollBuilder = Widget Function(
  BuildContext context,
  Widget expandOnScrollWidget,
);

typedef PullToExpandCollapsedWidgetBuilder = Widget Function(
  BuildContext context,
  double pullProgress,
  bool isReadyToExpand,
);

typedef PullToExpandExpandedWidgetBuilder = Widget Function(
  BuildContext context,
  VoidCallback onCollapse,
);

typedef PullToExpandTransitionBuilder = Widget Function(
  Widget child,
  Animation<double> animation,
);

/// Indicator widget shown when collapsed, displaying "Pull for details" with a chevron.
/// The text and chevron animate based on pull progress with rotation, scale, and opacity.
/// Shows a background pill that reveals as pull progress increases, with a visual effect
/// when ready to expand.
class PullToExpandIndicator extends StatefulWidget {
  const PullToExpandIndicator({
    required this.pullProgress,
    required this.isReadyToExpand,
    this.text = 'More Details',
    super.key,
  });

  /// Pull progress from 0.0 (not pulling) to 1.0 (at threshold).
  final double pullProgress;

  /// Whether the pull distance has reached the threshold and is ready to expand.
  final bool isReadyToExpand;

  /// Text to display. Defaults to "Pull for details".
  final String text;

  @override
  State<PullToExpandIndicator> createState() => _PullToExpandIndicatorState();
}

class _PullToExpandIndicatorState extends State<PullToExpandIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 0.5,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.12, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 0.5,
      ),
    ]).animate(_pulseController);
  }

  @override
  void didUpdateWidget(PullToExpandIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isReadyToExpand && !oldWidget.isReadyToExpand) {
      // Single jump animation when becoming ready
      _pulseController.forward(from: 0.0).then((_) {
        // After animation completes, reset to 1.0 and keep it there
        _pulseController.reset();
      });
    } else if (!widget.isReadyToExpand && oldWidget.isReadyToExpand) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Scale text from 0 to 1 based on pull progress - makes text 0 size at 0 state
    final double textScale = widget.pullProgress.clamp(0.0, 1.0);

    // Animate text opacity: start at 0, increase as you pull
    final double textOpacity = widget.pullProgress.clamp(0.0, 1.0);

    // Animate icon opacity: start at 0, increase as you pull
    final double iconOpacity =
        0.5 + (widget.pullProgress.clamp(0.0, 1.0) * 0.2); // 0.5 to 0.7

    // Animate text size from 12 to 13 based on progress
    final double fontSize = 12.0 + (widget.pullProgress * 1.0);

    // Animate chevron size from 16 to 18 based on progress
    final double chevronSize = 16.0 + (widget.pullProgress * 2.0);

    // Text and icon color - use onSurface color with opacity for subtle appearance
    final double colorOpacity = 0.4 + (widget.pullProgress * 0.3); // 0.4 to 0.7

    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          // Use pulse animation value during the jump, then 1.0 when ready (after jump completes)
          final double scale = widget.isReadyToExpand
              ? (_pulseController.isAnimating ? _pulseAnimation.value : 1.0)
              : 1.0;

          return Transform.scale(
            scale: scale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizeTransition(
                  sizeFactor: AlwaysStoppedAnimation(textScale),
                  axisAlignment: 0.0,
                  child: Opacity(
                    opacity: textOpacity.clamp(0.0, 1.0),
                    child: Center(
                      child: Text(
                        widget.text,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: fontSize,
                          color: colorScheme.onSurface
                              .withOpacity(colorOpacity.clamp(0.0, 1.0)),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
                ),
                Opacity(
                  opacity: iconOpacity.clamp(0.0, 1.0),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 16.0, end: chevronSize),
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    builder: (context, animatedSize, child) {
                      return Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: animatedSize,
                        color: colorScheme.onSurface
                            .withOpacity(colorOpacity.clamp(0.0, 1.0)),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Expanded content widget that displays metadata using DetailTile components.
/// Modern floating card design with clean layout and smooth animations.
class ExpandableMetadataContent extends StatelessWidget {
  const ExpandableMetadataContent({
    required this.children,
    required this.onCollapse,
    this.title,
    super.key,
  });

  /// List of widgets (typically DetailTile widgets) to display.
  final List<Widget> children;

  /// Callback to collapse the expanded content.
  final VoidCallback onCollapse;

  /// Title to display in the header. If null, defaults to 'Details'.
  final String? title;

  BorderRadius _getTileBorderRadius(
    SurfaceStyleTheme surfaceStyle,
    int index,
    int total,
  ) {
    if (total == 1) {
      // Single tile - round bottom corners only
      return surfaceStyle.borderRadiusLarge(
        corners: [CornerSide.bottom],
      );
    } else if (index == 0) {
      // First tile - no rounded corners (connects to header)
      return BorderRadius.zero;
    } else if (index == total - 1) {
      // Last tile - round bottom corners
      return surfaceStyle.borderRadiusLarge(
        corners: [CornerSide.bottom],
      );
    } else {
      // Middle tiles - no rounded corners
      return BorderRadius.zero;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceStyle = theme.surfaceStyle;

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    // Use darker colors to match app bar styling
    final bool isDark = colorScheme.brightness == Brightness.dark;
    final Color backgroundColor = colorScheme.surfaceContainer;

    // Header background - match app bar color
    final Color headerBackground = colorScheme.surfaceContainer;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: surfaceStyle.borderRadiusLarge(),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(isDark ? 0.12 : 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header section with title and collapse button
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: headerBackground,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant
                      .withOpacity(isDark ? 0.2 : 0.12),
                  width: 1,
                ),
              ),
              borderRadius: surfaceStyle.borderRadiusLarge().copyWith(
                    bottomLeft: Radius.zero,
                    bottomRight: Radius.zero,
                  ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title ?? 'Details',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onCollapse,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            colorScheme.surfaceContainerHigh.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.keyboard_arrow_up_rounded,
                            size: 18,
                            color: colorScheme.primary.withOpacity(0.9),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Collapse',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Metadata content section with visual separation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: surfaceStyle.borderRadiusLarge().copyWith(
                    topLeft: Radius.zero,
                    topRight: Radius.zero,
                  ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  ClipRRect(
                    borderRadius: _getTileBorderRadius(
                      surfaceStyle,
                      i,
                      children.length,
                    ),
                    child: children[i],
                  ),
                  if (i < children.length - 1)
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: colorScheme.outlineVariant
                          .withOpacity(isDark ? 0.15 : 0.1),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
///   collapsedWidget: (context, progress, isReadyToExpand) => PullToExpandIndicator(
///     pullProgress: progress,
///     isReadyToExpand: isReadyToExpand,
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
    required this.expandedWidget,
    required this.builder,
    this.collapsedWidget,
    this.duration = const Duration(milliseconds: 250),
    this.curve = Curves.fastOutSlowIn,
    this.expandThreshold = 100.0,
    this.transitionBuilder,
    super.key,
  });

  /// Builder that receives pull progress (0.0 to 1.0) and isReadyToExpand flag
  /// for animating collapsed widget.
  /// progress = 0.0 when not pulling, 1.0 when at expandThreshold.
  /// isReadyToExpand = true when pull distance has reached expandThreshold.
  /// If null, nothing is shown when collapsed.
  final PullToExpandCollapsedWidgetBuilder? collapsedWidget;

  /// Builder that receives a collapse callback to programmatically collapse the widget.
  final PullToExpandExpandedWidgetBuilder expandedWidget;

  /// Duration of the expand/collapse animation.
  final Duration duration;

  /// Curve for the expand/collapse animation.
  final Curve curve;

  /// Pull distance threshold (in pixels) required to trigger expansion.
  /// Defaults to 100.0 pixels.
  final double expandThreshold;

  /// Custom transition builder for the expand/collapse animation.
  /// If null, defaults to SizeTransition.
  /// The animation parameter goes from 0.0 (collapsed) to 1.0 (expanded).
  final PullToExpandTransitionBuilder? transitionBuilder;

  /// Builder that receives the expandOnScrollWidget to place in your scrollable structure.
  ///
  /// The expandable widget should be placed as the first item in your scrollable
  /// (e.g., first sliver in CustomScrollView, first item in ListView).
  final ExpandableScrollBuilder builder;

  @override
  State<ExpandOnScrollWrapper> createState() => _ExpandOnScrollWrapperState();
}

class _ExpandOnScrollWrapperState extends State<ExpandOnScrollWrapper> {
  double _pullProgress = 0.0;
  bool _isExpanded = false;
  bool _isReadyToExpand = false;
  static const bool _debugLogging = true; // Set to false to disable logs

  void _log(final String message) {
    if (_debugLogging) {
      debugPrint('[ExpandOnScrollWrapper] $message');
    }
  }

  void _resetPullState() {
    setState(() {
      _pullProgress = 0.0;
      _isReadyToExpand = false;
    });
  }

  void _updatePullProgress(final double pullDistance) {
    final double progress =
        (pullDistance / widget.expandThreshold).clamp(0.0, 1.0);
    final bool isReady = pullDistance >= widget.expandThreshold;

    if (_pullProgress != progress || _isReadyToExpand != isReady) {
      final double currentProgress = _pullProgress;
      final bool wasReady = _isReadyToExpand;
      _log(
          'Updating pull progress: $currentProgress -> $progress, isReadyToExpand: $wasReady -> $isReady');
      setState(() {
        _pullProgress = progress;
        _isReadyToExpand = isReady;
      });
      // Trigger haptic feedback when becoming ready
      if (!wasReady && isReady) {
        HapticFeedback.mediumImpact();
      }
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
        _log(
            'Pull detected: distance=$pullDistance, threshold=${widget.expandThreshold}');
        _updatePullProgress(pullDistance);
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
        _log('Pull detected (pixels < 0): distance=$pullDistance');
        _updatePullProgress(pullDistance);
      } else if (metrics.pixels >= 0 && _pullProgress > 0 && !_isExpanded) {
        // Only reset pull progress if NOT expanded
        // If expanded, keep it expanded (only collapse via onCollapse callback)
        _log('Resetting pull progress: pixels >= 0');
        _resetPullState();
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
        _resetPullState();
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

    // Handle scroll end - expand only when user releases at threshold
    if (notification is ScrollEndNotification) {
      final ScrollMetrics metrics = notification.metrics;
      _log(
          'ScrollEndNotification: pixels=${metrics.pixels}, isReadyToExpand=$_isReadyToExpand');

      // Only expand if threshold was reached and user releases
      if (_isReadyToExpand && !_isExpanded) {
        _log('Threshold reached on release! Expanding...');
        setState(() {
          _isExpanded = true;
        });
      } else if (!_isReadyToExpand && _pullProgress > 0 && !_isExpanded) {
        // Reset if user released before reaching threshold
        _log('Resetting pull progress: released before threshold');
        _resetPullState();
      }
      return false;
    }

    return false;
  }

  void _collapse() {
    _log('Collapsing...');
    setState(() {
      _isExpanded = false;
    });
    _resetPullState();
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
      isReadyToExpand: _isReadyToExpand,
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
    required this.isReadyToExpand,
    required this.isExpanded,
    required this.onCollapse,
    this.collapsedWidget,
    required this.expandedWidget,
    required this.duration,
    required this.curve,
    this.transitionBuilder,
  });

  final double pullProgress;
  final bool isReadyToExpand;
  final bool isExpanded;
  final VoidCallback onCollapse;
  final Widget Function(
          BuildContext context, double pullProgress, bool isReadyToExpand)?
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
          (final Widget child, final Animation<double> animation) =>
              SizeTransition(
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
              child: collapsedWidget!(context, pullProgress, isReadyToExpand),
            ),
    );
  }
}
