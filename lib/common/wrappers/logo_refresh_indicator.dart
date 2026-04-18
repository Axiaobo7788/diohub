import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:diohub/common/animations/logo_progress_indicator.dart';
import 'package:flutter/material.dart';

/// A custom refresh indicator that uses the DioHub logo.
///
/// The logo ring fills as the user pulls down (determinate progress mapped to
/// pull distance), switches to indeterminate spin when refreshing, and plays a
/// burst animation on completion.
class LogoRefreshIndicator extends StatelessWidget {
  const LogoRefreshIndicator({
    required this.child,
    required this.onRefresh,
    super.key,
  });

  final Widget child;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: onRefresh,
      builder: (context, child, controller) {
        return Stack(
          children: [
            Transform.translate(
              offset: Offset(0, controller.value * 100),
              child: child,
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: controller.value * 100,
                child: Center(
                  child: LogoProgressIndicator(
                    size: 32,
                    value: controller.state.isLoading
                        ? null
                        : controller.value.clamp(0.0, 1.0),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: child,
    );
  }
}
