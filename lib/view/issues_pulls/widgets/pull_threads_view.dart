import 'package:diohub/common/misc/list_loading_shimmers.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/pagination/pagination.dart';
import 'package:diohub_graphql/queries/issues_pulls/review_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/providers/database_providers.dart'
    show apiClientProvider;
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/view/issues_pulls/widgets/review_thread_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

typedef _ThreadEdge = ReviewThreadEdge;

/// Filter for the threads list. Public so [pullThreadsFilterProvider] can use it.
enum ThreadsFilter { all, unresolved, resolved }

bool _matchesFilter(ThreadsFilter filter, _ThreadEdge edge) {
  final node = edge.node;
  if (node == null) return false;
  switch (filter) {
    case ThreadsFilter.all:
      return true;
    case ThreadsFilter.unresolved:
      return !node.isResolved;
    case ThreadsFilter.resolved:
      return node.isResolved;
  }
}

class _PullThreadsFilterNotifier extends Notifier<ThreadsFilter> {
  _PullThreadsFilterNotifier(this._pullRef);

  // ignore: unused_field
  final PullRequestRef _pullRef;

  @override
  ThreadsFilter build() => ThreadsFilter.all;
}

final pullThreadsFilterProvider = NotifierProvider.autoDispose
    .family<_PullThreadsFilterNotifier, ThreadsFilter, PullRequestRef>(
      _PullThreadsFilterNotifier.new,
    );

final pullThreadsControllerProvider = Provider.autoDispose
    .family<PaginationController<_ThreadEdge?, _ThreadEdge?>?, PullRequestRef>((
      final Ref ref,
      final PullRequestRef pullRef,
    ) {
      final controller = PaginationController<_ThreadEdge?, _ThreadEdge?>(
        idOf: (final _ThreadEdge? e) => e?.cursor ?? '',
        source: CursorForwardSource<_ThreadEdge?>(
          fetch: ({required int first, String? after}) async {
            final result = await pullRef
                .services(ref.read(apiClientProvider))
                .getPullRequestReviewThreads(cursor: after);
            final edges =
                result?.repository?.pullRequest?.reviewThreads.edges ??
                <ReviewThreadEdge?>[];
            return CursorPage<_ThreadEdge?>(
              items: edges.toList(),
              hasNextPage:
                  result
                      ?.repository
                      ?.pullRequest
                      ?.reviewThreads
                      .pageInfo
                      .hasNextPage ??
                  false,
              endCursor: result
                  ?.repository
                  ?.pullRequest
                  ?.reviewThreads
                  .pageInfo
                  .endCursor,
            );
          },
        ),
        filter: (final List<_ThreadEdge?> items) => items
            .where(
              (final _ThreadEdge? e) =>
                  e?.node != null &&
                  _matchesFilter(
                    ref.read(pullThreadsFilterProvider(pullRef)),
                    e!,
                  ),
            )
            .toList(),
        pageSize: 25,
      );
      ref.onDispose(controller.dispose);
      return controller;
    });

/// Returns slivers for the Threads position (for use with [SliverBuilderBody]).
/// [onThreadTap] is optional; when provided, tapping a thread card navigates to
/// the thread reply screen. Premium passes [ReviewCommentScreen] here.
List<Widget> buildPullThreadsSlivers(
  final BuildContext context,
  final WidgetRef ref,
  final PullRequestRef pullRef, {
  final Widget Function(
    PullRequestRef pullRef,
    String threadId,
    String? filePath,
  )?
  onThreadTap,
}) {
  final PaginationController<_ThreadEdge?, _ThreadEdge?>? controller = ref
      .watch(pullThreadsControllerProvider(pullRef));

  if (controller == null) {
    return <Widget>[
      const SliverFillRemaining(
        hasScrollBody: false,
        child: const CenteredSpinner(),
      ),
    ];
  }

  return <Widget>[
    PaginatedSliverList<_ThreadEdge?>(
      controller: controller,
      loadingBuilder: ListLoadingShimmers.commitList,
      itemBuilder:
          (
            final BuildContext context,
            final _ThreadEdge? edge,
            final int index,
          ) {
            final node = edge?.node;
            if (node == null) return const SizedBox.shrink();
            final int commentCount = node.comments.totalCount;
            final firstComment = node.comments.nodes?.isNotEmpty == true
                ? node.comments.nodes!.first
                : null;
            final String? snippet = firstComment?.body.trim();
            final String? sideLabel = node.diffSide.name.toLowerCase();
            final String? authorLogin = firstComment?.author?.login;
            final String? createdAtIso = firstComment?.createdAt
                .toIso8601String();
            return Padding(
              padding: EdgeInsets.only(
                top: context.spacing.tightSpacing,
                bottom: context.spacing.tightSpacing,
              ),
              child: ReviewThreadCard(
                path: node.path,
                line: node.line,
                sideLabel: sideLabel,
                commentCount: commentCount,
                isResolved: node.isResolved,
                snippet: snippet?.isNotEmpty == true ? snippet : null,
                firstCommentAuthorLogin: authorLogin,
                firstCommentCreatedAt: createdAtIso,
                onTap: onThreadTap != null
                    ? () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (final _) =>
                                onThreadTap(pullRef, node.id, node.path),
                          ),
                        );
                      }
                    : null,
              ),
            );
          },
    ),
  ];
}

/// PR review threads list with infinite scroll.
/// Filter: All / Unresolved / Resolved. Tapping a thread opens the file diff.
class PullThreadsView extends ConsumerStatefulWidget {
  const PullThreadsView({required this.pullRef, this.onThreadTap, super.key});

  final PullRequestRef pullRef;

  /// Optional premium injection – when provided, tapping a thread card opens
  /// the review comment reply screen.
  final Widget Function(
    PullRequestRef pullRef,
    String threadId,
    String? filePath,
  )?
  onThreadTap;

  @override
  ConsumerState<PullThreadsView> createState() => _PullThreadsViewState();
}

class _PullThreadsViewState extends ConsumerState<PullThreadsView> {
  @override
  Widget build(final BuildContext context) {
    return MultiSliver(
      children: buildPullThreadsSlivers(
        context,
        ref,
        widget.pullRef,
        onThreadTap: widget.onThreadTap,
      ),
    );
  }
}
