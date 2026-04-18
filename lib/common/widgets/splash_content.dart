import 'package:diohub/common/animations/animations.dart';
import 'package:diohub/common/const/app_info.dart';
import 'package:diohub/common/const/version_info.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// Shared splash layout: logo (20% of width), AppName (24), LoadingIndicator (20), VersionInfo.
/// Use in [LandingLoadingScreen].
class SplashContent extends StatelessWidget {
  const SplashContent({
    super.key,
    this.animated = false,
    this.message,
  });

  final bool animated;
  final String? message;

  @override
  Widget build(final BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final AppLogoWidget logo = AppLogoWidget(size: screenWidth * 0.2);
    const AppNameWidget name = AppNameWidget(size: 24);
    const LoadingIndicator indicator = LoadingIndicator(size: 20);
    const VersionInfoWidget version = VersionInfoWidget();

    Widget wrap(final Widget child, final Duration delay) {
      if (animated) {
        return DelayedFadeAnimation(delay: delay, child: child);
      }
      return child;
    }

    return Stack(
      children: <Widget>[
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              wrap(logo, const Duration(milliseconds: 100)),
              context.spacing.sectionGap,
              wrap(name, const Duration(milliseconds: 200)),
              context.spacing.spaciousGap,
              wrap(indicator, const Duration(milliseconds: 300)),
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
                  if (message != null) ...[
                    Text(
                      message!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    context.spacing.itemGap,
                  ],
                  wrap(version, const Duration(milliseconds: 400)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
