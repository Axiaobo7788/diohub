/// Client-side patches for secret scanning alerts so resolve mutation can
/// update the card without ref.invalidate.
library;

import 'package:flutter/foundation.dart';

import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/secret_scanning_alert.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class SecretScanningAlertResolvedPatch {
  const SecretScanningAlertResolvedPatch({
    required this.number,
    required this.state,
    this.resolvedAt,
    this.resolution,
    this.resolutionComment,
  });

  final int number;
  final String state;
  final DateTime? resolvedAt;
  final String? resolution;
  final String? resolutionComment;
}

class PatchedSecretScanningAlertsNotifier
    extends Notifier<Map<int, SecretScanningAlertResolvedPatch>> {
  PatchedSecretScanningAlertsNotifier(RepoRef repoRef) : _repoRef = repoRef;

  // ignore: unused_field - family key, state is per-repo
  final RepoRef _repoRef;

  @override
  Map<int, SecretScanningAlertResolvedPatch> build() => {};

  void patch(SecretScanningAlertResolvedPatch p) {
    state = Map<int, SecretScanningAlertResolvedPatch>.from(state)
      ..[p.number] = p;
  }
}

/// Patched secret scanning alerts per repo. Auto-disposes when no longer watched.
final patchedSecretScanningAlertsProvider = NotifierProvider.autoDispose.family<
    PatchedSecretScanningAlertsNotifier,
    Map<int, SecretScanningAlertResolvedPatch>,
    RepoRef>(PatchedSecretScanningAlertsNotifier.new);

SecretScanningAlert mergePatchedSecretScanningAlert(
  SecretScanningAlert base,
  Map<int, SecretScanningAlertResolvedPatch> patched,
) {
  final p = patched[base.number];
  if (p == null) return base;
  return base.copyWith(
    state: p.state,
    resolvedAt: p.resolvedAt,
    resolution: p.resolution,
    resolutionComment: p.resolutionComment,
  );
}
