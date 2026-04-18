import 'package:diohub/common/animations/animated_content_switcher.dart';
import 'package:diohub/common/animations/motion.dart';
import 'package:flutter/material.dart';

class SliverAnimatedSwitcher extends StatelessWidget {
  const SliverAnimatedSwitcher({
    required this.child,
    this.transition = AnimationTransition.fadeSize,
    this.duration,
    this.alignment = Alignment.topCenter,
    this.axisAlignment = -1.0,
    this.axis = Axis.vertical,
    super.key,
  });

  final Widget child;
  final AnimationTransition transition;
  final Duration? duration;
  final AlignmentGeometry alignment;
  final double axisAlignment;
  final Axis axis;

  @override
  Widget build(final BuildContext context) => SliverToBoxAdapter(
        child: AnimatedContentSwitcher(
          transition: transition,
          duration: duration,
          alignment: alignment,
          axisAlignment: axisAlignment,
          axis: axis,
          child: child,
        ),
      );
}
