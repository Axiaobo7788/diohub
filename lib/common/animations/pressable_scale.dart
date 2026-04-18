/// Micro press-down spring animation for high-value action buttons.
///
/// Scales from 1.0 → 0.95 on press, springs back on release using the
/// app's [kMicroDuration] and [kMicroCurve] motion tokens.
///
/// This is a **visual-only** widget. It does not handle tap callbacks.
/// Uses [Listener] (not [GestureDetector]) so it does not participate in the
/// gesture arena and will not conflict with tap handlers. Wrap it inside
/// a tap-handling widget like `TapFeedback`, `InkWell`, or
/// `BorderedContainer(onTap:)` to get both the press animation and the
/// tap callback.
///
/// Example:
/// ```dart
/// TapFeedback(
///   onTap: () => ref.read(notifier).toggleStar(),
///   child: PressableScale(
///     child: StarIcon(),
///   ),
/// )
/// ```
library;

import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/providers/haptic_service_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PressableScale extends StatefulWidget {
  const PressableScale({
    required this.child,
    this.scaleFactor = 0.95,
    this.haptic = true,
    this.enabled = true,
    super.key,
  });

  /// The child widget to scale.
  final Widget child;

  /// How much to scale down on press (default 0.95 = 5% shrink).
  final double scaleFactor;

  /// Whether to trigger haptic feedback on press.
  final bool haptic;

  /// Whether the pressable interaction is enabled.
  final bool enabled;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: kMicroDuration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: widget.scaleFactor,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: kMicroCurve,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(final PointerDownEvent _) {
    if (!widget.enabled) return;
    _controller.forward();
    if (widget.haptic) {
      ProviderScope.containerOf(context)
          .read(hapticServiceProvider)
          .selectionClick();
    }
  }

  void _onPointerUp(final PointerUpEvent _) {
    _controller.reverse();
  }

  void _onPointerCancel(final PointerCancelEvent _) {
    _controller.reverse();
  }

  @override
  Widget build(final BuildContext context) => Listener(
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        behavior: HitTestBehavior.translucent,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: widget.child,
        ),
      );
}
