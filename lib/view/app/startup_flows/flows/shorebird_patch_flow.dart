import 'package:diohub/providers/shorebird/shorebird_update_provider.dart';
import 'package:diohub/providers/startup_flows/startup_flow.dart';
import 'package:diohub/view/app/startup_flows/widgets/shorebird_patch_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// Prompted flow: Shows banner when OTA patch is available or ready to install.
///
/// This flow checks for Shorebird patches and displays a banner prompting the
/// user to download or restart to apply updates.
class ShorebirdPatchFlow extends StartupFlow {
  @override
  String get id => 'shorebird_patch';

  @override
  int get priority => 5;

  @override
  FlowTier get tier => FlowTier.prompted;

  @override
  Future<bool> shouldShow(ProviderContainer container) async {
    final ShorebirdUpdater updater = ShorebirdUpdater();
    if (!updater.isAvailable) return false;
    final UpdateStatus status = await updater.checkForUpdate();
    // Show banner when patch is downloaded and waiting for restart,
    // OR when a new patch is available to download.
    return status == UpdateStatus.restartRequired ||
        status == UpdateStatus.outdated;
  }

  @override
  Widget? buildBanner(
    BuildContext context, {
    required VoidCallback onDismiss,
    required VoidCallback onAction,
  }) {
    // Uses a custom banner with the LogoProgressIndicator as the leading icon
    return ShorebirdPatchBanner(
      onDismiss: onDismiss,
      onAction: onAction,
    );
  }

  @override
  Future<void> markHandled(ProviderContainer container) async {
    // No persistent dismissal needed - flow will re-evaluate on next startup
  }
}
