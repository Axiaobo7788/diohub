import 'package:diohub/common/anchor_overlay/anchor_overlay.dart';
import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/overlay/modal_barrier_style.dart';
import 'package:diohub/common/popup/popup_controller.dart';
import 'package:diohub/common/popup/popup_menu.dart';
import 'package:diohub/providers/haptic_service_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_anchor/flutter_anchor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A button that shows a popup menu when tapped
///
/// Supports both action-based menus and custom content via builder.
/// Uses flutter_anchor for intelligent positioning.
class PopupButton extends StatefulWidget {
  const PopupButton({
    required this.buttonBuilder,
    this.animatedButtonBuilder,
    this.actions,
    this.popupBuilder,
    this.title,
    this.subtitle,
    this.controller,
    this.placement = Placement.bottom,
    this.spacing = 8.0,
    this.barrierDismissible = true,
    this.barrierColor,
    this.onOpen,
    this.onClose,
    super.key,
  }) : assert(
          actions != null || popupBuilder != null,
          'Either actions or popupBuilder must be provided',
        );

  /// Builder for the trigger button
  /// Receives the context and a callback to show the menu
  final Widget Function(BuildContext context, VoidCallback showMenu)
      buttonBuilder;

  /// Optional builder that receives [isOpen] so the trigger can animate
  /// (e.g. [AnimatedMenuIcon]). When provided, takes precedence over [buttonBuilder].
  final Widget Function(
    BuildContext context,
    VoidCallback showMenu,
    bool isOpen,
  )? animatedButtonBuilder;

  /// Optional list of actions to display in the popup
  /// If provided, a PopupMenu will be automatically created
  final List<ActionButtonData>? actions;

  /// Optional custom content builder.
  /// Receives [context] and [onDismiss] to close the popup (e.g. pass to EntityPopupMenu).
  final Widget Function(BuildContext context, VoidCallback onDismiss)?
      popupBuilder;

  /// Optional title displayed in the popup header
  final String? title;

  /// Optional subtitle displayed in the popup header
  final String? subtitle;

  /// Optional external controller for programmatic control
  final PopupController? controller;

  /// Placement of the popup relative to the button
  final Placement placement;

  /// Spacing between button and popup
  final double spacing;

  /// Whether tapping outside the popup dismisses it
  final bool barrierDismissible;

  /// Color of the modal barrier
  /// If null, uses a semi-transparent black
  final Color? barrierColor;

  /// Callback when popup opens
  final VoidCallback? onOpen;

  /// Callback when popup closes
  final VoidCallback? onClose;

  @override
  State<PopupButton> createState() => _PopupButtonState();
}

class _PopupButtonState extends State<PopupButton> {
  late final PopupController _internalController;
  late final AnchorController _anchorController;
  PopupController get _controller => widget.controller ?? _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = PopupController();
    _anchorController = AnchorController();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(final PopupButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      (oldWidget.controller ?? _internalController)
          .removeListener(_onControllerChanged);
      _controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _internalController.dispose();
    _anchorController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
    if (_controller.isOpen) {
      _anchorController.show();
      widget.onOpen?.call();
    } else {
      _anchorController.hide();
      widget.onClose?.call();
    }
  }

  void _handleTap() {
    ProviderScope.containerOf(context)
        .read(hapticServiceProvider)
        .lightImpact();
    _controller.toggle();
  }

  @override
  Widget build(final BuildContext context) {
    final EdgeInsets viewPadding = MediaQuery.viewPaddingOf(context);
    final EdgeInsets viewInsets = MediaQuery.viewInsetsOf(context);
    final EdgeInsets padding = viewPadding + viewInsets;

    return Anchor(
      controller: _anchorController,
      triggerMode: const AnchorTriggerMode.manual(),
      placement: widget.placement,
      spacing: widget.spacing,
      viewPadding: padding,
      transitionDuration: kPopupDuration,
      transitionBuilder: (final BuildContext context,
              final Animation<double> animation, final Widget? child) =>
          AnchorScaleTransition(
        placement: widget.placement,
        animation: animation,
        child: child ?? const SizedBox.shrink(),
      ),
      onShow: widget.onOpen,
      onHide: () {
        if (_controller.isOpen) {
          _controller.close();
        }
        widget.onClose?.call();
      },
      backdropBuilder: widget.barrierDismissible
          ? (final BuildContext context) => AnchorBarrier(
                onDismiss: () => _controller.close(),
                color: widget.barrierColor ?? modalBarrierColor(context),
              )
          : null,
      overlayBuilder: (final BuildContext context) {
        void onDismiss() => _controller.close();
        return Material(
          type: MaterialType.transparency,
          child: widget.popupBuilder?.call(context, onDismiss) ??
              PopupMenu(
                actions: widget.actions!,
                title: widget.title,
                subtitle: widget.subtitle,
                onDismiss: onDismiss,
              ),
        );
      },
      child: widget.animatedButtonBuilder?.call(
            context,
            _handleTap,
            _controller.isOpen,
          ) ??
          widget.buttonBuilder(context, _handleTap),
    );
  }
}
