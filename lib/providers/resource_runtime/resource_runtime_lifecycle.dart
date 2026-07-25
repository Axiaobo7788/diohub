import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:flutter/widgets.dart';

/// Flutter-only adapter around the pure Dart runtime. Inactive is deliberately
/// ignored because system overlays can produce it while the app remains
/// foreground-visible.
void updateResourceRuntimeLifecycle(
  final ResourceRuntime runtime,
  final AppLifecycleState state,
) {
  switch (state) {
    case AppLifecycleState.resumed:
      runtime.updateEnvironment(const ResourceEnvironment());
    case AppLifecycleState.hidden:
      runtime.updateEnvironment(
        const ResourceEnvironment(appState: ResourceAppState.hidden),
      );
    case AppLifecycleState.paused || AppLifecycleState.detached:
      runtime.updateEnvironment(
        const ResourceEnvironment(appState: ResourceAppState.paused),
      );
    case AppLifecycleState.inactive:
      break;
  }
}
