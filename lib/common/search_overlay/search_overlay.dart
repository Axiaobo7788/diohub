import 'package:diohub/app/settings/search_state.dart';
import 'package:diohub/models/search/search_state.dart';
import 'package:diohub/utils/string_extensions.dart';

class SearchData {
  SearchData({
    this.query = '',
    this.filterStrings = const <String>[],
    this.sort = 'best',
    final bool multiType = false,
    final List<String> defaultHiddenFilters = const <String>[],
  })  : _defaultFilters = defaultHiddenFilters,
        multiType = multiType;

  /// Builds [SearchData] from scope-based [SearchState] for use with legacy
  /// bars (BasicSearchBar, AppSearchBar). Used when migrating to scope notifier.
  factory SearchData.fromSearchState(SearchState state) => SearchData(
        query: state.freeText,
        filterStrings:
            state.activeQualifiers.map((q) => q.toQueryFragment()).toList(),
        sort: state.sort?.key ?? 'best',
        multiType: true,
      );

  /// Current query info without filters.
  final String query;

  /// List of all applied filters.
  final List<String> filterStrings;

  /// Default filters that will be applied to the query without being visible.
  final List<String> _defaultFilters;

  /// Multi type query for universal search bars.
  final bool multiType;

  /// Current sort setting, defaults to 'best', which returns null on being queried.
  final String sort;

  /// Return string of the query without the default filters.
  @override
  String toString() => '${query.trim()} ${filterStrings.join(' ').trim()} ';

  /// Return string of the query with the default filters.
  String get toQuery =>
      '${query.trim()} ${_defaultFilters.join(' ').trim()} ${filterStrings.join(' ').trim()}';

  /// Get current sort setting. Returns null if it is "best".
  String? get getSort => sort != 'best' ? sort.split('-').first : null;

  /// Is sort setting ascending.
  bool? get isSortAsc => sort != 'best' ? sort.split('-').last == 'asc' : null;

  /// If search is active, i.e., [toString()] is not empty.
  bool get isActive => toString().trim().isNotEmpty;

  /// Get if a quick filter is currently in the filters.
  /// [quickFilterKeys] is the set of filter keys that count as "quick" in this context (from UI config).
  String? activeQuickFilter(final Iterable<String> quickFilterKeys) {
    final List<String> active = <String>[];
    for (final String element in filterStrings) {
      for (final String e in quickFilterKeys) {
        if (e.isStringEqual(element)) {
          active.add(element);
        }
      }
    }
    // Return null if more than one.
    if (active.length == 1) {
      return active.first;
    }
    return null;
  }

  /// If current query is valid.
  bool get isValid => toQuery.trim().isNotEmpty;

  /// Persistible state (sort, filterStrings, query) for this tab.
  PersistedSearchState toPersistedState() => PersistedSearchState(
        sort: sort,
        filterStrings: List<String>.from(filterStrings),
        query: query,
      );

  /// Apply previously persisted state; keeps _defaultFilters, multiType.
  SearchData applyPersistedState(final PersistedSearchState p) => copyWith(
        sort: p.sort,
        filterStrings: List<String>.from(p.filterStrings),
        query: p.query,
      );

  /// Clear all search related data.
  SearchData get cleared => copyWith(
        query: '',
        filterStrings: <String>[],
        sort: 'best',
      );

  /// Replace the quick filters in all the filters and add a new one.
  List<String> _quickFilterChange(
    final String quickFilter,
    final List<String> allFilters,
    final Iterable<String> quickFilterKeys,
  ) {
    final List<String> filters = allFilters.toList();
    return filters
      ..removeWhere((final String element) {
        bool exists = false;
        for (final String e in quickFilterKeys) {
          if (e.isStringEqual(element)) {
            exists = true;
          }
        }
        return exists;
      })
      ..add(quickFilter);
  }

  /// Copy search data with custom data.
  /// When [quickFilter] is set, pass [quickFilterKeys] (the list of quick filter keys for this context).
  SearchData copyWith({
    final String? query,
    final List<String>? filterStrings,
    final String? quickFilter,
    final List<String>? quickFilterKeys,
    final String? sort,
  }) {
    List<String> filters = filterStrings ?? this.filterStrings;
    if (quickFilter != null &&
        quickFilterKeys != null &&
        quickFilterKeys.isNotEmpty) {
      filters = _quickFilterChange(quickFilter, filters, quickFilterKeys);
    }
    return SearchData(
      query: query ?? this.query,
      filterStrings: filters,
      defaultHiddenFilters: _defaultFilters,
      multiType: multiType,
      sort: sort ?? this.sort,
    );
  }
}
