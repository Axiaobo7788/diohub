import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/animations/animations.dart';
import 'package:diohub/common/const/app_info.dart';
import 'package:diohub/common/const/version_info.dart';
import 'package:diohub/providers/account/auth_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/view/authentication/widgets/auth_flow_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@RoutePage()
class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    ref.listen<AuthenticationState>(authProvider, (
      final AuthenticationState? previous,
      final AuthenticationState next,
    ) {
      if (previous is AuthenticationAccountLinking &&
          next is AuthenticationUnauthenticated) {
        unawaited(context.router.maybePop());
      }
    });

    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(height: screenHeight * 0.1),
                      DelayedFadeAnimation(
                        delay: const Duration(milliseconds: 100),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Center(
                              child: AppLogoWidget(size: screenWidth * 0.25),
                            ),
                            context.spacing.sectionGap,
                            const DelayedFadeAnimation(
                              delay: Duration(milliseconds: 200),
                              child: Center(child: AppNameWidget(size: 28)),
                            ),
                            context.spacing.itemGap,
                            DelayedFadeAnimation(
                              delay: const Duration(milliseconds: 300),
                              child: Center(
                                child: Text(
                                  'Sign in to continue',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface.secondary,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.08),
                      const DelayedFadeAnimation(
                        delay: Duration(milliseconds: 400),
                        child: AuthFlowContent(),
                      ),
                      SizedBox(height: screenHeight * 0.1),
                    ],
                  ),
                ),
              ),
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: VersionInfoWidget(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
