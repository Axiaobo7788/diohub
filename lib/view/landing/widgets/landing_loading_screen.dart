import 'package:auto_route/annotations.dart';
import 'package:diohub/app/settings/appearance.dart';
import 'package:diohub/common/animations/animations.dart';
import 'package:diohub/common/animations/logo_progress_indicator.dart';
import 'package:diohub/common/const/app_tokens.dart';
import 'package:diohub/common/widgets/splash_content.dart';
import 'package:diohub/providers/settings/appearance_provider.dart';
import 'package:diohub/providers/startup/app_startup_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@RoutePage()
class LandingLoadingScreen extends ConsumerStatefulWidget {
  const LandingLoadingScreen({super.key});

  @override
  ConsumerState<LandingLoadingScreen> createState() =>
      _LandingLoadingScreenState();
}

class _LandingLoadingScreenState extends ConsumerState<LandingLoadingScreen> {
  final GlobalKey<AnimatedSplashContentState> _splashKey =
      GlobalKey<AnimatedSplashContentState>();

  @override
  Widget build(final BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final AppearanceSettings appearance = ref.watch(appearanceProvider);
    final AnimationPreset preset = appearance.animationPreset;
    final AsyncValue<AppStartupState> startup = ref.watch(appStartupProvider);

    final Widget body = startup.when(
      loading: () =>
          _buildSplash(context, screenWidth, preset: preset, animated: true),
      error: (final Object e, final _) => _buildError(
        context,
        preset,
        e.toString(),
        onRetry: () => ref.invalidate(appStartupProvider),
      ),
      data: (final AppStartupState state) => switch (state) {
        StartupLoading() => _buildSplash(
          context,
          screenWidth,
          preset: preset,
          animated: true,
        ),
        StartupPublic() => _buildSplash(
          context,
          screenWidth,
          preset: preset,
          animated: false,
        ),
        StartupError(:final message) => _buildError(
          context,
          preset,
          message,
          onRetry: () => ref.invalidate(appStartupProvider),
        ),
        StartupReady() => _buildSplash(
          context,
          screenWidth,
          preset: preset,
          animated: false,
        ),
      },
    );

    final bool isPremium =
        preset == AnimationPreset.normal || preset == AnimationPreset.enhanced;
    if (isPremium) {
      return Scaffold(backgroundColor: AppTokens.backgroundDark, body: body);
    }
    return Scaffold(
      backgroundColor: AppTokens.backgroundDark,
      body: preset == AnimationPreset.none
          ? body
          : AnimatedContentSwitcher(
              transition: AnimationTransition.fadeSize,
              alignment: Alignment.center,
              child: body,
            ),
    );
  }

  Widget _buildError(
    final BuildContext context,
    final AnimationPreset preset,
    final String message, {
    required final VoidCallback onRetry,
  }) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool useBrandedError =
        preset == AnimationPreset.normal || preset == AnimationPreset.enhanced;

    if (!useBrandedError) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(
            left: context.spacing.spaciousPadding.left,
            right: context.spacing.spaciousPadding.right,
            top: 0,
            bottom: 0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                message,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              context.spacing.sectionGap,
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.only(
          left: context.spacing.spaciousPadding.left,
          right: context.spacing.spaciousPadding.right,
          top: 0,
          bottom: 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DelayedFadeAnimation(
              delay: Duration.zero,
              child: LogoProgressIndicator(
                size: screenWidth * 0.2,
                value: 0.0,
                trackColor: Theme.of(
                  context,
                ).colorScheme.error.withOpacity(0.2),
                showPercentage: false,
              ),
            ),
            context.spacing.sectionGap,
            DelayedFadeAnimation(
              delay: const Duration(milliseconds: 200),
              child: Text(
                message,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            context.spacing.itemGap,
            DelayedFadeAnimation(
              delay: const Duration(milliseconds: 300),
              child: FilledButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplash(
    final BuildContext context,
    final double screenWidth, {
    required final AnimationPreset preset,
    required final bool animated,
  }) {
    final bool isPremium =
        preset == AnimationPreset.normal || preset == AnimationPreset.enhanced;
    if (isPremium) {
      return AnimatedSplashContent(key: _splashKey, preset: preset);
    }
    return SplashContent(
      animated: preset == AnimationPreset.reduced && animated,
    );
  }
}
