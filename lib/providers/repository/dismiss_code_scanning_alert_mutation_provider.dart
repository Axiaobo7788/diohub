/// Mutation to dismiss a code scanning alert. Refreshes the security position on success.
library;

import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/riverpod/mutation_state.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/repository/security_refresh_trigger_provider.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef DismissCodeScanningAlertKey = ({RepoRef repo, int alertNumber});

class DismissCodeScanningAlertMutationNotifier
    extends Notifier<MutationState<void>> with MutationNotifierMixin<void> {
  DismissCodeScanningAlertMutationNotifier(this._key);

  final DismissCodeScanningAlertKey _key;

  RepoRef get _repoRef => _key.repo;
  int get _alertNumber => _key.alertNumber;

  @override
  MutationState<void> build() {
    initMutationDisposal();
    return MutationState.idle();
  }

  Future<void> dismiss({
    required String reason,
    String? comment,
  }) async {
    if (state is MutationLoading<void>) return;
    state = MutationState.loading();
    try {
      await ref.read(dismissCodeScanningAlertMutationProvider((
        repo: _repoRef,
        alertNumber: _alertNumber,
      )).notifier).dismiss(reason: reason, comment: comment);
      ref.read(securityRefreshTriggerProvider(_repoRef)).value++;
      state = const MutationState.success(null);
      scheduleReset();
    } catch (e, st) {
      AppLogger.warning(
        'Dismiss code scanning alert failed',
        error: e,
        stackTrace: st,
        tag: 'DismissCodeScanningAlert',
      );
      state = MutationState.error(e, st);
      scheduleReset();
    }
  }
}

/// Dismiss code scanning alert mutation. Auto-disposes when no longer watched.
final dismissCodeScanningAlertMutationProvider = NotifierProvider.autoDispose
    .family<DismissCodeScanningAlertMutationNotifier, MutationState<void>,
            DismissCodeScanningAlertKey>(
        DismissCodeScanningAlertMutationNotifier.new);
