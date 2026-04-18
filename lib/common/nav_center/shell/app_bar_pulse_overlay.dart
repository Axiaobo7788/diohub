import 'package:diohub/providers/settings/appearance_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overlay that draws a two-phase shimmer on the app bar pill when
/// [isRefreshing] is true or has just completed.
///
/// Stage 1 (sweeping): Repeating linear gradient sweep (~900 ms) at onSurface
/// 0.08. Stage 2 (settled): Uniform tint at onSurface 0.04 — 200 ms blend →
/// 1800 ms hold → 500 ms fade (total ~2500 ms). Clipped via [borderRadius].
/// Respects [MediaQuery.disableAnimations] and [disableShimmerAnimation]
/// (reduced motion: static tint only).
class AppBarPulseOverlay extends ConsumerStatefulWidget {
  const AppBarPulseOverlay({
    required this.isRefreshing,
    required this.borderRadius,
    super.key,
  });

  final ValueListenable<bool> isRefreshing;
  final BorderRadius borderRadius;

  @override
  ConsumerState<AppBarPulseOverlay> createState() => _AppBarPulseOverlayState();
}

enum _PulsePhase { idle, sweeping, settled }

class _AppBarPulseOverlayState extends ConsumerState<AppBarPulseOverlay>
    with TickerProviderStateMixin {
  static const Duration _sweepDuration = Duration(milliseconds: 900);
  static const Duration _settledBlend = Duration(milliseconds: 200);
  static const Duration _settledHold = Duration(milliseconds: 1800);
  static const Duration _settledFade = Duration(milliseconds: 500);

  late final AnimationController _sweepController;
  late final AnimationController _settledController;
  late final Animation<double> _settledOpacity;

  _PulsePhase _phase = _PulsePhase.idle;
  bool _lastRefreshing = false;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: _sweepDuration,
    );
    final settledTotal = _settledBlend.inMilliseconds +
        _settledHold.inMilliseconds +
        _settledFade.inMilliseconds;
    _settledController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: settledTotal),
    );
    final blendEnd = _settledBlend.inMilliseconds / settledTotal;
    final holdEnd =
        (_settledBlend.inMilliseconds + _settledHold.inMilliseconds) /
            settledTotal;
    _settledOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1),
        weight: blendEnd,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1),
        weight: holdEnd - blendEnd,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0),
        weight: 1 - holdEnd,
      ),
    ]).animate(CurvedAnimation(
      parent: _settledController,
      curve: Curves.easeInOut,
    ));
    _settledController.addStatusListener(_onSettledStatus);
    widget.isRefreshing.addListener(_onRefreshingChanged);
  }

  void _onSettledStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _phase = _PulsePhase.idle;
      _settledController.reset();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    widget.isRefreshing.removeListener(_onRefreshingChanged);
    _settledController.removeStatusListener(_onSettledStatus);
    _sweepController.dispose();
    _settledController.dispose();
    super.dispose();
  }

  void _onRefreshingChanged() {
    final value = widget.isRefreshing.value;
    final reducedMotion = MediaQuery.of(context).disableAnimations ||
        ref.read(appearanceProvider).disableShimmerAnimation;

    if (value && !_lastRefreshing) {
      if (reducedMotion) {
        _phase = _PulsePhase.settled;
        // Hold at blend end so settled opacity is 1 (static tint 0.04).
        final totalMs = _settledBlend.inMilliseconds +
            _settledHold.inMilliseconds +
            _settledFade.inMilliseconds;
        _settledController.value =
            (_settledBlend.inMilliseconds + _settledHold.inMilliseconds / 2) /
                totalMs;
        if (mounted) setState(() {});
      } else {
        _phase = _PulsePhase.sweeping;
        _sweepController.repeat();
      }
    } else if (!value && _lastRefreshing) {
      if (reducedMotion) {
        _phase = _PulsePhase.settled;
        _settledController.forward(); // fade out
      } else {
        _sweepController.stop();
        _sweepController.reset();
        _phase = _PulsePhase.settled;
        _settledController.forward(from: 0);
      }
    }
    _lastRefreshing = value;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;
    final reducedMotion = MediaQuery.of(context).disableAnimations ||
        ref.watch(appearanceProvider).disableShimmerAnimation;

    return AnimatedBuilder(
      animation: Listenable.merge(
          [_sweepController, _settledController, _settledOpacity]),
      builder: (context, child) {
        final bool showSweep = !reducedMotion &&
            _phase == _PulsePhase.sweeping &&
            _sweepController.isAnimating;
        final bool showSettled =
            _phase == _PulsePhase.settled && _settledOpacity.value > 0;

        if (!showSweep && !showSettled) return const SizedBox.shrink();

        return IgnorePointer(
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (showSweep)
                  _SweepLayer(
                    color: onSurface.withValues(alpha: 0.08),
                    t: _sweepController.value,
                  ),
                if (showSettled)
                  ColoredBox(
                    color: onSurface.withValues(
                      alpha: 0.04 * _settledOpacity.value,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SweepLayer extends StatelessWidget {
  const _SweepLayer({required this.color, required this.t});

  final Color color;
  final double t;

  @override
  Widget build(BuildContext context) {
    const bandWidth = 0.2;
    final c = (t * (1 + bandWidth)).clamp(0.0, 1.0);
    double s0 = (c - bandWidth).clamp(0.0, 1.0);
    double s1 = c;
    double s2 = (c + bandWidth).clamp(0.0, 1.0);
    if (s1 <= s0) s1 = s0 + 0.001;
    if (s2 <= s1) s2 = s1 + 0.001;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            color,
            Colors.transparent,
          ],
          stops: [s0, s1, s2],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}
