/// Delete gist mutation. Call [onSuccess] to patch the list (e.g. applyPatch).
/// List is driven by [PaginationController] when viewer; no list provider.
library;

import 'package:diohub/common/riverpod/mutation_state.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Key for the delete mutation family: (userRef, gistId).
typedef DeleteGistKey = ({UserRef user, String gistId});

class DeleteGistMutationNotifier extends Notifier<MutationState<void>>
    with MutationNotifierMixin<void> {
  DeleteGistMutationNotifier(this._key);

  final DeleteGistKey _key;

  String get _gistId => _key.gistId;

  @override
  MutationState<void> build() {
    initMutationDisposal();
    return MutationState.idle();
  }

  /// [onSuccess] Called after delete (e.g. to apply PatchDeleted). The list
  /// is driven by [PaginationController] in the viewer gists body.
  Future<void> delete({void Function()? onSuccess}) async {
    if (state is MutationLoading<void>) return;
    state = MutationState.loading();
    try {
      await ref.read(viewerSettingsServiceProvider).deleteGist(_gistId);
      onSuccess?.call();
      state = const MutationState.success(null);
      scheduleReset();
    } catch (e, st) {
      state = MutationState.error(e, st);
      scheduleReset();
    }
  }
}

/// Delete gist mutation. Auto-disposes when no longer watched.
final deleteGistMutationProvider = NotifierProvider.autoDispose
    .family<DeleteGistMutationNotifier, MutationState<void>, DeleteGistKey>(
        DeleteGistMutationNotifier.new);
