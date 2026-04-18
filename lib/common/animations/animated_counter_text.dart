import 'package:diohub/app/settings/appearance.dart';
import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/providers/settings/appearance_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A text widget that animates between numeric values by counting up/down.
///
/// In `none` preset: renders final value instantly.
/// In `reduced` preset: fades between old and new text.
/// In `normal`/`enhanced` preset: smoothly morphs the number.
///
/// Usage:
/// ```dart
/// AnimatedCounterText(
///   value: 1234,
///   style: theme.textTheme.titleMedium,
///   formatter: (v) => v.toString(), // optional
/// )
/// ```
class AnimatedCounterText extends ConsumerStatefulWidget {
  const AnimatedCounterText({
    required this.value,
    super.key,
    this.style,
    this.formatter,
    this.duration,
    this.curve,
  });

  /// The target numeric value to display.
  final int value;

  /// Text style for the rendered number.
  final TextStyle? style;

  /// Optional formatter to convert int → display String.
  /// Defaults to `value.toString()`.
  final String Function(int)? formatter;

  /// Override duration. Defaults to [kMicroDuration] (200ms).
  final Duration? duration;

  /// Override curve. Defaults to [kMicroCurve].
  final Curve? curve;

  @override
  ConsumerState<AnimatedCounterText> createState() =>
      _AnimatedCounterTextState();
}

class _AnimatedCounterTextState extends ConsumerState<AnimatedCounterText> {
  int _previousValue = 0;

  @override
  void didUpdateWidget(final AnimatedCounterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
    }
  }

  String _format(final int v) => widget.formatter?.call(v) ?? v.toString();

  @override
  Widget build(final BuildContext context) {
    final AnimationPreset preset =
        ref.watch(appearanceProvider).animationPreset;
    final Duration duration = widget.duration ?? kMicroDuration;
    final Curve curve = widget.curve ?? kMicroCurve;

    if (preset == AnimationPreset.none) {
      return Text(_format(widget.value), style: widget.style);
    }

    if (preset == AnimationPreset.reduced) {
      return AnimatedSwitcher(
        duration: duration,
        switchInCurve: curve,
        switchOutCurve: curve,
        child: Text(
          _format(widget.value),
          key: ValueKey<int>(widget.value),
          style: widget.style,
        ),
      );
    }

    // normal / enhanced: count morph
    final double startValue = _previousValue.toDouble();
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(widget.value),
      tween: Tween<double>(begin: startValue, end: widget.value.toDouble()),
      duration: duration,
      curve: curve,
      builder:
          (final BuildContext context, final double value, final Widget? _) =>
              Text(_format(value.round()), style: widget.style),
    );
  }
}
