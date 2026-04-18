/// Riverpod provider for reaction data and mutations on a reactable node
/// (issue, PR, or comment). Keyed by reactable node ID.
library;

import 'package:diohub/app/app_logger.dart';
import 'package:diohub_models/models/pagination/page_slice.dart' show CursorPage;
import 'package:diohub/common/riverpod/keep_alive_helper.dart';
import 'package:diohub/common/riverpod/mutation_error.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub/services/capabilities/capabilities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/providers/database_providers.dart';

/// Service for reaction operations keyed by reactable node ID. Instance-based API.
final reactableByIdServiceProvider =
    Provider.autoDispose.family<ReactableService, String>(
  (ref, reactableId) => ReactableService(ref.read(apiClientProvider), reactableId),
);

/// Fetches one page of reactors; used by [ReactionBar].
typedef GetReactorsPageFn = Future<CursorPage<ReactorsGroupEdge?>> Function(
  String reactableId,
  ReactionContent content, {
  required int first,
  String? after,
});

final Provider<GetReactorsPageFn> getReactorsPageProvider =
    Provider<GetReactorsPageFn>((ref) => (
          String reactableId,
          ReactionContent content, {
          required int first,
          String? after,
        }) =>
            ref
                .read(reactableByIdServiceProvider(reactableId))
                .getReactorsPage(content, first: first, after: after));

final reactionsProvider = AsyncNotifierProvider.autoDispose
    .family<ReactionsNotifier, List<ReactorsGroup>, String>(
  ReactionsNotifier.new,
);

/// List of reactors for a given subject and reaction content (e.g. for "who reacted" sheet).
final reactorsListProvider = FutureProvider.autoDispose.family<
    List<ReactorsGroupEdge?>, ({String subjectId, ReactionContent content})>(
  (ref, key) => ref
      .read(reactionsProvider(key.subjectId).notifier)
      .getReactors(key.content),
);

class ReactionsNotifier extends AsyncNotifier<List<ReactorsGroup>> {
  ReactionsNotifier(this.arg);
  final String arg;

  @override
  Future<List<ReactorsGroup>> build() async {
    keepAliveFor(ref);
    return ref.watch(reactableByIdServiceProvider(arg)).getReactionGroups();
  }

  Future<void> addReaction(final ReactionContent content) async {
    final previousState = state;
    try {
      final List<ReactorsGroup>? groups = await ref
          .read(reactableByIdServiceProvider(arg))
          .addReaction(content);
      if (groups != null) {
        state = AsyncValue.data(groups);
      }
    } catch (e, st) {
      AppLogger.error(
        'Add reaction failed',
        error: e,
        stackTrace: st,
        tag: 'Reactions',
      );
      // Revert to previous state on error
      state = previousState;
      showMutationError(ref, "Couldn't add reaction", error: e, stackTrace: st);
    }
  }

  Future<void> removeReaction(final ReactionContent content) async {
    final previousState = state;
    try {
      final List<ReactorsGroup>? groups = await ref
          .read(reactableByIdServiceProvider(arg))
          .removeReaction(content);
      if (groups != null) {
        state = AsyncValue.data(groups);
      }
    } catch (e, st) {
      AppLogger.error(
        'Remove reaction failed',
        error: e,
        stackTrace: st,
        tag: 'Reactions',
      );
      // Revert to previous state on error
      state = previousState;
      showMutationError(ref, "Couldn't remove reaction", error: e, stackTrace: st);
    }
  }

  Future<List<ReactorsGroupEdge?>> getReactors(
    final ReactionContent content,
  ) =>
      ref.read(reactableByIdServiceProvider(arg)).getReactors(content);
}
