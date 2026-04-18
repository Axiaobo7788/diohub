import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class PremiumLifecycle {
  const PremiumLifecycle();

  Future<void> initialize(ProviderContainer container) async {}

  bool get isPremiumAvailable => false;

  Widget buildAppOverlay(
    BuildContext context,
    WidgetRef ref, {
    required Widget child,
  }) => child;

  Future<void> initializeDownloadManager(WidgetRef ref) async {}

  Widget cloudSyncObserverWrapper(Widget child) => child;
}

class DefaultPremiumLifecycle extends PremiumLifecycle {
  const DefaultPremiumLifecycle();
}

final premiumLifecycleProvider = Provider<PremiumLifecycle>((ref) {
  return const DefaultPremiumLifecycle();
});
