/// States for the Shorebird patch update lifecycle.
///
/// Used to track the current status of OTA patch availability and installation.
sealed class ShorebirdPatchState {
  const ShorebirdPatchState();
}

/// Updater not available (debug build, non-Shorebird binary).
class PatchUnavailable extends ShorebirdPatchState {
  const PatchUnavailable();
}

/// No update needed - app is running the latest patch.
class PatchUpToDate extends ShorebirdPatchState {
  const PatchUpToDate();
}

/// A new patch is available on the server, not yet downloaded.
class PatchAvailable extends ShorebirdPatchState {
  const PatchAvailable();
}

/// Patch is being downloaded/applied.
class PatchDownloading extends ShorebirdPatchState {
  const PatchDownloading();
}

/// Patch downloaded, restart required to activate.
class PatchReadyToInstall extends ShorebirdPatchState {
  const PatchReadyToInstall();
}

/// Download or install failed.
class PatchFailed extends ShorebirdPatchState {
  const PatchFailed(this.message);

  final String message;
}
