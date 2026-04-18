import 'package:diohub_models/models/search/sort_config.dart';

/// Shared sort option lists for search scopes to avoid duplication.
abstract final class SearchSortConfigs {
  SearchSortConfigs._();

  static const SortConfig issuesPullsSort = SortConfig([
    SortOption(key: 'best', displayName: 'Best Match'),
    SortOption(key: 'created-desc', displayName: 'Newest'),
    SortOption(key: 'created-asc', displayName: 'Oldest'),
    SortOption(key: 'comments-desc', displayName: 'Most comments'),
    SortOption(key: 'comments-asc', displayName: 'Least comments'),
    SortOption(key: 'updated-desc', displayName: 'Recently updated'),
    SortOption(key: 'updated-asc', displayName: 'Least recently updated'),
    SortOption(key: 'reactions-desc', displayName: 'Most reactions'),
    SortOption(key: 'reactions-asc', displayName: 'Least reactions'),
  ]);

  static const SortConfig repositoriesSort = SortConfig([
    SortOption(key: 'best', displayName: 'Best Match'),
    SortOption(key: 'stars-desc', displayName: 'Most stars'),
    SortOption(key: 'stars-asc', displayName: 'Fewest stars'),
    SortOption(key: 'forks-desc', displayName: 'Most forks'),
    SortOption(key: 'forks-asc', displayName: 'Least forks'),
    SortOption(key: 'updated-desc', displayName: 'Recently updated'),
    SortOption(key: 'updated-asc', displayName: 'Least recently updated'),
  ]);
}
