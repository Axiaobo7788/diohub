import 'package:diohub/common/animations/motion.dart';
import 'package:flutter/material.dart';

/// A widget that animates transitions between different child widgets.
///
/// This widget replaces [FadeSwitch], [SizeSwitch], [ScaleSwitch], and
/// inline [AnimatedSwitcher] calls with a unified API.
///
/// Example:
/// ```dart
/// AnimatedContentSwitcher(
///   transition: AnimationTransition.fadeSize,
///   child: currentWidget, // Change to trigger animation
/// )
/// ```
class AnimatedContentSwitcher extends StatelessWidget {
  const AnimatedContentSwitcher({
    required this.child,
    this.transition = AnimationTransition.fadeSize,
    this.duration,
    this.alignment = Alignment.topCenter,
    this.axisAlignment = -1.0,
    this.axis = Axis.vertical,
    super.key,
  });

  /// The current child widget (change to trigger animation)
  final Widget child;

  /// The type of transition to use
  final AnimationTransition transition;

  /// Animation duration
  final Duration? duration;

  /// Layout alignment for the switcher
  final AlignmentGeometry alignment;

  /// Alignment for size transitions (-1.0 = top/left, 0.0 = center, 1.0 = bottom/right)
  final double axisAlignment;

  /// The axis along which to animate (for size transitions)
  final Axis axis;

  @override
  Widget build(final BuildContext context) {
    final Duration effectiveDuration = duration ?? kSwitchDuration;

    return AnimatedSwitcher(
      duration: effectiveDuration,
      switchInCurve: kSwitchCurveIn,
      switchOutCurve: kSwitchCurveOut,
      layoutBuilder:
          (final Widget? currentChild, final List<Widget> previousChildren) =>
              Stack(
        alignment: alignment,
        children: <Widget>[
          ...previousChildren,
          if (currentChild != null) currentChild,
        ],
      ),
      transitionBuilder:
          (final Widget child, final Animation<double> animation) {
        switch (transition) {
          case AnimationTransition.fade:
            return FadeTransition(
              opacity: animation,
              child: child,
            );

          case AnimationTransition.size:
            return SizeTransition(
              sizeFactor: animation,
              axis: axis,
              axisAlignment: axisAlignment,
              child: child,
            );

          case AnimationTransition.fadeSize:
            return FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                axis: axis,
                axisAlignment: axisAlignment,
                child: child,
              ),
            );

          case AnimationTransition.fadeScale:
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1).animate(animation),
                child: child,
              ),
            );

          case AnimationTransition.fadeSlide:
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );

          case AnimationTransition.scale:
            return ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1).animate(animation),
              child: child,
            );
        }
      },
      child: child,
    );
  }
}
