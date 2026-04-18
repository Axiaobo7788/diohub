import 'package:diohub/common/animations/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Spring-driven entrance/exit animation for pills appearing/disappearing.
///
/// Used for:
/// - Hiding non-active pills when one goes active
/// - Showing all pills when active pill deactivates
/// - Initial dock render entrance (staggered)
/// - Companion row entrance (staggered)
///
/// Combines [ScaleTransition] (0 → 1 on Z-axis), [SizeTransition] on [axis],
/// and [FadeTransition] (0 → 1) with spring physics via [kPillSpring].
/// [animateEntrance] springs open on mount when visible.
class PillEntrance extends StatefulWidget {
  const PillEntrance({
    required this.visible,
    required this.child,
    this.axis = Axis.horizontal,
    this.animateEntrance = false,
    super.key,
  });

  final bool visible;
  final Widget child;

  /// Axis for size collapse/expand (layout slot). Horizontal for pill rows.
  final Axis axis;

  /// When true and visible on mount, animate from 0 → 1 with spring instead of snapping.
  final bool animateEntrance;

  @override
  State<PillEntrance> createState() => _PillEntranceState();
}

class _PillEntranceState extends State<PillEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      lowerBound: 0,
      upperBound: 1,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    if (widget.visible) {
      if (widget.animateEntrance) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.visible) {
            _controller.animateWith(
              SpringSimulation(kPillSpring, 0, 1, 0),
            );
          }
        });
      } else {
        _controller.value = 1;
      }
    }
  }

  @override
  void didUpdateWidget(covariant PillEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        _controller.animateWith(
          SpringSimulation(
            kPillSpring,
            0,
            1,
            0,
          ),
        );
      } else {
        _controller.animateWith(
          SpringSimulation(
            kPillSpring,
            1,
            0,
            0,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible && _controller.value == 0) {
      return const SizedBox.shrink();
    }
    return FadeTransition(
      opacity: _opacity,
      child: SizeTransition(
        axis: widget.axis,
        sizeFactor: _controller,
        axisAlignment: 0.0,
        child: ScaleTransition(
          scale: _scale,
          child: widget.child,
        ),
      ),
    );
  }
}
