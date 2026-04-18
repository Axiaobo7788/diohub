import 'package:diohub/common/search_overlay/filters.dart' show SearchType;
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub_models/models/search/search_type_counts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier that holds merged [SearchTypeCounts] from GQL search completions.
class SearchTypeCountsNotifier extends Notifier<SearchTypeCounts?> {
  @override
  SearchTypeCounts? build() => null;

  static SearchCountKind _kindForType(SearchType type) {
    return switch (type) {
      SearchType.repositories => SearchCountKind.repositories,
      SearchType.issuesPulls => SearchCountKind.issues,
      SearchType.users => SearchCountKind.users,
      SearchType.discussions => SearchCountKind.discussions,
      _ => throw ArgumentError('SearchType $type has no count kind'),
    };
  }

  /// Merge a single search response into current counts. Call when a GQL search completes.
  void mergeFromResponse(SearchType searchType, Map<String, dynamic>? rawData) {
    final kind = _kindForType(searchType);
    state = SearchTypeCounts.mergeFromResponse(state, rawData, kind);
  }
}

final searchTypeCountsNotifierProvider =
    NotifierProvider<SearchTypeCountsNotifier, SearchTypeCounts?>(
  SearchTypeCountsNotifier.new,
);

/// Type counts for global search. Non-null only when [scope] is [TypedGlobalSearchScope].
final searchTypeCountsProvider =
    Provider.family<SearchTypeCounts?, SearchScope>((ref, scope) {
  if (scope is! TypedGlobalSearchScope) return null;
  return ref.watch(searchTypeCountsNotifierProvider);
});
