/// Commit graph data and loadCommitsPage for the repo commits tab. Depends on
/// [repository_providers_core] and [branch_notifier].
library;

import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/common/riverpod/keep_alive_helper.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/repository/branch_notifier.dart';
import 'package:diohub/providers/repository/repository_providers_core.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/services/repositories/repo_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/src/providers/async_notifier.dart';

/// Data for the commit graph: branch tips map and the selected branch name.
class CommitGraphData {
  const CommitGraphData({
    required this.branchTips,
    required this.selectedBranch,
  });

  /// Map of commit OID → list of branch names pointing at that commit.
  final Map<String, List<String>> branchTips;

  /// The branch whose commit history is being displayed.
  final String selectedBranch;
}

final commitGraphProvider = AsyncNotifierProvider.autoDispose
    .family<CommitGraphNotifier, CommitGraphData, RepoRef>(
  CommitGraphNotifier.new,
);

class CommitGraphNotifier extends AsyncNotifier<CommitGraphData> {
  CommitGraphNotifier(this.arg);
  final RepoRef arg;

  late final RepositoryServices _services = arg.services(ref.read(apiClientProvider));

  @override
  Future<CommitGraphData> build() async {
    keepAliveFor(ref);

    BranchState branch = ref.watch(branchProvider(arg));
    if (branch is BranchStateLoading) {
      await ref.read<Future<RepoInfoData>>(
        repositoryProvider(arg).future,
      );
      branch = ref.read<BranchState>(branchProvider(arg));
      if (branch case BranchStateLoading()) {
        return const CommitGraphData(
          branchTips: <String, List<String>>{},
          selectedBranch: '',
        );
      }
    }
    final BranchStateResolved resolved = branch as BranchStateResolved;
    final String selectedBranch = resolved.currentSHA;

    final List<BranchEdge> allBranches =
        await arg.branches(ref.read(apiClientProvider)).fetchBranchListGQL(first: 100);
    final Map<String, List<String>> branchTips = <String, List<String>>{};
    for (final BranchEdge edge in allBranches) {
      final String? branchName = edge.node?.name;
      final String? commitOid = edge.node?.target?.maybeWhen(
        commit: (final BranchCommit c) => c.oid,
        orElse: () => null,
      );
      if (commitOid != null && branchName != null) {
        branchTips.putIfAbsent(commitOid, () => <String>[]).add(branchName);
      }
    }

    return CommitGraphData(
      branchTips: branchTips,
      selectedBranch: selectedBranch,
    );
  }

  /// Load a page of commit edges for the graph view. Call from UI instead of
  /// [RepositoryServices] directly.
  Future<List<CommitEdge>> loadCommitsPage({
    required final String selectedBranch,
    final String? cursor,
    final int first = 20,
  }) =>
      _services.loadCommitsPage(
        selectedBranch: selectedBranch,
        cursor: cursor,
        first: first,
      );
}
