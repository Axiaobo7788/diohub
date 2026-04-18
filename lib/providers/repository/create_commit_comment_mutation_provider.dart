/// Mutation to create a commit comment. Invalidates [commitDataProvider] and
/// bumps [commitCommentsRefreshTriggerProvider] on success.
library;

import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/riverpod/mutation_state.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/commits/commit_providers.dart';
import 'package:diohub/providers/repository/commit_comments_refresh_trigger_provider.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/providers/database_providers.dart';

class CreateCommitCommentMutationNotifier extends Notifier<MutationState<void>>
    with MutationNotifierMixin<void> {
  CreateCommitCommentMutationNotifier(this._commitRef);

  final CommitRef _commitRef;

  @override
  MutationState<void> build() {
    initMutationDisposal();
    return MutationState.idle();
  }

  Future<void> create({
    required String body,
    void Function()? onSuccess,
  }) async {
    if (state is MutationLoading<void>) return;
    state = MutationState.loading();
    try {
      await _commitRef.repo.services(ref.read(apiClientProvider)).createCommitComment(
        commitRef: _commitRef,
        body: body,
      );
      ref.invalidate(commitDataProvider(_commitRef));
      ref.read(commitCommentsRefreshTriggerProvider(_commitRef)).value++;
      onSuccess?.call();
      state = const MutationState.success(null);
      scheduleReset();
    } catch (e, st) {
      AppLogger.warning(
        'Create commit comment failed',
        error: e,
        stackTrace: st,
        tag: 'CreateCommitComment',
      );
      state = MutationState.error(e, st);
      scheduleReset();
    }
  }
}

/// Create commit comment mutation per commit. Auto-disposes when no longer watched.
final createCommitCommentMutationProvider = NotifierProvider.autoDispose.family<
    CreateCommitCommentMutationNotifier,
    MutationState<void>,
    CommitRef>(CreateCommitCommentMutationNotifier.new);
