import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// State of scroll-based minimize behavior
enum ScrollMinimizeState {
  /// Widget is visible (not minimized)
  visible,

  /// Widget should be minimized (transitioning to minimized)
  minimizing,

  /// Widget is minimized by scroll
  minimized,

  /// Widget should be restored (transitioning to visible)
  restoring,
}

/// Controller that handles scroll-based minimize/restore logic
///
/// Tracks scroll deltas (relative movement) and determines when to minimize/restore based on
/// scroll thresholds. Uses delta-based tracking which is immune to position jumps from
/// pagination or tab switches. Can be used with any widget that needs scroll-based
/// visibility control.
///
/// **Best Practices:**
/// - This controller is the single source of truth for scroll-based minimize state
/// - Widgets should reactively respond to [state] changes, not maintain duplicate state
/// - Use [state] to determine UI behavior, not internal flags
class ScrollBasedMinimizeController extends ChangeNotifier {
  ScrollBasedMinimizeController({
    this.enableScrollMinimize = true,
    this.scrollMinimizeOffset = 200.0,
    this.scrollOffsetUntilMinimize = 150.0,
    this.scrollOffsetUntilRestore = 150.0,
    this.scrollInitialOffset = 350.0,
    this.debugLogging = false,
  }) : _initializationStopwatch = Stopwatch()..start();

  /// Whether scroll-based minimize is enabled
  final bool enableScrollMinimize;

  /// Scroll offset threshold to enable minimize on scroll
  /// Defaults to 200.0
  final double scrollMinimizeOffset;

  /// Scroll offset to trigger minimize when scrolling down
  /// Defaults to 50.0
  final double scrollOffsetUntilMinimize;

  /// Scroll offset to trigger restore when scrolling up
  /// Defaults to 50.0
  final double scrollOffsetUntilRestore;

  /// Initial scroll offset required before tracking starts
  /// This prevents immediate minimize/restore on small scroll movements
  /// Defaults to 350.0
  final double scrollInitialOffset;

  /// Enable debug logging
  final bool debugLogging;

  // Internal state - track cumulative scroll deltas instead of absolute positions
  double _cumulativeScrollDown = 0.0; // Cumulative scroll down distance
  double _cumulativeScrollUp = 0.0; // Cumulative scroll up distance
  ScrollMinimizeState _state = ScrollMinimizeState.visible;
  final Stopwatch
      _initializationStopwatch; // Track elapsed time since controller creation

  /// Current state of scroll-based minimize behavior
  /// This is the single source of truth - widgets should react to this
  ScrollMinimizeState get state => _state;

  /// Whether the widget was minimized by scroll
  /// Convenience getter for checking if currently minimized
  bool get isMinimizedByScroll =>
      _state == ScrollMinimizeState.minimized ||
      _state == ScrollMinimizeState.minimizing;

  /// Handle a scroll notification
  /// Returns true if the notification was handled and should be consumed
  bool handleScrollNotification(ScrollNotification notification) {
    if (!enableScrollMinimize) {
      return false;
    }

    // Only handle scroll update notifications
    if (notification is! ScrollUpdateNotification) {
      return false;
    }

    final metrics = notification.metrics;

    // Only respond to vertical scroll (up/down), ignore horizontal scroll (left/right)
    if (metrics.axisDirection != AxisDirection.down &&
        metrics.axisDirection != AxisDirection.up) {
      // Horizontal scroll - ignore
      return false;
    }

    final pixels = metrics.pixels; // Only used for threshold checks, not stored
    final scrollDelta = notification.scrollDelta ?? 0.0;

    // Ignore scroll notifications during initial layout phase (first 500ms)
    // This prevents programmatic scrolls (like DynamicScroll initialization) from triggering minimize
    if (_initializationStopwatch.elapsedMilliseconds < 500) {
      return false;
    } else {
      _initializationStopwatch.stop();
    }

    // Ignore programmatic scroll jumps (very large deltas indicate jumpTo/animateTo)
    // Normal user scrolling rarely exceeds 50px per frame
    if (scrollDelta.abs() > 100.0) {
      return false;
    }

    // Determine scroll direction from scrollDelta
    // Positive delta = scrolling down, negative delta = scrolling up
    final isScrollingDown = scrollDelta > 0;
    final isScrollingUp = scrollDelta < 0;

    // Check if we're at the top (should restore)
    if (pixels <= scrollMinimizeOffset && isMinimizedByScroll) {      _transitionToRestoring();
      return false;
    }

    // Only process if we're past the threshold
    if (pixels <= scrollMinimizeOffset) {
      return false;
    }

    // Track scroll deltas based on direction
    if (isScrollingDown) {
      _handleScrollDown(scrollDelta);
    } else if (isScrollingUp) {
      _handleScrollUp(scrollDelta);
    }

    return false;
  }

