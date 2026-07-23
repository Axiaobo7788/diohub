import 'package:diohub/common/animations/motion.dart';
import 'package:flutter/material.dart';

/// Shared transition for migrated MD3 routes.
///
/// The page shell is mounted immediately. Reduced Motion removes the spatial
/// transition without changing navigation timing or route semantics.
Widget buildAppPageTransition(
  final BuildContext context,
  final Animation<double> animation,
  final Animation<double> secondaryAnimation,
  final Widget child,
) {
  if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
    return child;
  }

  final Animation<double> curved = CurvedAnimation(
    parent: animation,
    curve: kPageTransitionCurve,
    reverseCurve: kPageTransitionReverseCurve,
  );
  final double direction = Directionality.maybeOf(context) == TextDirection.rtl
      ? -1
      : 1;
  return LayoutBuilder(
    builder: (final BuildContext context, final BoxConstraints constraints) {
      final double width =
          constraints.hasBoundedWidth && constraints.maxWidth > 0
          ? constraints.maxWidth
          : MediaQuery.sizeOf(context).width;
      final double fractionalOffset = width > 0
          ? kPageTransitionOffset / width
          : 0;
      return FadeTransition(
        key: const ValueKey<String>('app-page-fade-transition'),
        opacity: curved,
        child: SlideTransition(
          key: const ValueKey<String>('app-page-slide-transition'),
          position: Tween<Offset>(
            begin: Offset(fractionalOffset * direction, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
