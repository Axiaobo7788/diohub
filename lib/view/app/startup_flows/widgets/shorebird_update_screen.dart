import 'package:diohub/app/settings/appearance.dart';
import 'package:diohub/common/animations/animated_content_switcher.dart';
import 'package:diohub/common/animations/logo_progress_indicator.dart';
import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/common/misc/glass_pill_surface.dart';
import 'package:diohub/providers/settings/appearance_provider.dart';
import 'package:diohub/providers/shorebird/shorebird_update_provider.dart';
import 'package:diohub/providers/shorebird/shorebird_update_state.dart';
import 'package:diohub/providers/startup/app_startup_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full-screen premium Shorebird update overlay with spring choreography.
///
/// Displays a large LogoProgressIndicator with state-driven headline/subtitle,
/// optional reassurance chip, entrance/exit animations respecting AnimationPreset.
/// On completion, invalidates appStartupProvider to restart the app with the patch.
class ShorebirdUpdateScreen extends ConsumerStatefulWidget {
  const ShorebirdUpdateScreen({super.key});

  @override
  ConsumerState<ShorebirdUpdateScreen> createState() =>
      _ShorebirdUpdateScreenState();
}

class _ShorebirdUpdateScreenState
    extends ConsumerState<ShorebirdUpdateScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _springController;
  late AnimationController _exitController;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _headlineFade;
  late Animation<double> _subtitleFade;
  late Animation<double> _chipFade;

  late Animation<double> _exitScale;
  late Animation<double> _exitFade;

  bool _entranceCompleted = false;
  bool _exitStarted = false;

  @override
  void initState() {
    super.initState();
    final AnimationPreset preset =
        ref.read(appearanceProvider).animationPreset;
    final bool useChoreography = preset == AnimationPreset.normal ||
        preset == AnimationPreset.enhanced;

    _entranceController = AnimationController(
      vsync: this,
      duration: useChoreography ? const Duration(milliseconds: 600) : Duration.zero,
    );
    _springController = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: 1,
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _logoFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );
    _headlineFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.3, 0.6, curve: kEntranceCurve),
    );
    _subtitleFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.4, 0.7, curve: kEntranceCurve),
    );
    _chipFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(_springController);

    _exitScale = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    if (preset == AnimationPreset.none) {
      _entranceController.value = 1.0;
      _springController.value = 1.0;
      _triggerDownload();
    } else {
      _entranceController.forward().then((_) {
        if (mounted) {
          setState(() {
            _entranceCompleted = true;
          });
          _triggerDownload();
        }
      });
      if (useChoreography) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _springController.animateWith(
            SpringSimulation(kSplashSpring, 0, 1, 0),
          );
        });
      }
    }
  }

  void _triggerDownload() {
    ref.read(shorebirdUpdateProvider).whenData((ShorebirdPatchState state) {
      if (state is PatchAvailable) {
        ref.read(shorebirdUpdateProvider.notifier).downloadAndInstall();
      }
    });
  }

  Future<void> _handleCompletion() async {
    if (_exitStarted) return;
    _exitStarted = true;

    final AnimationPreset preset =
        ref.read(appearanceProvider).animationPreset;
    if (preset == AnimationPreset.none || preset == AnimationPreset.reduced) {
      _restartApp();
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    await _exitController.forward();
    if (!mounted) return;
    _restartApp();
  }

  void _restartApp() {
    ref.invalidate(appStartupProvider);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _springController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ShorebirdPatchState> state =
        ref.watch(shorebirdUpdateProvider);
    final AnimationPreset preset =
        ref.watch(appearanceProvider).animationPreset;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AppSpacing spacing = context.spacing;
    final MediaQueryData media = MediaQuery.of(context);
    final double logoSize = media.size.width * 0.25;

    // React to state changes
    state.whenData((ShorebirdPatchState patchState) {
      if (patchState is PatchReadyToInstall && _entranceCompleted && !_exitStarted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleCompletion();
        });
      } else if (patchState is PatchUpToDate || patchState is PatchUnavailable) {
        if (_entranceCompleted && !_exitStarted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleCompletion();
          });
        }
      }
    });

    late final String headline;
    late final String subtitle;
    late final double? progressValue;

    state.when(
      data: (ShorebirdPatchState patchState) {
        switch (patchState) {
          case PatchAvailable():
            headline = 'Update found';
            subtitle = 'Downloading...';
            progressValue = null;
          case PatchDownloading():
            headline = 'Downloading update...';
            subtitle = "This won't take long";
            progressValue = null;
          case PatchReadyToInstall():
            headline = 'Update ready!';
            subtitle = 'Restarting...';
            progressValue = 1.0;
          case PatchFailed(:final String message):
            headline = 'Update failed';
            subtitle = message;
            progressValue = 0.0;
          case PatchUpToDate():
            headline = "You're up to date";
            subtitle = '';
            progressValue = 1.0;
          case PatchUnavailable():
            headline = 'Updates unavailable';
            subtitle = '';
            progressValue = null;
        }
      },
      loading: () {
        headline = 'Checking for updates...';
        subtitle = '';
        progressValue = null;
      },
      error: (Object _, StackTrace __) {
        headline = 'Error checking updates';
        subtitle = '';
        progressValue = null;
      },
    );

    return Scaffold(
      backgroundColor: scheme.surface,
      body: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[
          _entranceController,
          _springController,
          _exitController,
        ]),
        builder: (BuildContext context, Widget? child) {
          final double scaleValue =
              preset == AnimationPreset.none || preset == AnimationPreset.reduced
                  ? 1.0
                  : _logoScale.value * (1.0 - _exitScale.value);
          final double opacityValue =
              preset == AnimationPreset.none || preset == AnimationPreset.reduced
                  ? 1.0
                  : (1.0 - _exitFade.value);

          return Opacity(
            opacity: opacityValue,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: AlwaysStoppedAnimation<double>(scaleValue),
                      child: LogoProgressIndicator(
                        size: logoSize,
                        value: progressValue,
                        showPercentage: false,
                        showBar: true,
                        showHub: true,
                      ),
                    ),
                  ),
                  SizedBox(height: spacing.sectionSpacing),
                  FadeTransition(
                    opacity: _headlineFade,
                    child: AnimatedContentSwitcher(
                      child: Text(
                        headline,
                        key: ValueKey<String>(headline),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(height: spacing.itemSpacing),
                  FadeTransition(
                    opacity: _subtitleFade,
                    child: AnimatedContentSwitcher(
                      child: Text(
                        subtitle,
                        key: ValueKey<String>(subtitle),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _chipFade,
        builder: (BuildContext context, Widget? child) {
          return FadeTransition(
            opacity: _chipFade,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: spacing.sectionSpacing),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ...state.when(
                      data: (ShorebirdPatchState patchState) {
                        if (patchState is PatchDownloading) {
                          return <Widget>[
                            GlassPillSurface(
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: spacing.itemSpacing,
                                  vertical: spacing.tightSpacing,
                                ),
                                child: Text(
                                  'Updates are small — usually under 10 seconds',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ];
                        } else if (patchState is PatchFailed) {
                          return <Widget>[
                            FilledButton(
                              onPressed: () {
                                ref
                                    .read(shorebirdUpdateProvider.notifier)
                                    .recheck();
                              },
                              child: const Text('Retry'),
                            ),
                            SizedBox(height: spacing.itemSpacing),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Close'),
                            ),
                          ];
                        }
                        return <Widget>[];
                      },
                      loading: () => <Widget>[],
                      error: (Object _, StackTrace __) => <Widget>[],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
