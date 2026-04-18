import 'dart:async';

import 'package:diohub/common/animations/motion.dart';
import 'package:flutter/material.dart';

/// Animated chevron that rotates 180° between closed (▾) and open (▴) states.
///
/// Use in dock navigator pill as a dropdown indicator instead of a menu icon.
class AnimatedChevron extends StatefulWidget {
  const AnimatedChevron({
    required this.isOpen,
    this.size = 18,
    super.key,
  });

  final bool isOpen;
  final double size;

  @override
  State<AnimatedChevron> createState() => _AnimatedChevronState();
}

class _AnimatedChevronState extends State<AnimatedChevron>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: kMicroDuration,
    );
    _rotation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: kMicroCurve),
    );
    if (widget.isOpen) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedChevron oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        unawaited(_controller.forward());
      } else {
        unawaited(_controller.reverse());
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return RotationTransition(
      turns: _rotation,
      child: Icon(
        Icons.expand_more_rounded,
        size: widget.size,
        color: IconTheme.of(context).color,
      ),
    );
  }
}
