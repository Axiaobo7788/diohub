/// Mutation to resolve a secret scanning alert.
/// Patches [patchedSecretScanningAlertsProvider] on success (no ref.invalidate).
library;

import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/riverpod/mutation_state.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/secret_scanning_alert.dart';
import 'package:diohub/providers/repository/patched_secret_scanning_alerts_provider.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/providers/database_providers.dart';

typedef ResolveSecretScanningAlertKey = ({RepoRef repo, int alertNumber});

class ResolveSecretScanningAlertMutationNotifier
    extends Notifier<MutationState<void>> with MutationNotifierMixin<void> {
  ResolveSecretScanningAlertMutationNotifier(this._key);

  final ResolveSecretScanningAlertKey _key;

  RepoRef get _repoRef => _key.repo;
  int get _alertNumber => _key.alertNumber;

  @override
  MutationState<void> build() {
    initMutationDisposal();
    return MutationState.idle();
  }

  Future<void> resolve({
    required String resolution,
    String? resolutionComment,
  }) async {
    if (state is MutationLoading<void>) return;
    state = MutationState.loading();
    try {
      final SecretScanningAlert? result =
          await _repoRef.services(ref.read(apiClientProvider)).updateSecretScanningAlert(
        number: _alertNumber,
        state: 'resolved',
        resolution: resolution,
        resolutionComment: resolutionComment,
      );
      if (result != null) {
        ref.read(patchedSecretScanningAlertsProvider(_repoRef).notifier).patch(
              SecretScanningAlertResolvedPatch(
                number: result.number,
                state: result.state,
                resolvedAt: result.resolvedAt,
                resolution: result.resolution,
                resolutionComment: result.resolutionComment,
              ),
            );
      }
      state = MutationState.success(null);
      scheduleReset();
    } catch (e, st) {
      AppLogger.warning(
        'Resolve secret scanning alert failed',
        error: e,
        stackTrace: st,
        tag: 'ResolveSecretScanningAlert',
      );
      state = MutationState.error(e, st);
      scheduleReset();
    }
  }
}

/// Resolve secret scanning alert mutation. Auto-disposes when no longer watched.
final resolveSecretScanningAlertMutationProvider = NotifierProvider.autoDispose
    .family<ResolveSecretScanningAlertMutationNotifier, MutationState<void>,
            ResolveSecretScanningAlertKey>(
        ResolveSecretScanningAlertMutationNotifier.new);
