import 'package:flutter/material.dart';

/// Exposes the shell's paginated-refresh state to descendants.
///
/// Position bodies (e.g. paginated list) set [value] true on refresh start
/// and false on end; the app bar uses it to show a pulse. Only [NavCenterShell]
/// provides this scope.
class NavCenterRefreshScope extends InheritedNotifier<ValueNotifier<bool>> {
  const NavCenterRefreshScope({
    required super.notifier,
    required super.child,
    super.key,
  });

  /// The [ValueNotifier<bool>] for refresh state, or null if no [NavCenterRefreshScope]
  /// is above [context] (e.g. outside NavCenterShell).
  static ValueNotifier<bool>? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<NavCenterRefreshScope>()
        ?.notifier;
  }
}
