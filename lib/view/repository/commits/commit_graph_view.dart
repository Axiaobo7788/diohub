import 'package:diohub/common/wrappers/app_custom_scroll_view.dart';
import 'package:diohub/common/wrappers/infinite_pagination.dart';
import 'package:diohub/common/wrappers/infinite_scroll_wrapper.dart';
import 'package:diohub/providers/repository/commit_graph_provider.dart';
import 'package:diohub/view/repository/commits/models/graph_layout.dart';
import 'package:diohub/view/repository/commits/widgets/commit_graph_row.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CommitGraphView extends StatefulWidget {
  const CommitGraphView({super.key});

  @override
  State<CommitGraphView> createState() => _CommitGraphViewState();
}

class _CommitGraphViewState extends State<CommitGraphView> {
  late final InfinitePaginationController<CommitWithLaneData> _controller;
  final GraphLayoutCalculator _calculator = GraphLayoutCalculator();

  @override
  void initState() {
    super.initState();
    _controller = InfinitePaginationController<CommitWithLaneData>(
      future: _fetchCommitsPage,
      builder: _buildCommitRow,
      pageSize: 20,
      separatorBuilder: (context, index) => const SizedBox(height: 0),
      emptyBuilder: _buildEmptyState,
      firstPageLoadingBuilder: _buildLoadingState,
    );
  }

  /// Build empty state widget
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No commits found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'This repository has no commit history',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build loading state widget
  Widget _buildLoadingState(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Fetch commits page and wrap with lane data
  Future<List<CommitWithLaneData>> _fetchCommitsPage(
    ScrollWrapperFutureArguments<CommitWithLaneData> args,
  ) async {
    final provider = context.read<CommitGraphProvider>();

    // Extract state from last item's laneData (no dirty state!)
    LaneData? lastCommitLaneData;
    if (!args.refresh && args.lastItem != null) {
      lastCommitLaneData = args.lastItem!.laneData;
    }

    // Load raw commits
    final rawCommits = await provider.loadCommitsPage(
      cursor: null, // Provider handles cursor internally
      refresh: args.refresh,
    );

    // Calculate lanes incrementally - only need state from last commit!
    final newCommitsWithLaneData = _calculator.processCommitsIncremental(
      rawCommits,
      lastCommitLaneData,
    );

    return newCommitsWithLaneData;
  }

  /// Build commit row widget
  Widget _buildCommitRow(
    BuildContext context,
    ScrollWrapperBuilderData<CommitWithLaneData> data,
  ) {
    final provider = context.read<CommitGraphProvider>();
    return CommitGraphRow(
      commitWithLaneData: data.item,
      branchTips: provider.branchTips,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCustomScrollView(
      slivers: [
        _controller.buildSliverList(context),
      ],
    );
  }
}
