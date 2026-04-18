import 'package:diohub/providers/shorebird/shorebird_update_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

final shorebirdUpdateProvider =
    AsyncNotifierProvider<ShorebirdUpdateNotifier, ShorebirdPatchState>(
  ShorebirdUpdateNotifier.new,
);

class ShorebirdUpdateNotifier extends AsyncNotifier<ShorebirdPatchState> {
  late final ShorebirdUpdater _updater;

  @override
  Future<ShorebirdPatchState> build() async {
    _updater = ShorebirdUpdater();
    if (!_updater.isAvailable) return const PatchUnavailable();

    final UpdateStatus status = await _updater.checkForUpdate();
    return switch (status) {
      UpdateStatus.upToDate => const PatchUpToDate(),
      UpdateStatus.outdated => const PatchAvailable(),
      UpdateStatus.restartRequired => const PatchReadyToInstall(),
      UpdateStatus.unavailable => const PatchUnavailable(),
    };
  }

  /// Downloads and installs the available patch.
  Future<void> downloadAndInstall() async {
    state = const AsyncData<ShorebirdPatchState>(PatchDownloading());
    try {
      await _updater.update();
      // After update(), a restart is required for the patch to take effect.
      state = const AsyncData<ShorebirdPatchState>(PatchReadyToInstall());
    } catch (e) {
      state = AsyncData<ShorebirdPatchState>(PatchFailed(e.toString()));
    }
  }

  /// Re-check for updates (e.g. after a failure or manual refresh).
  Future<void> recheck() async {
    ref.invalidateSelf();
  }
}

/// Provider for the current patch number (if available).
///
/// Used to display patch information in the About section.
final currentPatchProvider = FutureProvider<int?>((Ref ref) async {
  final ShorebirdUpdater updater = ShorebirdUpdater();
  if (!updater.isAvailable) return null;
  final Patch? patch = await updater.readCurrentPatch();
  return patch?.number;
});
