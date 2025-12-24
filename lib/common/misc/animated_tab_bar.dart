import 'package:diohub/common/misc/scroll_dynamic_elevation.dart';
import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// A widget that animates a tab bar in and out, with default padding when hidden.
///
/// When the tab bar is not visible, it provides default padding to maintain spacing.
/// This ensures consistent layout whether the tab bar is shown or hidden.
///
/// Example usage:
/// ```dart
/// AnimatedTabBar(
///   showTabBar: tabController.activeLength > 1,
///   tabBar: tabs,
///   defaultPadding: const EdgeInsets.only(bottom: 8),
/// )
/// ```
class AnimatedTabBar extends StatelessWidget {
  const AnimatedTabBar({
    required this.showTabBar,
    required this.tabBar,
    super.key, 
  });

  /// Whether to show the tab bar
  final bool showTabBar;

  /// The tab bar widget to animate
  final Widget tabBar;

  /// Default padding to show when tab bar is hidden
  // final EdgeInsets defaultPadding;


  @override
  Widget build(final BuildContext context) => SliverPinnedHeader(
    child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (final Widget child, final Animation<double> animation) => SizeTransition(
            sizeFactor: animation,
            child: child,
          ),
        child: showTabBar
            ? ScrollDynamicElevation(
              child: SizedBox(
                  key: const ValueKey('tabBar'),
                  child: 
                    SizedBox(
                      width: double.infinity,
                      child: tabBar,
                    ),
                  
                ),
            )
            : const SizedBox.shrink(),
      ),
  );
}

