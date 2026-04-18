import 'package:diohub/common/wrappers/logo_refresh_indicator.dart';
import 'package:flutter/material.dart';

/// A wrapper widget that provides pull-to-refresh functionality with branded DioHub logo.
///
/// This wrapper simplifies the usage by providing a consistent pull-to-refresh
/// experience across the app with the custom LogoProgressIndicator.
class PullToRefreshWrapper extends StatelessWidget {
  /// Creates a [PullToRefreshWrapper].
  ///
  /// The [onRefresh] callback must be provided and should return a [Future]
  /// that completes when the refresh operation is finished.
  ///
  /// The [child] widget should be a scrollable widget (e.g., [ListView],
  /// [GridView], [CustomScrollView], etc.).
  const PullToRefreshWrapper({
    required this.onRefresh,
    required this.child,
    super.key,
  });

  /// Callback function that is called when the user pulls to refresh.
  ///
  /// This should return a [Future] that completes when the refresh operation
  /// is finished.
  final Future<void> Function() onRefresh;

  /// The widget to wrap with pull-to-refresh functionality.
  ///
  /// This should typically be a scrollable widget.
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    return LogoRefreshIndicator(
      onRefresh: onRefresh,
      child: child,
    );
  }
}
