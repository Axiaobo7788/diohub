import 'package:diohub/app/settings/appearance.dart';
import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/providers/settings/appearance_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A circular progress ring that sweeps from 0 to [value] on first build.
///
/// In `none`/`reduced` preset: paints final value immediately.
/// In `normal`/`enhanced` preset: animates sweep with [kEntranceDuration].
class AnimatedProgressRing extends ConsumerWidget {
  const AnimatedProgressRing({
    required this.value,
    required this.color,
    super.key,
    this.size = 12.0,
    this.strokeWidth = 2.5,
    this.backgroundColor,
  });

  /// Progress in 0.0–1.0.
  final double value;

  /// Diameter of the ring.
  final double size;

  /// Stroke width of the ring.
  final double strokeWidth;

  /// Progress segment color.
  final Color color;

  /// Track color; defaults to transparent/surface variant at call site.
  final Color? backgroundColor;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AnimationPreset preset =
        ref.watch(appearanceProvider).animationPreset;
    final Color bg = backgroundColor ??
        Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3);

    if (preset == AnimationPreset.none || preset == AnimationPreset.reduced) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          value: value.clamp(0.0, 1.0),
          color: color,
          backgroundColor: bg,
          strokeWidth: strokeWidth,
          strokeCap: StrokeCap.round,
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: kEntranceDuration,
      curve: kEntranceCurve,
      builder: (final BuildContext context, final double animValue,
              final Widget? _) =>
          SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          value: animValue,
          color: color,
          backgroundColor: bg,
          strokeWidth: strokeWidth,
          strokeCap: StrokeCap.round,
        ),
      ),
    );
  }
}
