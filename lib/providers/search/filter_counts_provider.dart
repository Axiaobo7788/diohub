import 'package:diohub/models/search/search_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Key for storing counts by scope (repo_issues:owner/name, repo_pulls:owner/name, etc.).
String filterCountsScopeKey(SearchScope scope) {
  return switch (scope) {
    RepoIssuesScope(repo: final r) => 'repo_issues:${r.fullName}',
    RepoPullsScope(repo: final r) => 'repo_pulls:${r.fullName}',
    RepoDiscussionsScope(repo: final r) => 'repo_discussions:${r.fullName}',
    HomeIssuesScope() => 'home_issues',
    HomePullsScope() => 'home_pulls',
    UserReposScope(user: final u) => 'user_repos:${u.login}',
    _ => scope.tabKey,
  };
}

/// State held by [FilterCountsNotifier]: quick filter and custom filter counts per scope key.
class FilterCountsState {
  const FilterCountsState({
    this.quickFilterCounts = const {},
    this.customFilterCounts = const {},
  });

  final Map<String, Map<String, int>> quickFilterCounts;
  final Map<String, Map<String, int>> customFilterCounts;
}

class FilterCountsNotifier extends Notifier<FilterCountsState> {
  @override
  FilterCountsState build() => const FilterCountsState();

  void setQuickFilterCounts(SearchScope scope, Map<String, int> counts) {
    state = FilterCountsState(
      quickFilterCounts: {
        ...state.quickFilterCounts,
        filterCountsScopeKey(scope): counts
      },
      customFilterCounts: state.customFilterCounts,
    );
  }

  void setCustomFilterCounts(SearchScope scope, Map<String, int> counts) {
    state = FilterCountsState(
      quickFilterCounts: state.quickFilterCounts,
      customFilterCounts: {
        ...state.customFilterCounts,
        filterCountsScopeKey(scope): counts
      },
    );
  }
}

final filterCountsNotifierProvider =
    NotifierProvider<FilterCountsNotifier, FilterCountsState>(
  FilterCountsNotifier.new,
);

/// Quick filter count badges for [scope]. Keys are alias names (e.g. assignedToYouRepo_issues).
final quickFilterCountsProvider =
    Provider.family<Map<String, int>, SearchScope>((ref, scope) {
  final key = filterCountsScopeKey(scope);
  return ref.watch(filterCountsNotifierProvider).quickFilterCounts[key] ?? {};
});

/// Custom filter count badges for [scope]. Keys are filter ids.
final customFilterCountsProvider =
    Provider.family<Map<String, int>, SearchScope>((ref, scope) {
  final key = filterCountsScopeKey(scope);
  return ref.watch(filterCountsNotifierProvider).customFilterCounts[key] ?? {};
});
