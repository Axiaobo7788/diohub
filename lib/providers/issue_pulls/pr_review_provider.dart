/// Riverpod provider for PR review screen: pending review GQL data and
/// review comment fetching / reply. Keyed by (PullRequestRef, reviewNodeId).
library;

import 'package:diohub_graphql/queries/issues_pulls/pr_review_checks.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/review_typedefs.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub/providers/database_providers.dart';

import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/issue_pulls/issue_providers.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:riverpod/src/providers/async_notifier.dart';

/// Key for [prReviewProvider]: (PullRequestRef, reviewNodeId).
typedef PrReviewKey = ({PullRequestRef pr, String reviewNodeId});

/// Key for [reviewThreadForCommentProvider].
typedef ReviewThreadForCommentKey = ({PullRequestRef pr, String commentId});

/// Pending review comment count for hint ("N pending"). Keyed by [PullRequestRef].
/// Uses viewer's pending (draft) review comments.totalCount from getViewerPendingReview.
final pendingReviewCommentsCountProvider = FutureProvider.autoDispose
    .family<int, PullRequestRef>((
      final Ref ref,
      final PullRequestRef pr,
    ) async {
      final pending = await ref.read(pendingReviewProvider(pr).future);
      if (pending == null) return 0;
      final int? total = pending.comments.totalCount;
      return total ?? 0;
    });

/// Pending (draft) review comments for [PrReviewKey]. Used by submit-review screen.
final pendingReviewCommentsProvider = FutureProvider.autoDispose
    .family<List<ReviewCommentEdge?>, PrReviewKey>(
      (ref, key) => key.pr
          .services(ref.read(apiClientProvider))
          .getPRReview(key.reviewNodeId, refresh: true, cursor: null),
    );

/// Returns the viewer's pending (draft) review node for a PR, or null.
/// Keyed by [PullRequestRef]. Use for banner and submit-review flow.
final pendingReviewProvider = FutureProvider.autoDispose
    .family<PendingReviewNode?, PullRequestRef>((
      final Ref ref,
      final PullRequestRef pr,
    ) async {
      final pullDetail = await ref.read(pullDetailProvider(pr).future);
      final ViewerPendingReviewData? data = await pr
          .services(ref.read(apiClientProvider))
          .getViewerPendingReview(pullDetail.id);
      final nodes = data?.node?.maybeWhen(
        pullRequest: (final p) => p.reviews?.nodes,
        orElse: () => null,
      );
      if (nodes == null || nodes.isEmpty) return null;
      return nodes.first;
    });

final AsyncNotifierProviderFamily<
  PrReviewNotifier,
  ViewerPendingReviewData?,
  PrReviewKey
>
prReviewProvider =
    AsyncNotifierProvider.family<
      PrReviewNotifier,
      ViewerPendingReviewData?,
      PrReviewKey
    >(PrReviewNotifier.new);

/// Review thread replies (comments) for the thread. Key: (PullRequestRef, threadNodeId).
typedef ReviewThreadRepliesKey = ({PullRequestRef pr, String threadNodeId});

final reviewThreadRepliesProvider = FutureProvider.autoDispose
    .family<List<ThreadReplyEdge?>, ReviewThreadRepliesKey>((ref, key) async {
      final page = await key.pr
          .services(ref.read(apiClientProvider))
          .getReviewThreadReplies(key.threadNodeId, null, refresh: true);
      return page.edges;
    });

/// Fetches ALL review threads for a PR (paginating fully) and builds a
/// Map<commentId, threadEdge>. Shared across all [reviewThreadForCommentProvider]
/// instances for the same PR.
final allReviewThreadsMapProvider = FutureProvider.autoDispose
    .family<Map<String, ReviewThreadEdge>, PullRequestRef>((
      final Ref ref,
      final PullRequestRef pr,
    ) async {
      final map = <String, ReviewThreadEdge>{};
      String? cursor;
      bool hasMore = true;

      while (hasMore) {
        final data = await pr
            .services(ref.read(apiClientProvider))
            .getPullRequestReviewThreads(cursor: cursor, refresh: false);
        final threads = data?.repository?.pullRequest?.reviewThreads;
        if (threads == null) break;

        for (final ReviewThreadEdge? edge in threads.edges ?? const []) {
          if (edge?.node == null) continue;
          final commentNodes = edge!.node!.comments.nodes;
          if (commentNodes != null) {
            for (final n in commentNodes) {
              if (n != null) map[n.id] = edge;
            }
          }
        }

        hasMore = threads.pageInfo.hasNextPage;
        cursor = threads.pageInfo.endCursor;
      }
      return map;
    });

/// Fetches the review thread edge for a specific comment (for reply count).
/// O(1) map lookup after [allReviewThreadsMapProvider] completes.
final reviewThreadForCommentProvider = FutureProvider.autoDispose
    .family<ReviewThreadEdge?, ReviewThreadForCommentKey>((
      final Ref ref,
      final ReviewThreadForCommentKey key,
    ) async {
      final map = await ref.watch(allReviewThreadsMapProvider(key.pr).future);
      return map[key.commentId];
    });

class PrReviewNotifier extends AsyncNotifier<ViewerPendingReviewData?> {
  PrReviewNotifier(this.key);
  final PrReviewKey key;

  PullRequestRef get _pr => key.pr;

  @override
  Future<ViewerPendingReviewData?> build() async {
    final pullDetail = await ref.watch(pullDetailProvider(_pr).future);
    return _pr
        .services(ref.watch(apiClientProvider))
        .getViewerPendingReview(pullDetail.id);
  }
}
