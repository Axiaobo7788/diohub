import 'package:auto_route/auto_route.dart';
import 'package:diohub/blocs/account_bloc/account_bloc.dart';
import 'package:diohub/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:diohub/common/animations/fade_animation_widget.dart';
import 'package:diohub/common/const/app_info.dart';
import 'package:diohub/common/const/version_info.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/view/authentication/widgets/code_info_box.dart';
import 'package:diohub/view/authentication/widgets/error_popup.dart';
import 'package:diohub/view/authentication/widgets/login_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key, this.onAuthenticated});
  final VoidCallback? onAuthenticated;

  @override
  Widget build(final BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            // Main content
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(height: screenHeight * 0.1),
                      // Logo and app name section with staggered animations
                      _DelayedFadeAnimation(
                        delay: const Duration(milliseconds: 100),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Center(
                              child: AppLogoWidget(
                                size: screenWidth * 0.25,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _DelayedFadeAnimation(
                              delay: const Duration(milliseconds: 200),
                              child: const Center(
                                child: AppNameWidget(
                                  size: 28,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _DelayedFadeAnimation(
                              delay: const Duration(milliseconds: 300),
                              child: Center(
                                child: Text(
                                  'Sign in to continue',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.7),
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.08),
                      // Login options with fade slide animation
                      // Listen to AccountBloc for callback invocation
                      BlocListener<AccountBloc, AccountState>(
                        listenWhen: (previous, current) =>
                            current is AccountReady &&
                            current.activeAccount != null,
                        listener: (context, state) {
                          // Invoke callback when account is ready and active
                          if (onAuthenticated != null) {
                            // Callback handles navigation (e.g., replaceAll to LandingLoadingRoute)
                            onAuthenticated!();
                          } else {
                            // No callback provided (add-account flow) - pop this screen
                            Navigator.of(context).pop();
                          }
                        },
                        child: BlocBuilder<AuthenticationBloc,
                            AuthenticationState>(
                          builder: (
                            final BuildContext context,
                            final AuthenticationState state,
                          ) {
                            if (state is AuthenticationUnauthenticated) {
                              return _DelayedFadeAnimation(
                                delay: const Duration(milliseconds: 400),
                                child: const LoginPopup(),
                              );
                            } else if (state is AuthenticationChecking ||
                                state is AuthenticationAccountLinking) {
                              return const LoadingIndicator();
                            } else if (state is AuthenticationInitialized) {
                              return _DelayedFadeAnimation(
                                delay: const Duration(milliseconds: 100),
                                child: CodeInfoBox(state.deviceCodeModel),
                              );
                            } else if (state is AuthenticationError) {
                              return _DelayedFadeAnimation(
                                delay: const Duration(milliseconds: 100),
                                child: ErrorPopup(state.error),
                              );
                            }
                            return Container();
                          },
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.1),
                    ],
                  ),
                ),
              ),
            ),
            // Version info at bottom
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

/// Wrapper widget that adds delay to FadeAnimationSection
class _DelayedFadeAnimation extends StatefulWidget {
  const _DelayedFadeAnimation({
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  State<_DelayedFadeAnimation> createState() => _DelayedFadeAnimationState();
}

class _DelayedFadeAnimationState extends State<_DelayedFadeAnimation> {
  bool _shouldShow = false;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _shouldShow = true;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(widget.delay, () {
          if (mounted) {
            setState(() {
              _shouldShow = true;
            });
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeAnimationSection(
      expand: _shouldShow,
      child: widget.child,
    );
  }
}
