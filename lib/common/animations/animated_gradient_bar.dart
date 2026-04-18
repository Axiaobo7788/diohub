import 'package:diohub/app/settings/appearance.dart';
import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/providers/settings/appearance_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A horizontal bar that grows from 0 width to full width on entrance,
/// revealing [child] (e.g. gradient or segmented bar).
///
/// In `none`/`reduced` preset: shows [child] directly with no animation.
/// In `normal`/`enhanced` preset: [kEntranceDuration] grow with [kEntranceCurve].
class AnimatedGradientBar extends ConsumerWidget {
  const AnimatedGradientBar({
    required this.child,
    super.key,
  });

  /// The fully-rendered bar content (gradient container, etc.).
  final Widget child;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AnimationPreset preset =
        ref.watch(appearanceProvider).animationPreset;

    if (preset == AnimationPreset.none || preset == AnimationPreset.reduced) {
      return child;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: kEntranceDuration,
      curve: kEntranceCurve,
      builder: (final BuildContext context, final double widthFactor,
              final Widget? _) =>
          ClipRect(
        child: Align(
          alignment: Alignment.centerLeft,
          widthFactor: widthFactor,
          child: child,
        ),
      ),
    );
  }
}
