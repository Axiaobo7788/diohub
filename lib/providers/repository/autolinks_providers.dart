/// Delete autolink mutation. List is paginated in the sheet via
/// [PaginationController] + [PageNumberForwardSource]; no list provider.
library;

import 'package:diohub/common/riverpod/mutation_state.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/providers/database_providers.dart';

/// Key for the delete mutation family: (RepoRef, autolinkId).
typedef DeleteAutolinkKey = ({RepoRef repo, int autolinkId});

class DeleteAutolinkMutationNotifier extends Notifier<MutationState<void>>
    with MutationNotifierMixin<void> {
  DeleteAutolinkMutationNotifier(this._key);

  final DeleteAutolinkKey _key;

  RepoRef get _repoRef => _key.repo;
  int get _autolinkId => _key.autolinkId;

  @override
  MutationState<void> build() {
    initMutationDisposal();
    return MutationState.idle();
  }

  /// [onSuccess] Called after delete (e.g. to apply PatchDeleted). The list
  /// is driven by [PaginationController] in the sheet; no list provider.
  Future<void> delete({void Function()? onSuccess}) async {
    if (state is MutationLoading<void>) return;
    state = MutationState.loading();
    try {
      await _repoRef.deployments(ref.read(apiClientProvider)).deleteAutolink(_autolinkId);
      onSuccess?.call();
      state = const MutationState.success(null);
      scheduleReset();
    } catch (e, st) {
      state = MutationState.error(e, st);
      scheduleReset();
    }
  }
}

/// Delete autolink mutation. Auto-disposes when no longer watched.
final deleteAutolinkMutationProvider = NotifierProvider.autoDispose.family<
    DeleteAutolinkMutationNotifier,
    MutationState<void>,
    DeleteAutolinkKey>(DeleteAutolinkMutationNotifier.new);
