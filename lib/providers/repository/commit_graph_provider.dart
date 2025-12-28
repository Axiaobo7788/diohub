import 'package:diohub/app/global.dart';
import 'package:diohub/graphql/queries/repositories/__generated__/branches_list.data.gql.dart';
import 'package:diohub/graphql/queries/repositories/__generated__/commits_list.data.gql.dart';
import 'package:diohub/graphql/queries/repositories/__generated__/repo_info.data.gql.dart';
import 'package:diohub/providers/base_provider.dart';
import 'package:diohub/providers/repository/repository_provider.dart';
import 'package:diohub/services/repositories/repo_services.dart';
import 'package:flutter/foundation.dart';

class CommitGraphProvider extends BaseDataProvider<CommitGraphData> {
  CommitGraphProvider({
    required this.repositoryProvider,
    this.branchName,
  });

  final RepositoryProvider repositoryProvider;
  final String? branchName;

  Map<String, List<String>>? _branchTips;
  List<GbranchesListData_repository_refs_edges>? _allBranches;
  String? _lastCursor;

  Map<String, List<String>>? get branchTips => _branchTips;
  List<String>? get availableBranches =>
      _allBranches?.map((b) => b.node?.name ?? '').where((n) => n.isNotEmpty).toList();

  Future<GcommitHistoryConnection> _loadCommitHistory({
    required String owner,
    required String repoName,
    required String refName,
  }) async {    try {
      final history = await RepositoryServices.getCommitsListGQL(
        owner: owner,
        repo: repoName,
        ref: refName,
        first: 50,
      );
      
      if (kDebugMode) {        if (history.edges != null && history.edges!.isNotEmpty) {        } else {        }
      }
      return history;
    } catch (e) {      // Fallback to default branch query
      final history = await RepositoryServices.getCommitsListGQL(
        owner: owner,
        repo: repoName,
        ref: null, // This triggers the default branch query path
        first: 50,
      );      return history;
    }
  }

  @override
  Future<CommitGraphData> setInitData({
    final bool isInitialisation = false,
  }) async {    final repo = repositoryProvider.data;
    final owner = repo.owner.when(
      user: (u) => u.login,
      organization: (o) => o.login,
      orElse: () => throw Exception('Invalid repository owner'),
    );
    final repoName = repo.name;    // Load all branches
    _allBranches = await RepositoryServices.fetchBranchListGQL(
      owner: owner,
      repo: repoName,
      first: 100,
    );    // Build branch tips map
    _branchTips = {};
    for (final branch in _allBranches!) {
      final target = branch.node?.target;
      final branchName = branch.node?.name;
      
      if (kDebugMode && branchName != null) {      }
      
      final commitOid = target?.when(
        commit: (c) => c.oid,
        orElse: () {
          if (kDebugMode && branchName != null) {          }
          return null;
        },
      );
      
      if (commitOid != null && branchName != null) {
        _branchTips!.putIfAbsent(commitOid, () => []).add(branchName);
      }
    }

    if (kDebugMode) {      final totalBranchLabels = _branchTips!.values.fold<int>(0, (sum, list) => sum + list.length);      // Log the actual contents of the map
      if (_branchTips!.isNotEmpty) {        for (final entry in _branchTips!.entries) {        }
      } else {      }
    }

    // Load commits from selected branch or default branch
    final selectedBranch = branchName ?? repo.defaultBranchRef?.name ?? 'main';
    // Use full ref name format: refs/heads/main
    final fullRefName = selectedBranch.startsWith('refs/') 
        ? selectedBranch 
        : 'refs/heads/$selectedBranch';    // Load history using ref name (always use full ref format)
    final history = await _loadCommitHistory(
      owner: owner,
      repoName: repoName,
      refName: fullRefName,
    );

    if (kDebugMode) {      if (history.edges != null && history.edges!.isNotEmpty) {      }
    }

    // Convert to list of commits
    final commits = history.edges
            ?.map((e) => e?.node)
            .whereType<GcommitListItem>()
            .toList() ??
        [];

    if (kDebugMode) {      // Count edges (parent relationships)
      int edgeCount = 0;
      for (final commit in commits) {
        final parentOids = commit.parents.edges
                ?.map((e) => e?.node?.oid)
                .whereType<String>()
                .toList() ??
            [];
        edgeCount += parentOids.length;
      }    }

    return CommitGraphData(
      commits: commits,
      branchTips: _branchTips!,
      selectedBranch: selectedBranch,
    );
  }

  Future<void> loadBranchCommits(String branch) async {    loading();
    try {
      final repo = repositoryProvider.data;
      final owner = repo.owner.when(
        user: (u) => u.login,
        organization: (o) => o.login,
        orElse: () => throw Exception('Invalid repository owner'),
      );
      final repoName = repo.name;

      // Use full ref name format: refs/heads/main
      final fullRefName = branch.startsWith('refs/') 
          ? branch 
          : 'refs/heads/$branch';      final history = await RepositoryServices.getCommitsListGQL(
        owner: owner,
        repo: repoName,
        ref: fullRefName,
        first: 50,
      );

      if (kDebugMode) {        if (history.edges != null && history.edges!.isNotEmpty) {        }
      }

      final commits = history.edges
              ?.map((e) => e?.node)
              .whereType<GcommitListItem>()
              .toList() ??
          [];      data = CommitGraphData(
        commits: commits,
        branchTips: _branchTips ?? {},
        selectedBranch: branch,
      );
      loaded();
    } catch (e) {      error(error: e);
    }
  }

  /// Load a page of commits for pagination
  /// 
  /// [cursor] - Cursor from previous page (null for first page)
  /// [refresh] - Whether this is a refresh request
  /// Returns list of commits (20 per page)
  Future<List<GcommitListItem>> loadCommitsPage({
    String? cursor,
    bool refresh = false,
  }) async {
    // Reset cursor on refresh
    if (refresh) {
      _lastCursor = null;
    }

    final repo = repositoryProvider.data;
    final owner = repo.owner.when(
      user: (u) => u.login,
      organization: (o) => o.login,
      orElse: () => throw Exception('Invalid repository owner'),
    );
    final repoName = repo.name;
    final selectedBranch = branchName ?? repo.defaultBranchRef?.name ?? 'main';
    final fullRefName = selectedBranch.startsWith('refs/') 
        ? selectedBranch 
        : 'refs/heads/$selectedBranch';

    // Use provided cursor or last stored cursor
    final cursorToUse = cursor ?? _lastCursor;    final history = await RepositoryServices.getCommitsListGQL(
      owner: owner,
      repo: repoName,
      ref: fullRefName,
      first: 20,
      after: cursorToUse,
      refresh: refresh,
    );

    final commits = history.edges
            ?.map((e) => e?.node)
            .whereType<GcommitListItem>()
            .toList() ??
        [];

    // Store cursor from last edge for next page
    if (history.edges != null && history.edges!.isNotEmpty) {
      _lastCursor = history.edges!.last?.cursor;
    }    return commits;
  }
}

class CommitGraphData {
  CommitGraphData({
    required this.commits,
    required this.branchTips,
    required this.selectedBranch,
  });

  final List<GcommitListItem> commits;
  final Map<String, List<String>> branchTips;
  final String selectedBranch;
}

