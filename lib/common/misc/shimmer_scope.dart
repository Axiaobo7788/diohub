import 'dart:async';

import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/common/misc/shimmer_bone.dart' show ShimmerBone;
import 'package:diohub/providers/settings/appearance_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps a subtree of shimmer bones in a single synchronized animation.
///
/// Place one [ShimmerScope] around the loading state of a screen/section.
/// All [ShimmerBone] descendants will animate together in lockstep.
///
/// Reads [disableShimmerAnimation] from [appearanceProvider]. When true,
/// shows a static opacity placeholder instead of the breathing animation.
///
/// Uses a calm "breathe" pulse animation — a sinusoidal opacity oscillation
/// between 40% and 100% — instead of a directional shimmer sweep.
/// This creates a more premium, organic feel aligned with the app's
/// glass-pill / squircle design language.
///
/// Example:
/// ```dart
/// ShimmerScope(
///   child: Column(
///     children: [
///       ShimmerBone.text(width: 100),
///       context.spacing.tightGap,
///       ShimmerBone.title(),
///     ],
///   ),
/// )
/// ```
class ShimmerScope extends ConsumerStatefulWidget {
  const ShimmerScope({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ShimmerScope> createState() => _ShimmerScopeState();
}

class _ShimmerScopeState extends ConsumerState<ShimmerScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: kSkeletonPulseDuration,
    );

    _opacity = Tween<double>(
      begin: 0.35,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final bool disableShimmerAnimation =
        ref.watch(appearanceProvider).disableShimmerAnimation ||
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    if (disableShimmerAnimation) {
      _controller.stop();
      return Opacity(
        key: const ValueKey<String>('shimmer-scope-static'),
        opacity: 0.6,
        child: widget.child,
      );
    }
    if (!_controller.isAnimating) {
      unawaited(_controller.repeat(reverse: true));
    }
    return FadeTransition(
      key: const ValueKey<String>('shimmer-scope-animation'),
      opacity: _opacity,
      child: widget.child,
    );
  }
}
