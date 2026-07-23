import 'package:flutter/widgets.dart';

/// Applies DioHub's animation preference without overriding a platform-level
/// Reduced Motion request already exposed through [MediaQuery].
class AppMotionMediaQuery extends StatelessWidget {
  const AppMotionMediaQuery({
    required this.appAnimationsDisabled,
    required this.child,
    super.key,
  });

  final bool appAnimationsDisabled;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    final MediaQueryData platformData = MediaQuery.of(context);
    final bool disableAnimations =
        appAnimationsDisabled || platformData.disableAnimations;
    return MediaQuery(
      data: platformData.copyWith(disableAnimations: disableAnimations),
      child: child,
    );
  }
}
