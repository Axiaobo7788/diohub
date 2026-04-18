import 'package:diohub/common/misc/async_error_widgets.dart';
import 'package:diohub/common/misc/list_loading_shimmers.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub/common/pagination/pagination.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/view/repository/commits/models/graph_layout.dart';
import 'package:diohub/view/repository/commits/widgets/commit_graph_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Commit graph body: sliver-only (no scroll view).
/// Returns [MultiSliver] for use inside the shell's [CustomScrollView];
/// the shell owns the single scroll view.
class CommitGraphView extends ConsumerStatefulWidget {
  const CommitGraphView({required this.repoRef, super.key});

  final RepoRef repoRef;

  @override
  ConsumerState<CommitGraphView> createState() => _CommitGraphViewState();
}

class _CommitGraphViewState extends ConsumerState<CommitGraphView> {
  late final PaginationController<CommitWithLaneData, CommitWithLaneData>
      _controller;
  GraphLayoutCalculator? _calculator;
  String? _cursor;
  final CommitGraphStyle _style = const CommitGraphStyle();

  @override
  void initState() {
    super.initState();
    _controller = PaginationController<CommitWithLaneData, CommitWithLaneData>(
      source: SliceForwardSource<CommitWithLaneData>(
        fetch: _fetchSlice,
        resetState: () {
          _calculator = null;
          _cursor = null;
        },
      ),
      idOf: (final CommitWithLaneData e) => e.cursor ?? e.commit.oid,
      pageSize: 20,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Build empty state widget
  Widget _buildEmptyState(final BuildContext context) => Center(
        child: Padding(
          padding: context.spacing.emptyStatePadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.history,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant.hinted,
              ),
              context.spacing.sectionGap,
              Text(
                'No commits found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              context.spacing.itemGap,
              Text(
                'This repository has no commit history',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .secondary,
                    ),
              ),
            ],
          ),
        ),
      );

  /// Build loading state widget (commit list shimmer).
  Widget _buildLoadingState(final BuildContext context) =>
      ListLoadingShimmers.commitList(context);

  Future<PageSlice<CommitWithLaneData>> _fetchSlice(final int count) async {
    final CommitGraphData graphData =
        ref.read(commitGraphProvider(widget.repoRef)).requireValue;

    final List<CommitWithLaneData> currentItems = _controller.state.value.items;
    final LaneData? lastCommitLaneData =
        currentItems.isNotEmpty ? currentItems.last.laneData : null;

    final List<CommitEdge> edges = await ref
        .read(commitGraphProvider(widget.repoRef).notifier)
        .loadCommitsPage(
          selectedBranch: graphData.selectedBranch,
          cursor: _cursor,
          first: count,
        );

    if (edges.isNotEmpty) {
      _cursor = edges.last.cursor;
    }

    final List<CommitNode> commits = edges
        .map((final CommitEdge e) => e.node)
        .whereType<CommitNode>()
        .toList();

    _calculator ??= GraphLayoutCalculator(
      brightness: Theme.of(context).brightness,
      style: _style,
    );

    final List<CommitWithLaneData> results =
        _calculator!.processCommitsIncremental(commits, lastCommitLaneData);

    if (results.isNotEmpty && edges.isNotEmpty) {
      final String lastCursor = edges.last.cursor;
      final CommitWithLaneData last = results.last;
      results[results.length - 1] = CommitWithLaneData(
        commit: last.commit,
        laneData: last.laneData,
        cursor: lastCursor,
      );
    }

    return PageSlice<CommitWithLaneData>(
      items: results,
      hasNextPage: edges.length >= count,
    );
  }

  /// Build commit row widget
  Widget _buildCommitRow(
    final BuildContext context,
    final CommitWithLaneData data,
    final int index,
  ) {
    final CommitGraphData? graphData =
        ref.read(commitGraphProvider(widget.repoRef)).value;
    final CommitRef commitRef =
        CommitRef.fromGcommitListItem(data.commit, widget.repoRef);
    return CommitGraphRow(
      commitRef: commitRef,
      commitWithLaneData: data,
      branchTips: graphData?.branchTips ?? <String, List<String>>{},
    );
  }

  List<Widget> _buildSlivers(final BuildContext context) {
    final AsyncValue<CommitGraphData> graphAsync =
        ref.watch(commitGraphProvider(widget.repoRef));
    return graphAsync.when(
      loading: () => <Widget>[
        SliverToBoxAdapter(child: _buildLoadingState(context)),
      ],
      error: (final Object error, final StackTrace stack) => <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: CenteredError('Error loading commit graph: $error'),
        ),
      ],
      data: (final _) => <Widget>[
        PaginatedSliverList<CommitWithLaneData>(
          controller: _controller,
          itemBuilder: _buildCommitRow,
          emptyBuilder: _buildEmptyState,
          loadingBuilder: _buildLoadingState,
        ),
      ],
    );
  }

  @override
  Widget build(final BuildContext context) {
    ref.listen(branchProvider(widget.repoRef),
        (final BranchState? previous, final BranchState next) {
      if (next is BranchStateLoading) return;
      final String nextSha = (next as BranchStateResolved).currentSHA;
      final String? prevSha =
          previous is BranchStateResolved ? previous.currentSHA : null;
      if (prevSha != null && prevSha != nextSha) {
        _calculator = null;
        _controller.refresh();
      }
    });

    return MultiSliver(children: _buildSlivers(context));
  }
}