  void _handleScrollDown(double scrollDelta) {
    // Ignore scroll tracking if already minimized or minimizing (same direction)
    // Allow tracking if restoring (opposite direction) - user might want to cancel restore
    if (_state == ScrollMinimizeState.minimized ||
        _state == ScrollMinimizeState.minimizing) {
      return;
    }

    // Reset reverse direction tracking when scrolling down
    _cumulativeScrollUp = 0.0;

    // Accumulate scroll down distance
    _cumulativeScrollDown += scrollDelta;    // Only start tracking after initial offset threshold
    if (_cumulativeScrollDown < scrollInitialOffset) {
      return;
    }

    // Calculate how much we've scrolled past the initial threshold
    final scrollPastInitial = _cumulativeScrollDown - scrollInitialOffset;

    // Check if scrolled enough to minimize
    if (scrollPastInitial >= scrollOffsetUntilMinimize) {
      // Only transition if not already minimized or minimizing
      if (_state != ScrollMinimizeState.minimized &&
          _state != ScrollMinimizeState.minimizing) {        _transitionToMinimizing();
        // Reset tracking after transitioning
        _cumulativeScrollDown = 0.0;
      }
    }
  }

  void _handleScrollUp(double scrollDelta) {
    // Ignore scroll tracking if already visible or restoring (same direction)
    // Allow tracking if minimizing (opposite direction) - user might want to cancel minimize
    if (_state == ScrollMinimizeState.visible ||
        _state == ScrollMinimizeState.restoring) {
      return;
    }

    // Reset forward direction tracking when scrolling up
    _cumulativeScrollDown = 0.0;

    // Accumulate scroll up distance (delta is negative, so we add the absolute value)
    _cumulativeScrollUp += scrollDelta.abs();    // Only start tracking after initial offset threshold
    if (_cumulativeScrollUp < scrollInitialOffset) {
      return;
    }

    // Calculate how much we've scrolled past the initial threshold
    final scrollPastInitial = _cumulativeScrollUp - scrollInitialOffset;

    // Check if scrolled enough to restore
    if (scrollPastInitial >= scrollOffsetUntilRestore) {
      // Only restore if currently minimized by scroll
      if (isMinimizedByScroll) {        _transitionToRestoring();
      } else {        // Reset tracking even if not restoring to prevent issues
        _cumulativeScrollUp = 0.0;
      }
    }
  }

  void _transitionToMinimizing() {
    if (_state == ScrollMinimizeState.minimized ||
        _state == ScrollMinimizeState.minimizing) {
      return; // Already minimized or minimizing
    }    _state = ScrollMinimizeState.minimizing;
    notifyListeners();
  }

  void _transitionToRestoring() {
    if (!isMinimizedByScroll) {      return;
    }    _state = ScrollMinimizeState.restoring;

    // Reset all scroll tracking accumulators
    _cumulativeScrollDown = 0.0;
    _cumulativeScrollUp = 0.0;

    notifyListeners();
  }

  /// Called by the widget when minimize animation completes
  /// This transitions from [ScrollMinimizeState.minimizing] to [ScrollMinimizeState.minimized]
  void onMinimizeComplete() {
    if (_state == ScrollMinimizeState.minimizing) {      _state = ScrollMinimizeState.minimized;
      notifyListeners();
    }
  }

  /// Called by the widget when restore animation completes
  /// This transitions from [ScrollMinimizeState.restoring] to [ScrollMinimizeState.visible]
  void onRestoreComplete() {
    if (_state == ScrollMinimizeState.restoring) {      _state = ScrollMinimizeState.visible;
      notifyListeners();
    }
  }

  /// Reset all scroll tracking state
  void reset() {
    _cumulativeScrollDown = 0.0;
    _cumulativeScrollUp = 0.0;
    _state = ScrollMinimizeState.visible;
    notifyListeners();
  }
}
