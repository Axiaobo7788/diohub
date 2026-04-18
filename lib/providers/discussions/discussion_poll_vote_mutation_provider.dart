/// Mutation to vote on a discussion poll option. Invalidates discussion
/// provider on success.
library;

import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/riverpod/mutation_state.dart';
import 'package:diohub/services/capabilities/capabilities.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef DiscussionPollVoteKey = ({String optionId, String discussionId});

class DiscussionPollVoteMutationNotifier extends Notifier<MutationState<void>>
    with MutationNotifierMixin<void> {
  DiscussionPollVoteMutationNotifier(this._key);

  final DiscussionPollVoteKey _key;

  @override
  MutationState<void> build() {
    initMutationDisposal();
    return MutationState.idle();
  }

  Future<void> mutate() async {
    if (state is MutationLoading<void>) return;
    state = MutationState.loading();
    try {
      await DiscussionNodeService(
        ref.read(apiClientProvider),
        _key.discussionId,
      ).addPollVote(_key.optionId);
      state = const MutationState.success(null);
      scheduleReset();
    } catch (e, st) {
      AppLogger.warning(
        'Discussion poll vote failed',
        error: e,
        stackTrace: st,
        tag: 'DiscussionPollVote',
      );
      state = MutationState.error(e, st);
      scheduleReset();
    }
  }
}

final discussionPollVoteMutationProvider = NotifierProvider.autoDispose.family<
    DiscussionPollVoteMutationNotifier,
    MutationState<void>,
    DiscussionPollVoteKey>(DiscussionPollVoteMutationNotifier.new);
