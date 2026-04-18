import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/overlay/modal_barrier_style.dart';
import 'package:diohub/common/popup/popup_button.dart' show PopupButton;
import 'package:diohub/common/popup/popup_menu.dart';
import 'package:diohub/providers/haptic_service_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:diohub/common/popup/popup_menu.dart' show PopupActionLayout;

/// Shows a popup menu at a specific location
///
/// This is a helper function for showing popups programmatically
/// without needing a PopupButton widget.
///
/// For most cases, prefer using [PopupButton] instead.
///
/// Either [actions] or [popupBuilder] must be provided. When [popupBuilder]
/// is provided, it supplies the popup content and [actions] is ignored.
Future<void> showPopupMenu(
  final BuildContext context, {
  final List<ActionButtonData>? actions,
  final Widget Function(BuildContext context, VoidCallback onDismiss)?
      popupBuilder,
  final Rect? anchorRect,
  final String? title,
  final String? subtitle,
  final double? maxHeight,
  final PopupActionLayout actionLayout = PopupActionLayout.list,
}) async {
  assert(
    actions != null || popupBuilder != null,
    'Either actions or popupBuilder must be provided',
  );
  await ProviderScope.containerOf(context)
      .read(hapticServiceProvider)
      .lightImpact();
  if (!context.mounted) return;

  // Calculate anchor position
  final RenderBox? overlay =
      Overlay.of(context).context.findRenderObject() as RenderBox?;
  if (overlay == null) return;

  final Rect effectiveAnchorRect = anchorRect ??
      Rect.fromLTWH(
        overlay.size.width / 2,
        overlay.size.height / 2,
        0,
        0,
      );

  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: modalBarrierColor(context),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (final BuildContext context, final Animation<double> animation,
            final Animation<double> secondaryAnimation) =>
        _PopupMenuDialog(
      anchorRect: effectiveAnchorRect,
      animation: animation,
      actions: actions,
      popupBuilder: popupBuilder,
      title: title,
      subtitle: subtitle,
      maxHeight: maxHeight,
      actionLayout: actionLayout,
    ),
  );
}

class _PopupMenuDialog extends StatelessWidget {
  const _PopupMenuDialog({
    required this.anchorRect,
    required this.animation,
    required this.actionLayout,
    this.actions,
    this.popupBuilder,
    this.title,
    this.subtitle,
    this.maxHeight,
  });

  final Rect anchorRect;
  final Animation<double> animation;
  final List<ActionButtonData>? actions;
  final Widget Function(BuildContext context, VoidCallback onDismiss)?
      popupBuilder;
  final PopupActionLayout actionLayout;
  final String? title;
  final String? subtitle;
  final double? maxHeight;

  @override
  Widget build(final BuildContext context) {
    final Animation<double> scaleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: kPopupCurveIn,
        reverseCurve: kPopupCurveOut,
      ),
    );

    final VoidCallback onDismiss = () => Navigator.of(context).pop();
    final Widget menuChild = ScaleTransition(
      scale: scaleAnimation,
      alignment: Alignment.topCenter,
      child: Material(
        type: MaterialType.transparency,
        child: popupBuilder?.call(context, onDismiss) ??
            PopupMenu(
              actions: actions!,
              title: title,
              subtitle: subtitle,
              maxHeight: maxHeight,
              actionLayout: actionLayout,
              onDismiss: onDismiss,
            ),
      ),
    );

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: CustomSingleChildLayout(
            delegate: PopupLayoutDelegate(anchorRect: anchorRect),
            child: menuChild,
          ),
        ),
      ],
    );
  }
}

/// Positions the popup menu so its horizontal center aligns with the anchor's
/// center and its top is just below the anchor, clamped to stay on screen.
///
/// Shared by [showPopupMenu] and entity info popup so all anchored popups
/// use the same layout logic.
class PopupLayoutDelegate extends SingleChildLayoutDelegate {
  PopupLayoutDelegate({required this.anchorRect});

  final Rect anchorRect;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints.loose(constraints.biggest);
  }

  @override
  Offset getPositionForChild(final Size size, final Size childSize) {
    final double left = (anchorRect.center.dx - childSize.width / 2)
        .clamp(0.0, size.width - childSize.width);
    final double top =
        (anchorRect.bottom + 8).clamp(0.0, size.height - childSize.height);
    return Offset(left, top);
  }

  @override
  bool shouldRelayout(covariant final PopupLayoutDelegate oldDelegate) =>
      oldDelegate.anchorRect != anchorRect;
}
