import 'package:diohub/common/animations/motion.dart';
import 'package:flutter/material.dart';

/// Adds restrained directional motion around the retained Repository tab
/// stack without replacing or rebuilding the selected page.
class RepositoryRetainedTabTransition extends StatelessWidget {
  const RepositoryRetainedTabTransition({
    required this.animation,
    required this.direction,
    required this.child,
    super.key,
  });

  final Animation<double> animation;

  /// Positive when a later tab enters, negative when an earlier tab enters.
  final int direction;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return child;
    }
    final double textDirection =
        Directionality.maybeOf(context) == TextDirection.rtl ? -1 : 1;
    final Animation<double> curved = CurvedAnimation(
      parent: animation,
      curve: kContentTransitionCurve,
    );
    return AnimatedBuilder(
      key: const ValueKey<String>('repository-tab-transition'),
      animation: curved,
      child: child,
      builder: (final BuildContext context, final Widget? child) {
        final double progress = curved.value;
        return Opacity(
          opacity:
              kTabTransitionStartOpacity +
              ((1 - kTabTransitionStartOpacity) * progress),
          child: Transform.translate(
            offset: Offset(
              kTabTransitionOffset *
                  direction.sign *
                  textDirection *
                  (1 - progress),
              0,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
