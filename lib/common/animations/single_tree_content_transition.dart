import 'package:diohub/common/animations/motion.dart';
import 'package:flutter/material.dart';

/// Animates only the newly mounted content tree.
///
/// Unlike [AnimatedSwitcher], the previous page/list is not retained during
/// the transition. This keeps paginated controllers, scroll listeners and
/// semantics single-owned while still giving peer destinations a short visual
/// hand-off.
class SingleTreeContentTransition extends StatelessWidget {
  const SingleTreeContentTransition({
    required this.transitionKey,
    required this.child,
    this.horizontalDirection = 0,
    super.key,
  });

  final Object transitionKey;
  final Widget child;

  /// -1 enters from the leading side, 1 from the trailing side, 0 fades only.
  final double horizontalDirection;

  @override
  Widget build(final BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    final double textDirection = Directionality.of(context) == TextDirection.rtl
        ? -1
        : 1;
    return TweenAnimationBuilder<double>(
      key: ValueKey<Object>(transitionKey),
      tween: Tween<double>(begin: 0, end: 1),
      duration: kTabTransitionDuration,
      curve: kContentTransitionCurve,
      child: child,
      builder:
          (
            final BuildContext context,
            final double value,
            final Widget? child,
          ) {
            final double opacity =
                kTabTransitionStartOpacity +
                (1 - kTabTransitionStartOpacity) * value;
            final double offset =
                (1 - value) *
                kTabTransitionOffset *
                horizontalDirection *
                textDirection;
            return ClipRect(
              child: Opacity(
                key: const ValueKey<String>('single-tree-content-opacity'),
                opacity: opacity,
                child: Transform.translate(
                  key: const ValueKey<String>(
                    'single-tree-content-translation',
                  ),
                  offset: Offset(offset, 0),
                  child: child,
                ),
              ),
            );
          },
    );
  }
}

/// Fade-only async state hand-off for sliver content.
///
/// The old loading/error/content sliver is unmounted before the new one fades
/// in, so there is never more than one real pagination subtree.
class SingleTreeSliverFadeTransition extends StatelessWidget {
  const SingleTreeSliverFadeTransition({
    required this.transitionKey,
    required this.sliver,
    super.key,
  });

  final Object transitionKey;
  final Widget sliver;

  @override
  Widget build(final BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return sliver;
    }
    return TweenAnimationBuilder<double>(
      key: ValueKey<Object>(transitionKey),
      tween: Tween<double>(begin: 0, end: 1),
      duration: kContentTransitionDuration,
      curve: kContentTransitionCurve,
      child: sliver,
      builder:
          (
            final BuildContext context,
            final double value,
            final Widget? child,
          ) => SliverOpacity(
            key: const ValueKey<String>('single-tree-sliver-opacity'),
            opacity: value,
            sliver: child,
          ),
    );
  }
}
