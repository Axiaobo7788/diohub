import 'package:diohub/common/animations/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scroll_to_top/flutter_scroll_to_top.dart'
    show AnimatePrompt;

/// A widget that animates the visibility of its child with various transition effects.
///
/// This widget replaces [SizeExpandedSection], [FadeAnimationSection],
/// [ScaleExpandedSection], and [AnimatePrompt] with a unified API.
///
/// Example:
/// ```dart
/// AnimatedVisibility(
///   visible: isVisible,
///   transition: AnimationTransition.fadeSize,
///   child: MyWidget(),
/// )
/// ```
class AnimatedVisibility extends StatefulWidget {
  const AnimatedVisibility({
    required this.visible,
    required this.child,
    this.transition = AnimationTransition.fadeSize,
    this.axis = Axis.vertical,
    this.axisAlignment = -1.0,
    this.duration,
    this.reverseDuration,
    this.curve,
    this.alignment,
    super.key,
  });

  /// Whether the child should be visible
  final bool visible;

  /// The widget to show/hide
  final Widget child;

  /// The type of transition to use
  final AnimationTransition transition;

  /// The axis along which to animate (for size transitions)
  final Axis axis;

  /// Alignment for size transitions (-1.0 = top/left, 0.0 = center, 1.0 = bottom/right)
  final double axisAlignment;

  /// Duration for the forward animation
  final Duration? duration;

  /// Duration for the reverse animation
  final Duration? reverseDuration;

  /// Animation curve
  final Curve? curve;

  /// Alignment for scale transitions
  final Alignment? alignment;

  @override
  State<AnimatedVisibility> createState() => _AnimatedVisibilityState();
}

class _AnimatedVisibilityState extends State<AnimatedVisibility>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    if (widget.visible) {
      _controller.value = 1.0;
    }
  }

  void _initializeAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? kStateDuration,
      reverseDuration: widget.reverseDuration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve ?? kStateCurve,
    );
  }

  @override
  void didUpdateWidget(final AnimatedVisibility oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration ?? kStateDuration;
    }

    if (oldWidget.reverseDuration != widget.reverseDuration) {
      _controller.reverseDuration = widget.reverseDuration;
    }

    if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final Widget child = widget.child;
    // When size is fully collapsed, do not build the real child so BackdropFilter
    // (e.g. in toolbar pills) does not paint and bleed through.
    final Widget sizeChild =
        _controller.isDismissed ? const SizedBox.shrink() : child;

    // Apply transitions based on the selected type
    switch (widget.transition) {
      case AnimationTransition.fade:
        return FadeTransition(
          opacity: _animation,
          child: child,
        );

      case AnimationTransition.size:
        return SizeTransition(
          sizeFactor: _animation,
          axis: widget.axis,
          axisAlignment: widget.axisAlignment,
          child: sizeChild,
        );

      case AnimationTransition.fadeSize:
        return FadeTransition(
          opacity: _animation,
          child: SizeTransition(
            sizeFactor: _animation,
            axis: widget.axis,
            axisAlignment: widget.axisAlignment,
            child: sizeChild,
          ),
        );

      case AnimationTransition.scale:
        return ScaleTransition(
          scale: _animation,
          alignment: widget.alignment ?? Alignment.center,
          child: child,
        );

      case AnimationTransition.fadeScale:
        return FadeTransition(
          opacity: _animation,
          child: ScaleTransition(
            scale: _animation,
            alignment: widget.alignment ?? Alignment.center,
            child: child,
          ),
        );

      case AnimationTransition.fadeSlide:
        // Not typically used for visibility, but supported for consistency
        return FadeTransition(
          opacity: _animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(_animation),
            child: child,
          ),
        );
    }
  }
}
