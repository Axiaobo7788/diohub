import 'dart:math' as math;

import 'package:diohub/app/settings/appearance.dart';
import 'package:diohub/common/animations/animated_logo_layers.dart';
import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/providers/settings/appearance_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A branded progress indicator using the DioHub logo geometry.
///
/// Supports both indeterminate (spinning) and determinate (progress 0.0-1.0)
/// modes. Adapts rendering based on size (micro, small, medium, large).
/// Respects AnimationPreset for animation behavior.
class LogoProgressIndicator extends ConsumerStatefulWidget {
  const LogoProgressIndicator({
    super.key,
    this.value,
    this.size = 24.0,
    this.color,
    this.trackColor,
    this.showHub = true,
    this.showBar = true,
    this.showPercentage = false,
    this.onComplete,
  });

  /// Progress value 0.0-1.0 for determinate mode. Null for indeterminate.
  final double? value;

  /// Diameter of the indicator.
  final double size;

  /// Color of the progress arc (defaults to colorScheme.primary).
  final Color? color;

  /// Color of the track ring (defaults to onSurfaceVariant.subtle).
  final Color? trackColor;

  /// Whether to show the hub ring. Auto-disabled for size < 24.
  final bool showHub;

  /// Whether to show the bar. Auto-disabled for size < 40.
  final bool showBar;

  /// Whether to show percentage text in hub hole (only size >= 48).
  final bool showPercentage;

  /// Callback when progress reaches 1.0.
  final VoidCallback? onComplete;

  @override
  ConsumerState<LogoProgressIndicator> createState() =>
      _LogoProgressIndicatorState();
}

class _LogoProgressIndicatorState
    extends ConsumerState<LogoProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _sweepController;
  late AnimationController _breathController;
  late AnimationController _progressController;
  late AnimationController _burstController;

  late Animation<double> _sweepRotation;
  late Animation<double> _breathOpacity;

  bool _hasCompletedOnce = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _configureAnimations();
  }

  void _initializeControllers() {
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: kEntranceDuration,
    );
    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  void _configureAnimations() {
    // Sweep rotation: 0-2pi continuously
    _sweepRotation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _sweepController, curve: Curves.linear),
    );

    // Breath opacity: 0.35-1.0 (identical to ShimmerScope)
    _breathOpacity = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _progressController.addListener(_onProgressChanged);
  }

  void _onProgressChanged() {
    if (_progressController.value >= 1.0 &&
        !_hasCompletedOnce &&
        widget.value == 1.0) {
      _hasCompletedOnce = true;
      _triggerCompletionBurst();
      widget.onComplete?.call();
    }
  }

  void _triggerCompletionBurst() {
    final AnimationPreset preset =
        ref.read(appearanceProvider).animationPreset;
    if (preset == AnimationPreset.none || preset == AnimationPreset.reduced) {
      return;
    }

    _burstController.reset();
    final SpringSimulation spring = SpringSimulation(
      kSpringSnappy,
      0,
      1,
      0,
    );
    _burstController.animateWith(spring);
  }

  @override
  void didUpdateWidget(covariant LogoProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    final AnimationPreset preset =
        ref.read(appearanceProvider).animationPreset;

    // Handle mode change or preset change
    if (oldWidget.value != widget.value) {
      _updateMode(preset);
    }
  }

  void _updateMode(AnimationPreset preset) {
    if (widget.value == null) {
      // Indeterminate mode
      _progressController.stop();
      if (preset == AnimationPreset.none) {
        _sweepController.stop();
        _breathController.stop();
      } else {
        _sweepController.repeat();
        _breathController.repeat(reverse: true);
      }
      _hasCompletedOnce = false;
    } else {
      // Determinate mode
      _sweepController.stop();
      _breathController.stop();

      if (preset == AnimationPreset.none) {
        _progressController.value = widget.value!;
      } else {
        _progressController.animateTo(
          widget.value!,
          duration: preset == AnimationPreset.reduced
              ? const Duration(milliseconds: 180)
              : kEntranceDuration,
          curve: kEntranceCurve,
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMode(ref.watch(appearanceProvider).animationPreset);
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _breathController.dispose();
    _progressController.dispose();
    _burstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appearanceProvider).animationPreset;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[
          _sweepController,
          _breathController,
          _progressController,
          _burstController,
        ]),
        builder: (BuildContext context, Widget? child) {
          final double scale = 1.0 +
              (_burstController.value * 0.08); // 1.0 to 1.08 during burst

          return Transform.scale(
            scale: scale,
            child: AnimatedLogoLayers(
              size: widget.size,
              circleRotation: widget.value == null ? _sweepRotation : null,
              innerOpacity: widget.value == null ? _breathOpacity : null,
              clipProgress: widget.value,
            ),
          );
        },
      ),
    );
  }
}
