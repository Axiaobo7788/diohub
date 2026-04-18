/// Pushes repo-scoped filter counts into [FilterCountsNotifier] when repo data
/// is available. Watched by the view so counts are populated without
/// side-effects in [RepositoryNotifier.build].
library;

import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/providers/database_providers.dart' show globalServicesProvider;
import 'package:diohub/providers/filters/custom_filters_notifier.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/providers/search/filter_counts_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// When watched, ensures quick and custom filter counts for this repo are
/// pushed to [FilterCountsNotifier] once [repositoryProvider] has data.
/// The view (e.g. filter popup for repo issues/pulls) watches this so the
/// push runs without side-effects in [RepositoryNotifier.build].
final repoFilterCountsProvider =
    FutureProvider.autoDispose.family<void, RepoRef>(
  (final Ref ref, final RepoRef repoRef) async {
    final data = await ref.watch(repositoryProvider(repoRef).future);
    final countsNotifier = ref.read(filterCountsNotifierProvider.notifier);
    
    final issuesScope = SearchScope.repoIssues(repo: repoRef);
    final issuesFilters = issuesScope.quickFilters;
    countsNotifier.setQuickFilterCounts(
      issuesScope,
      <String, int>{
        issuesFilters[0].aliasKeyForScope(issuesScope): data.assignedToYouRepo_issues.issueCount,
        issuesFilters[1].aliasKeyForScope(issuesScope): data.yourIssuesRepo_issues.issueCount,
        issuesFilters[2].aliasKeyForScope(issuesScope): data.mentionsYouRepo_issues.issueCount,
      },
    );
    
    final pullsScope = SearchScope.repoPulls(repo: repoRef);
    final pullsFilters = pullsScope.quickFilters;
    countsNotifier.setQuickFilterCounts(
      pullsScope,
      <String, int>{
        pullsFilters[0].aliasKeyForScope(pullsScope): data.assignedToYouRepo_pulls.issueCount,
        pullsFilters[1].aliasKeyForScope(pullsScope): data.yourPullRequestsRepo_pulls.issueCount,
        pullsFilters[2].aliasKeyForScope(pullsScope): data.mentionsYouRepo_pulls.issueCount,
      },
    );
    
    for (final scope in [issuesScope, pullsScope]) {
      final customFilters =
          ref.read(customFiltersNotifierProvider.notifier).forScope(scope);
      if (customFilters.isNotEmpty) {
        final counts = await ref.read(globalServicesProvider).search.fetchCustomFilterCounts(
          customFilters,
          scope,
        );
        countsNotifier.setCustomFilterCounts(scope, counts);
      }
    }
  },
);
