import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Observable application state shared by foreground-only schedulers.
///
/// [ResourceRuntime] remains the owner of resource scheduling policy. This
/// adapter only exposes the same Flutter lifecycle decision to provider-owned
/// coordinators that do not run through Runtime, such as the visible
/// notifications convergence timer.
final NotifierProvider<ResourceAppLifecycleNotifier, ResourceAppState>
resourceAppLifecycleProvider =
    NotifierProvider<ResourceAppLifecycleNotifier, ResourceAppState>(
      ResourceAppLifecycleNotifier.new,
    );

final class ResourceAppLifecycleNotifier extends Notifier<ResourceAppState> {
  @override
  ResourceAppState build() => ResourceAppState.active;

  void updateFromFlutter(final AppLifecycleState lifecycleState) {
    final ResourceAppState? next = resourceAppStateForFlutterLifecycle(
      lifecycleState,
    );
    if (next != null && next != state) {
      state = next;
    }
  }
}

/// Maps Flutter lifecycle events to scheduling-relevant Runtime states.
/// Inactive is deliberately ignored because system overlays can produce it
/// while the application remains foreground-visible.
ResourceAppState? resourceAppStateForFlutterLifecycle(
  final AppLifecycleState state,
) => switch (state) {
  AppLifecycleState.resumed => ResourceAppState.active,
  AppLifecycleState.hidden => ResourceAppState.hidden,
  AppLifecycleState.paused ||
  AppLifecycleState.detached => ResourceAppState.paused,
  AppLifecycleState.inactive => null,
};

/// Flutter-only adapter around the pure Dart runtime. Inactive is deliberately
/// ignored because system overlays can produce it while the app remains
/// foreground-visible.
void updateResourceRuntimeLifecycle(
  final ResourceRuntime runtime,
  final AppLifecycleState state,
) {
  final ResourceAppState? appState = resourceAppStateForFlutterLifecycle(state);
  if (appState != null) {
    runtime.updateEnvironment(ResourceEnvironment(appState: appState));
  }
}
