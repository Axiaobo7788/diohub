import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/providers/resource_runtime/resource_runtime_lifecycle.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('application lifecycle exposes only scheduling-relevant states', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final ResourceAppLifecycleNotifier notifier = container.read(
      resourceAppLifecycleProvider.notifier,
    );

    expect(
      container.read(resourceAppLifecycleProvider),
      ResourceAppState.active,
    );

    notifier.updateFromFlutter(AppLifecycleState.inactive);
    expect(
      container.read(resourceAppLifecycleProvider),
      ResourceAppState.active,
      reason: 'temporary platform overlays must not pause foreground work',
    );

    notifier.updateFromFlutter(AppLifecycleState.hidden);
    expect(
      container.read(resourceAppLifecycleProvider),
      ResourceAppState.hidden,
    );

    notifier.updateFromFlutter(AppLifecycleState.detached);
    expect(
      container.read(resourceAppLifecycleProvider),
      ResourceAppState.paused,
    );

    notifier.updateFromFlutter(AppLifecycleState.resumed);
    expect(
      container.read(resourceAppLifecycleProvider),
      ResourceAppState.active,
    );
  });
}
