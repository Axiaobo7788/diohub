import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/animations/animations.dart';
import 'package:diohub/providers/account/auth_provider.dart';
import 'package:diohub/providers/haptic_service_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/view/authentication/widgets/enterprise_login_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class LoginPopup extends ConsumerStatefulWidget {
  const LoginPopup({super.key});

  @override
  ConsumerState<LoginPopup> createState() => LoginPopupState();
}

class LoginPopupState extends ConsumerState<LoginPopup> {
  void _handleDeviceCodeLogin() {
    unawaited(ref.read(hapticServiceProvider).mediumImpact());
    unawaited(ref.read(authProvider.notifier).requestDeviceCode());
  }

  void _handleTokenLogin() {
    unawaited(ref.read(hapticServiceProvider).mediumImpact());
    unawaited(
      showDialog<void>(
        context: context,
        builder: (final _) => const EnterpriseLoginDialog(),
      ),
    );
  }

  void _handleReturnHome() {
    unawaited(ref.read(hapticServiceProvider).mediumImpact());
    ref.read(authProvider.notifier).reset();
    unawaited(context.router.replaceAll(<PageRouteInfo>[HomeRoute()]));
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AuthenticationState authState = ref.watch(authProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _DelayedFadeAnimation(
          child: Builder(
            builder: (final BuildContext context) {
              final bool isLoading =
                  authState is AuthenticationChecking ||
                  authState is AuthenticationAccountLinking ||
                  authState is AuthenticationInitialized;

              return _CustomLoginButton(
                onTap: _handleDeviceCodeLogin,
                icon: Octicons.mark_github,
                title: 'Sign in with GitHub',
                subtitle: 'Opens GitHub with a one-time code',
                isLoading: isLoading,
                isPrimary: true,
                colorScheme: colorScheme,
                textTheme: textTheme,
              );
            },
          ),
        ),
        context.spacing.sectionGap,
        context.spacing.tightGap,
        _DelayedFadeAnimation(
          delay: const Duration(milliseconds: 200),
          child: Center(
            child: TextButton(
              onPressed: _handleTokenLogin,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: context.spacing.sectionSpacing,
                ),
                minimumSize: const Size(44, 44),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Sign in with Token',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.muted,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
        context.spacing.tightGap,
        _DelayedFadeAnimation(
          delay: const Duration(milliseconds: 300),
          child: Center(
            child: TextButton.icon(
              onPressed: _handleReturnHome,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back to home'),
            ),
          ),
        ),
      ],
    );
  }
}

class _CustomLoginButton extends StatefulWidget {
  const _CustomLoginButton({
    required this.onTap,
    required this.icon,
    required this.title,
    required this.isPrimary,
    required this.colorScheme,
    required this.textTheme,
    this.subtitle,
    this.isLoading = false,
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
    _scaleAnimation = Tween<double>(begin: 1, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(final TapDownDetails details) {
    setState(() => _isPressed = true);
    unawaited(_scaleController.forward());
  }

  void _handleTapUp(final TapUpDetails details) {
    setState(() => _isPressed = false);
    unawaited(_scaleController.reverse());
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    unawaited(_scaleController.reverse());
  }

  @override
  Widget build(final BuildContext context) {
    final Color backgroundColor = widget.isPrimary
        ? widget.colorScheme.primary
        : widget.colorScheme.surfaceContainerHighest;
    final Color foregroundColor = widget.isPrimary
        ? widget.colorScheme.onPrimary
        : widget.colorScheme.onSurface;
    final Color borderColor = widget.isPrimary
        ? Colors.transparent
        : widget.colorScheme.outline.hinted;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (final BuildContext context, final Widget? child) =>
          Transform.scale(
            scale: _scaleAnimation.value,
            child: Material(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              elevation: widget.isPrimary ? (_isPressed ? 1 : 4) : 0,
              shadowColor: widget.isPrimary
                  ? Colors.black.withValues(alpha: _isPressed ? 0.05 : 0.15)
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 32,
                  ),
                  constraints: const BoxConstraints(minHeight: 56),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
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
                                  foregroundColor,
                                ),
                              ),
                            ),
                            context.spacing.itemGap,
                            Text(
                              'Opening GitHub...',
                              style: widget.textTheme.bodySmall?.copyWith(
                                color: foregroundColor.strong,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(widget.icon, size: 20, color: foregroundColor),
                            context.spacing.contentGap,
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  widget.title,
                                  style: widget.textTheme.titleMedium?.copyWith(
                                    color: foregroundColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (widget.subtitle != null) ...<Widget>[
                                  context.spacing.tightGap,
                                  Text(
                                    widget.subtitle!,
                                    style: widget.textTheme.bodySmall?.copyWith(
                                      color: foregroundColor.strong,
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
          ),
    );
  }
}

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
      WidgetsBinding.instance.addPostFrameCallback((final _) {
        unawaited(
          Future<void>.delayed(widget.delay, () {
            if (mounted) {
              setState(() {
                _shouldShow = true;
              });
            }
          }),
        );
      });
    }
  }

  @override
  Widget build(final BuildContext context) => AnimatedVisibility(
    visible: _shouldShow,
    transition: AnimationTransition.fade,
    child: widget.child,
  );
}
