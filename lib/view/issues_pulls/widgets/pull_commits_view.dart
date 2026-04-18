import 'package:diohub/common/cards/commit_card.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub/common/misc/list_loading_shimmers.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/pagination/pagination.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub/models/commits/commit_list_item_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/issue_pulls/issue_providers.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

typedef _Edge = PullCommitEdge;

typedef _Commit = PullCommitNode;

CommitListItemModel _commitFromPullGQL(
  final _Commit commit,
  final String repoOwner,
  final String repoName,
) {
  final String? authorLogin = commit.author?.user?.login;
  final String? authorAvatarUrl = commit.author?.avatarUrl.toString();
  return CommitListItemModel(
    messageHeadline: commit.messageHeadline,
    authorLogin: authorLogin,
    authorAvatarUrl: authorAvatarUrl,
    committedDate: commit.authoredDate,
    sha: commit.oid,
    commitUrl: commit.commitUrl.toString(),
    repoOwner: repoOwner,
    repoName: repoName,
  );
}

/// Returns a [SliverListBody] for the commits list on a PR screen.
TabBody createPullCommitsBody(PullRequestRef pullRef) {
  final String owner = pullRef.repo.owner;
  final String repoName = pullRef.repo.name;
  return DelegatingTabBody(
    createBody: (ref) => SliverListBody<_Edge?>(
      getCursor: (item) => item?.cursor,
      fetcher: ({String? after, int first = 20, bool refresh = false}) async {
        final result = await ref
            .read(pullDetailProvider(pullRef).notifier)
            .getPullCommitsPage(first: first, after: after, refresh: refresh);
        final items = result.items
            .where((e) => e != null && e.node != null)
            .cast<_Edge?>()
            .toList();
        return PaginatedResult(
          items: items,
          hasNextPage: result.hasNextPage,
          endCursor: result.endCursor,
        );
      },
      itemBuilder: (BuildContext context, _Edge? item) {
        final node = item?.node;
        if (node == null) return const SizedBox.shrink();
        final PullCommitNode commit = node.commit;
        final CommitListItemModel model = _commitFromPullGQL(
          commit,
          owner,
          repoName,
        );
        final RepoRef? repo = model.repoFullName != null
            ? RepoRef.fromFullName(model.repoFullName!)
            : null;
        return Padding(
          padding: context.spacing.listInset.copyWith(
            top: context.spacing.tightSpacing,
            bottom: context.spacing.tightSpacing,
          ),
          child: repo != null
              ? BorderedContainer(
                  ref: CommitRef(repo: repo, oid: model.sha),
                  child: CommitCard(data: model),
                )
              : BorderedContainer(child: CommitCard(data: model)),
        );
      },
    ),
  );
}

/// Commits tab for pull requests. Takes [pullRef] only; data is fetched
/// via [pullDetailProvider] notifier.
class PullCommitsView extends ConsumerStatefulWidget {
  const PullCommitsView({required this.pullRef, super.key});

  final PullRequestRef pullRef;

  @override
  ConsumerState<PullCommitsView> createState() => _PullCommitsViewState();
}

class _PullCommitsViewState extends ConsumerState<PullCommitsView> {
  late final PaginationController<_Edge, _Edge> _controller;

  @override
  void initState() {
    super.initState();
    _controller = PaginationController<_Edge, _Edge>(
      idOf: (final _Edge e) => e.cursor,
      source: CursorForwardSource<_Edge>(
        fetch: ({required int first, String? after}) async {
          final result = await ref
              .read(pullDetailProvider(widget.pullRef).notifier)
              .getPullCommitsPage(first: first, after: after);
          final items = result.items
              .where((final PullCommitEdge? e) => e?.node != null)
              .cast<_Edge>()
              .toList();
          return CursorPage<_Edge>(
            items: items,
            hasNextPage: result.hasNextPage,
            endCursor: result.endCursor,
          );
        },
      ),
      pageSize: 20,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final String owner = widget.pullRef.repo.owner;
    final String repoName = widget.pullRef.repo.name;
    return MultiSliver(
      children: <Widget>[
        PaginatedSliverList<_Edge>(
          controller: _controller,
          loadingBuilder: ListLoadingShimmers.commitList,
          itemBuilder:
              (final BuildContext context, final _Edge edge, final int index) {
                final node = edge.node;
                if (node == null) return const SizedBox.shrink();
                final PullCommitNode commit = node.commit;
                final CommitListItemModel model = _commitFromPullGQL(
                  commit,
                  owner,
                  repoName,
                );
                final RepoRef? repo = model.repoFullName != null
                    ? RepoRef.fromFullName(model.repoFullName!)
                    : null;
                return Padding(
                  padding: context.spacing.listInset.copyWith(
                    top: context.spacing.tightSpacing,
                    bottom: context.spacing.tightSpacing,
                  ),
                  child: repo != null
                      ? BorderedContainer(
                          ref: CommitRef(repo: repo, oid: model.sha),
                          child: CommitCard(data: model),
                        )
                      : BorderedContainer(child: CommitCard(data: model)),
                );
              },
        ),
      ],
    );
  }
}
