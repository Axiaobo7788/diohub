import 'package:diohub/app/settings/appearance.dart';
import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/providers/settings/appearance_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps a chart (or any widget) with a preset-gated entrance animation.
///
/// - [AnimationPreset.none]: child shown instantly.
/// - [AnimationPreset.reduced]: fade in.
/// - [AnimationPreset.normal] / [enhanced]: fade in over [kEntranceDuration].
class ChartEntrance extends ConsumerWidget {
  const ChartEntrance({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AnimationPreset preset =
        ref.watch(appearanceProvider).animationPreset;
    if (preset == AnimationPreset.none) {
      return child;
    }
    if (preset == AnimationPreset.reduced) {
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        builder: (final BuildContext context, final double value, final _) =>
            Opacity(opacity: value, child: child),
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: kEntranceDuration,
      curve: kEntranceCurve,
      builder: (final BuildContext context, final double value, final _) =>
          Opacity(opacity: value, child: child),
    );
  }
}
