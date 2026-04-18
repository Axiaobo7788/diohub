/// Mutation provider for adding/removing discussion upvotes.
/// Used by [DiscussionUpvoteButton].
library;

import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/riverpod/mutation_state.dart';
import 'package:diohub/services/capabilities/capabilities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/providers/database_providers.dart';

class DiscussionUpvoteMutationNotifier extends Notifier<MutationState<void>>
    with MutationNotifierMixin<void> {
  DiscussionUpvoteMutationNotifier(this._discussionId);

  final String _discussionId;

  @override
  MutationState<void> build() {
    initMutationDisposal();
    return MutationState.idle();
  }

  Future<void> addUpvote() async {
    if (state is MutationLoading<void>) return;
    state = MutationState.loading();
    try {
      await DiscussionNodeService(ref.read(apiClientProvider), _discussionId).addUpvote();
      state = const MutationState.success(null);
      scheduleReset();
    } catch (e, st) {
      AppLogger.warning(
        'Discussion add upvote failed',
        error: e,
        stackTrace: st,
        tag: 'DiscussionUpvote',
      );
      state = MutationState.error(e, st);
      scheduleReset();
    }
  }

  Future<void> removeUpvote() async {
    if (state is MutationLoading<void>) return;
    state = MutationState.loading();
    try {
      await DiscussionNodeService(ref.read(apiClientProvider), _discussionId).removeUpvote();
      state = const MutationState.success(null);
      scheduleReset();
    } catch (e, st) {
      AppLogger.warning(
        'Discussion remove upvote failed',
        error: e,
        stackTrace: st,
        tag: 'DiscussionUpvote',
      );
      state = MutationState.error(e, st);
      scheduleReset();
    }
  }
}

final discussionUpvoteMutationProvider = NotifierProvider.autoDispose
    .family<DiscussionUpvoteMutationNotifier, MutationState<void>, String>(
        DiscussionUpvoteMutationNotifier.new);
