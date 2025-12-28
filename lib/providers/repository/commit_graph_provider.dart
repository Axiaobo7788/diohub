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

  Map<String, List<String>>? get branchTips => _branchTips;
  List<String>? get availableBranches =>
      _allBranches?.map((b) => b.node?.name ?? '').where((n) => n.isNotEmpty).toList();

  Future<GcommitHistoryConnection> _loadCommitHistory({
    required String owner,
    required String repoName,
    required String refName,
  }) async {
    if (kDebugMode) {
      log.d('[CommitGraphProvider] Loading commits using ref: $refName');
    }
    
    try {
      final history = await RepositoryServices.getCommitsListGQL(
        owner: owner,
        repo: repoName,
        ref: refName,
        first: 50,
      );
      
      if (kDebugMode) {
        log.d('[CommitGraphProvider] Successfully loaded commits using ref query');
        log.d('[CommitGraphProvider] History connection edges count: ${history.edges?.length ?? 0}');
        log.d('[CommitGraphProvider] History connection hasNextPage: ${history.pageInfo.hasNextPage}');
        if (history.edges != null && history.edges!.isNotEmpty) {
          log.d('[CommitGraphProvider] First commit OID: ${history.edges!.first?.node?.oid}');
          log.d('[CommitGraphProvider] First edge node type: ${history.edges!.first?.node?.G__typename ?? "null"}');
        } else {
          log.w('[CommitGraphProvider] History edges is null or empty');
        }
      }
      return history;
    } catch (e) {
      if (kDebugMode) {
        log.e('[CommitGraphProvider] Error loading commits from "$refName": $e');
        log.w('[CommitGraphProvider] Falling back to default branch query');
      }
      
      // Fallback to default branch query
      final history = await RepositoryServices.getCommitsListGQL(
        owner: owner,
        repo: repoName,
        ref: null, // This triggers the default branch query path
        first: 50,
      );
      
      if (kDebugMode) {
        log.d('[CommitGraphProvider] Successfully loaded commits using default branch query');
      }
      return history;
    }
  }

  @override
  Future<CommitGraphData> setInitData({
    final bool isInitialisation = false,
  }) async {
    if (kDebugMode) {
      log.d('[CommitGraphProvider] setInitData called, branchName: $branchName');
    }

    final repo = repositoryProvider.data;
    final owner = repo.owner.when(
      user: (u) => u.login,
      organization: (o) => o.login,
      orElse: () => throw Exception('Invalid repository owner'),
    );
    final repoName = repo.name;

    if (kDebugMode) {
      log.d('[CommitGraphProvider] Loading branches for $owner/$repoName');
    }

    // Load all branches
    _allBranches = await RepositoryServices.fetchBranchListGQL(
      owner: owner,
      repo: repoName,
      first: 100,
    );

    if (kDebugMode) {
      log.d('[CommitGraphProvider] Loaded ${_allBranches?.length ?? 0} branches');
    }

    // Build branch tips map
    _branchTips = {};
    for (final branch in _allBranches!) {
      final target = branch.node?.target;
      final branchName = branch.node?.name;
      
      if (kDebugMode && branchName != null) {
        log.d('[CommitGraphProvider] Processing branch: $branchName, target type: ${target?.G__typename ?? "null"}');
      }
      
      final commitOid = target?.when(
        commit: (c) => c.oid,
        orElse: () {
          if (kDebugMode && branchName != null) {
            log.w('[CommitGraphProvider] Branch "$branchName" target is not a Commit (type: ${target.G__typename})');
          }
          return null;
        },
      );
      
      if (commitOid != null && branchName != null) {
        _branchTips!.putIfAbsent(commitOid, () => []).add(branchName);
      }
    }

    if (kDebugMode) {
      log.d('[CommitGraphProvider] Built branch tips map with ${_branchTips!.length} commit OIDs');
      final totalBranchLabels = _branchTips!.values.fold<int>(0, (sum, list) => sum + list.length);
      log.d('[CommitGraphProvider] Total branch labels: $totalBranchLabels');
      
      // Log the actual contents of the map
      if (_branchTips!.isNotEmpty) {
        log.d('[CommitGraphProvider] Branch tips map contents:');
        for (final entry in _branchTips!.entries) {
          log.d('[CommitGraphProvider]   OID: ${entry.key}, Branches: ${entry.value}');
        }
      } else {
        log.w('[CommitGraphProvider] Branch tips map is EMPTY - no branches were loaded as Commits');
      }
    }

    // Load commits from selected branch or default branch
    final selectedBranch = branchName ?? repo.defaultBranchRef?.name ?? 'main';
    // Use full ref name format: refs/heads/main
    final fullRefName = selectedBranch.startsWith('refs/') 
        ? selectedBranch 
        : 'refs/heads/$selectedBranch';
    
    if (kDebugMode) {
      log.d('[CommitGraphProvider] Selected branch: $selectedBranch');
      log.d('[CommitGraphProvider] Full ref name: $fullRefName');
      log.d('[CommitGraphProvider] Default branch from repo: ${repo.defaultBranchRef?.name}');
    }

    // Load history using ref name (always use full ref format)
    final history = await _loadCommitHistory(
      owner: owner,
      repoName: repoName,
      refName: fullRefName,
    );

    if (kDebugMode) {
      log.d('[CommitGraphProvider] History edges before conversion: ${history.edges?.length ?? 0}');
      if (history.edges != null && history.edges!.isNotEmpty) {
        log.d('[CommitGraphProvider] First edge node type: ${history.edges!.first?.node?.G__typename ?? "null"}');
        log.d('[CommitGraphProvider] First edge node is GcommitListItem: ${history.edges!.first?.node is GcommitListItem}');
      }
    }

    // Convert to list of commits
    final commits = history.edges
            ?.map((e) => e?.node)
            .whereType<GcommitListItem>()
            .toList() ??
        [];

    if (kDebugMode) {
      log.d('[CommitGraphProvider] Converted commits: ${commits.length}');
      log.d('[CommitGraphProvider] Loaded ${commits.length} commits from $selectedBranch');
      log.d('[CommitGraphProvider] Graph will have ${commits.length} nodes');
      
      // Count edges (parent relationships)
      int edgeCount = 0;
      for (final commit in commits) {
        final parentOids = commit.parents.edges
                ?.map((e) => e?.node?.oid)
                .whereType<String>()
                .toList() ??
            [];
        edgeCount += parentOids.length;
      }
      log.d('[CommitGraphProvider] Graph will have $edgeCount edges');
    }

    return CommitGraphData(
      commits: commits,
      branchTips: _branchTips!,
      selectedBranch: selectedBranch,
    );
  }

  Future<void> loadBranchCommits(String branch) async {
    if (kDebugMode) {
      log.d('[CommitGraphProvider] loadBranchCommits called for branch: $branch');
    }
    
    loading();
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
          : 'refs/heads/$branch';
      
      if (kDebugMode) {
        log.d('[CommitGraphProvider] Loading commits from branch: $branch (owner: $owner, repo: $repoName)');
        log.d('[CommitGraphProvider] Using full ref name: $fullRefName');
      }

      final history = await RepositoryServices.getCommitsListGQL(
        owner: owner,
        repo: repoName,
        ref: fullRefName,
        first: 50,
      );

      if (kDebugMode) {
        log.d('[CommitGraphProvider] History edges before conversion: ${history.edges?.length ?? 0}');
        if (history.edges != null && history.edges!.isNotEmpty) {
          log.d('[CommitGraphProvider] First edge node type: ${history.edges!.first?.node?.G__typename ?? "null"}');
          log.d('[CommitGraphProvider] First edge node is GcommitListItem: ${history.edges!.first?.node is GcommitListItem}');
        }
      }

      final commits = history.edges
              ?.map((e) => e?.node)
              .whereType<GcommitListItem>()
              .toList() ??
          [];

      if (kDebugMode) {
        log.d('[CommitGraphProvider] Loaded ${commits.length} commits from branch $branch');
      }

      data = CommitGraphData(
        commits: commits,
        branchTips: _branchTips ?? {},
        selectedBranch: branch,
      );
      loaded();
    } catch (e) {
      if (kDebugMode) {
        log.e('[CommitGraphProvider] Error loading branch commits: $e');
      }
      error(error: e);
    }
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

