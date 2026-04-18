import 'package:diohub/app/settings/appearance.dart';
import 'package:diohub/providers/settings/appearance_provider.dart';
import 'package:diohub/style/diff_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 8px colored circle indicating repository activity recency.
///
/// &lt; 1 week → green; &lt; 3 months → amber; &lt; 1 year → red;
/// &gt; 1 year or archived → gray. Tooltip shows exact date.
/// In [AnimationPreset.enhanced] only: subtle breathing pulse (opacity 0.6→1, ~2s).
class ActivityPulseDot extends ConsumerWidget {
  const ActivityPulseDot({
    required this.pushedAt,
    this.isArchived = false,
    this.now,
    super.key,
  });

  final DateTime? pushedAt;
  final bool isArchived;
  final DateTime? now;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final DateTime effectiveNow = now ?? DateTime.now();
    final Color color = _colorForRecency(context, effectiveNow);
    final String tooltipText =
        pushedAt != null ? _formatTooltip(pushedAt!) : 'No recent pushes';

    final Widget dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );

    final Widget wrapped = Tooltip(
      message: tooltipText,
      child: dot,
    );

    final AnimationPreset preset =
        ref.watch(appearanceProvider).animationPreset;
    if (preset == AnimationPreset.enhanced &&
        pushedAt != null &&
        !isArchived &&
        _isRecent(effectiveNow)) {
      return _BreathingDot(color: color, child: wrapped);
    }
    return wrapped;
  }

  Color _colorForRecency(final BuildContext context, final DateTime now) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    if (pushedAt == null || isArchived) {
      return cs.onSurfaceVariant.withValues(alpha: 0.6);
    }
    final Duration age = now.difference(pushedAt!);
    if (age.inDays < 7) {
      return DiffColors.addition;
    }
    if (age.inDays < 90) {
      return Colors.amber;
    }
    if (age.inDays < 365) {
      return DiffColors.deletion;
    }
    return cs.onSurfaceVariant.withValues(alpha: 0.6);
  }

  bool _isRecent(final DateTime now) {
    if (pushedAt == null) return false;
    return now.difference(pushedAt!).inDays < 7;
  }

  static String _formatTooltip(final DateTime date) {
    final String iso = date.toIso8601String();
    return iso.length > 10 ? iso.substring(0, 10) : iso;
  }
}

/// Wraps child in a breathing opacity animation (enhanced preset only).
class _BreathingDot extends StatefulWidget {
  const _BreathingDot({
    required this.color,
    required this.child,
  });

  final Color color;
  final Widget child;

  @override
  State<_BreathingDot> createState() => _BreathingDotState();
}

class _BreathingDotState extends State<_BreathingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (final BuildContext context, final Widget? child) => Opacity(
        opacity: _animation.value,
        child: child,
      ),
      child: widget.child,
    );
  }
}
