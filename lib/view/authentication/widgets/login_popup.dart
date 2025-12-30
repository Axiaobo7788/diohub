import 'package:diohub/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:diohub/common/animations/fade_animation_widget.dart';
import 'package:diohub/models/authentication/access_token_model.dart';
import 'package:diohub/services/authentication/auth_service.dart';
// import 'package:diohub/view/authentication/widgets/enterprise_login_dialog.dart'; // Hidden for now
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class LoginPopup extends StatefulWidget {
  const LoginPopup({super.key});

  @override
  LoginPopupState createState() => LoginPopupState();
}

class LoginPopupState extends State<LoginPopup> {
  bool _loading = false;

  Future<void> _handleBrowserLogin() async {
    try {
      setState(() {
        _loading = true;
      });
      await AuthRepository().oauth2().then(
            (final AccessTokenModel value) =>
                BlocProvider.of<AuthenticationBloc>(context).add(
              AuthSuccessful(value),
            ),
          );
    } on Exception catch (e) {
      if (mounted) {
        BlocProvider.of<AuthenticationBloc>(context)
            .add(AuthError(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _handleDeviceCodeLogin() {
    BlocProvider.of<AuthenticationBloc>(context).add(RequestDeviceCode());
  }

  // Hidden for now
  // void _handleEnterpriseLogin() {
  //   showDialog(
  //     context: context,
  //     builder: (final _) => const EnterpriseLoginDialog(),
  //   );
  // }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Primary login button - defaults to OAuth
        _DelayedFadeAnimation(
          delay: const Duration(milliseconds: 0),
          child: _CustomLoginButton(
            onTap: _handleBrowserLogin,
            icon: Octicons.mark_github,
            title: 'Sign in with GitHub',
            isLoading: _loading,
            isPrimary: true,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        ),
        const SizedBox(height: 16),
        // Divider with text
        _DelayedFadeAnimation(
          delay: const Duration(milliseconds: 100),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Divider(
                  color: colorScheme.outline.withOpacity(0.2),
                  height: 1,
                  thickness: 0.5,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'or',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: colorScheme.outline.withOpacity(0.2),
                  height: 1,
                  thickness: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Secondary option - Device Code (less prominent, fallback)
        _DelayedFadeAnimation(
          delay: const Duration(milliseconds: 200),
          child: BlocBuilder<AuthenticationBloc, AuthenticationState>(
            builder: (context, state) {
              final bool isLoading = state is AuthenticationChecking ||
                  state is AuthenticationAccountLinking ||
                  state is AuthenticationInitialized;

              return Center(
                child: TextButton(
                  onPressed: isLoading ? null : _handleDeviceCodeLogin,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    minimumSize: const Size(44, 44), // Minimum touch target
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        )
                      : Text(
                          'Use one-time code',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 13,
                          ),
                        ),
                ),
              );
            },
          ),
        ),
        // Hidden for now
        // const SizedBox(height: 4),
        // // Divider with text
        // Row(
        //   children: <Widget>[
        //     Expanded(
        //       child: Divider(
        //         color: colorScheme.outline.withOpacity(0.2),
        //         height: 1,
        //         thickness: 0.5,
        //       ),
        //     ),
        //     Padding(
        //       padding: const EdgeInsets.symmetric(horizontal: 16),
        //       child: Text(
        //         'or',
        //         style: textTheme.bodySmall?.copyWith(
        //           color: colorScheme.onSurface.withOpacity(0.5),
        //           fontSize: 12,
        //         ),
        //       ),
        //     ),
        //     Expanded(
        //       child: Divider(
        //         color: colorScheme.outline.withOpacity(0.2),
        //         height: 1,
        //         thickness: 0.5,
        //       ),
        //     ),
        //   ],
        // ),
        // const SizedBox(height: 20),
        // // Enterprise login - less prominent
        // Center(
        //   child: TextButton(
        //     onPressed: _handleEnterpriseLogin,
        //     style: TextButton.styleFrom(
        //       padding:
        //           const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        //       minimumSize: const Size(44, 44), // Minimum touch target
        //       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        //     ),
        //     child: Text(
        //       'Enterprise Server',
        //       style: textTheme.bodySmall?.copyWith(
        //         color: colorScheme.onSurface.withOpacity(0.6),
        //         fontSize: 13,
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }
}

class _CustomLoginButton extends StatefulWidget {
  const _CustomLoginButton({
    required this.onTap,
    required this.icon,
    required this.title,
    this.subtitle,
    this.isLoading = false,
    required this.isPrimary,
    required this.colorScheme,
    required this.textTheme,
  });

  final VoidCallback onTap;
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isLoading;
  final bool isPrimary;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  State<_CustomLoginButton> createState() => _CustomLoginButtonState();
}

class _CustomLoginButtonState extends State<_CustomLoginButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = widget.isPrimary
        ? widget.colorScheme.primary
        : widget.colorScheme.surfaceContainerHighest;
    final Color foregroundColor = widget.isPrimary
        ? widget.colorScheme.onPrimary
        : widget.colorScheme.onSurface;
    final Color borderColor = widget.isPrimary
        ? Colors.transparent
        : widget.colorScheme.outline.withOpacity(0.5);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Material(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            elevation: widget.isPrimary ? (_isPressed ? 1 : 4) : 0,
            shadowColor: widget.isPrimary
                ? Colors.black.withOpacity(_isPressed ? 0.05 : 0.15)
                : Colors.transparent,
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onTap,
              onTapDown: widget.isLoading ? null : _handleTapDown,
              onTapUp: widget.isLoading ? null : _handleTapUp,
              onTapCancel: widget.isLoading ? null : _handleTapCancel,
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
                constraints: const BoxConstraints(
                  minHeight: 56, // Material Design minimum touch target
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: borderColor,
                    width: 1,
                  ),
                ),
                child: widget.isLoading
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  foregroundColor),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Opening GitHub...',
                            style: widget.textTheme.bodySmall?.copyWith(
                              color: foregroundColor.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            widget.icon,
                            size: 20,
                            color: foregroundColor,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                widget.title,
                                style: widget.textTheme.titleMedium?.copyWith(
                                  color: foregroundColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (widget.subtitle != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  widget.subtitle!,
                                  style: widget.textTheme.bodySmall?.copyWith(
                                    color: foregroundColor.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
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
