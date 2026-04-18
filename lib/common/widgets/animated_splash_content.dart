import 'package:diohub/app/settings/appearance.dart';
import 'package:diohub/common/animations/animated_logo_layers.dart';
import 'package:diohub/common/animations/delayed_fade_animation.dart';
import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/common/const/app_info.dart';
import 'package:diohub/common/const/version_info.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// Premium splash content with "come alive" entrance and optional exit.
///
/// The logo appears immediately at full size (matching the native splash),
/// then "comes alive" with its indeterminate spin. Supporting text elements
/// (name, version) stagger-fade in. Respects [AnimationPreset]: none (instant),
/// reduced (simple fade stagger), normal/enhanced (full choreography).
///
/// Call [AnimatedSplashContentState.exit] to play the exit animation before
/// swapping to home (normal/enhanced only).
class AnimatedSplashContent extends StatefulWidget {
  const AnimatedSplashContent({
    required this.preset,
    super.key,
    this.message,
    this.onEntranceComplete,
  });

  final AnimationPreset preset;
  final String? message;
  final VoidCallback? onEntranceComplete;

  @override
  State<AnimatedSplashContent> createState() => AnimatedSplashContentState();
}

class AnimatedSplashContentState extends State<AnimatedSplashContent>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _exitController;
  late AnimationController _logoSpinController;
  late AnimationController _logoPulseController;

  late Animation<double> _nameFade;
  late Animation<Offset> _nameSlide;
  late Animation<double> _versionFade;
  late Animation<double> _logoRotation;
  late Animation<double> _logoPulse;

  late Animation<double> _exitLogoScale;
  late Animation<double> _exitFade;

  bool _exitCompleted = false;

  @override
  void initState() {
    super.initState();
    final bool useChoreography = widget.preset == AnimationPreset.normal ||
        widget.preset == AnimationPreset.enhanced;
    final Duration entranceDuration = widget.preset == AnimationPreset.enhanced
        ? const Duration(milliseconds: 750)
        : kSplashEntranceDuration;

    _entranceController = AnimationController(
      vsync: this,
      duration: useChoreography ? entranceDuration : Duration.zero,
    );
    _exitController = AnimationController(
      vsync: this,
      duration: kSplashExitDuration,
    );
    _logoSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Logo appears immediately at full size (no fade-in needed)
    // The "come alive" moment is the circle layer starting to spin
    _nameFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.1, 0.5, curve: kEntranceCurve),
    );
    _nameSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.1, 0.5, curve: kEntranceCurve),
    ));
    _versionFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );

    _logoRotation = Tween<double>(begin: 0, end: 6.2832).animate(
      CurvedAnimation(parent: _logoSpinController, curve: Curves.linear),
    );
    _logoPulse = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _logoPulseController, curve: Curves.easeInOut),
    );

    _exitLogoScale = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    if (widget.preset == AnimationPreset.none) {
      _entranceController.value = 1.0;
    } else if (useChoreography) {
      // Start logo spin immediately (the "come alive" moment)
      _logoSpinController.repeat();
      // For enhanced, also play the pulse once
      if (widget.preset == AnimationPreset.enhanced) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _logoPulseController.forward().then((_) {
              if (mounted) _logoPulseController.reverse();
            });
          }
        });
      }
      _entranceController.forward().then((_) {
        widget.onEntranceComplete?.call();
      });
    }
  }

  /// Plays the exit animation (logo shrink + fade). Returns a [Future] that
  /// completes when the exit is done. For [AnimationPreset.none] or
  /// [AnimationPreset.reduced], completes immediately.
  Future<void> exit() async {
    if (widget.preset == AnimationPreset.none ||
        widget.preset == AnimationPreset.reduced) {
      return;
    }
    if (_exitCompleted) return;
    _exitCompleted = true;
    await _exitController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _exitController.dispose();
    _logoSpinController.dispose();
    _logoPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    if (widget.preset == AnimationPreset.reduced) {
      return _buildReduced(context);
    }
    if (widget.preset == AnimationPreset.none) {
      return _buildStatic(context);
    }
    return _buildChoreography(context);
  }

  Widget _buildReduced(final BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    const AppNameWidget name = AppNameWidget(size: 24);
    const VersionInfoWidget version = VersionInfoWidget();
    final double logoSize = screenWidth * 0.2;

    Widget wrap(final Widget child, final Duration delay) =>
        DelayedFadeAnimation(delay: delay, child: child);

    return Stack(
      children: <Widget>[
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              wrap(
                AnimatedLogoLayers(
                  size: logoSize,
                  circleRotation: _logoRotation,
                ),
                const Duration(milliseconds: 100),
              ),
              context.spacing.sectionGap,
              wrap(name, const Duration(milliseconds: 200)),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (widget.message != null) ...[
                    Text(
                      widget.message!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    context.spacing.itemGap,
                  ],
                  wrap(version, const Duration(milliseconds: 300)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatic(final BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double logoSize = screenWidth * 0.2;
    const AppNameWidget name = AppNameWidget(size: 24);
    const VersionInfoWidget version = VersionInfoWidget();

    return Stack(
      children: <Widget>[
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimatedLogoLayers(size: logoSize),
              context.spacing.sectionGap,
              name,
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (widget.message != null) ...[
                    Text(
                      widget.message!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    context.spacing.itemGap,
                  ],
                  version,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChoreography(final BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double logoSize = screenWidth * 0.2;
    const AppNameWidget name = AppNameWidget(size: 24);
    const VersionInfoWidget version = VersionInfoWidget();

    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        _entranceController,
        _exitController,
        _logoSpinController,
        _logoPulseController,
      ]),
      builder: (final BuildContext context, final Widget? child) {
        final double exitFade = _exitFade.value;
        final double exitScale = _exitLogoScale.value;
        final bool exiting =
            _exitController.isAnimating || _exitController.value > 0;

        // For enhanced preset, apply pulse scale to inner layer
        final double pulseScale = widget.preset == AnimationPreset.enhanced
            ? _logoPulse.value
            : 1.0;

        return Stack(
          children: <Widget>[
            Center(
              child: Opacity(
                opacity: exiting ? exitFade : 1.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Logo appears immediately at full size - no fade/scale entrance
                    // The "come alive" is the circle layer spinning
                    if (exiting)
                      ScaleTransition(
                        scale: AlwaysStoppedAnimation<double>(exitScale),
                        child: AnimatedLogoLayers(
                          size: logoSize,
                          circleRotation: _logoRotation,
                        ),
                      )
                    else
                      Transform.scale(
                        scale: pulseScale,
                        child: AnimatedLogoLayers(
                          size: logoSize,
                          circleRotation: _logoRotation,
                        ),
                      ),
                    context.spacing.sectionGap,
                    SlideTransition(
                      position: _nameSlide,
                      child: FadeTransition(
                        opacity: _nameFade,
                        child: name,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Opacity(
                    opacity: exiting ? exitFade : _versionFade.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (widget.message != null) ...[
                          Text(
                            widget.message!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          context.spacing.itemGap,
                        ],
                        version,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
