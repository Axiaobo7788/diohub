/// Persisted search state for a single tab (sort, filter strings, query).
class PersistedSearchState {
  const PersistedSearchState({
    this.sort = 'best',
    this.filterStrings = const <String>[],
    this.qualifierStrings,
    this.query = '',
  });

  final String sort;
  final List<String> filterStrings;

  /// Typed qualifier fragments (e.g. "is:open", "label:bug"). When non-null
  /// preferred over [filterStrings] for parsing. Backward compat: fallback to
  /// [filterStrings] when null.
  final List<String>? qualifierStrings;
  final String query;

  factory PersistedSearchState.fromJson(final Map<String, dynamic> json) =>
      PersistedSearchState(
        sort: json['sort'] as String? ?? 'best',
        filterStrings: (json['filterStrings'] as List<dynamic>?)
                ?.map((final dynamic e) => e as String)
                .toList() ??
            const <String>[],
        qualifierStrings: (json['qualifierStrings'] as List<dynamic>?)
            ?.map((final dynamic e) => e as String)
            .toList(),
        query: json['query'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'sort': sort,
        'filterStrings': filterStrings,
        if (qualifierStrings != null) 'qualifierStrings': qualifierStrings,
        'query': query,
      };

  PersistedSearchState copyWith({
    final String? sort,
    final List<String>? filterStrings,
    final List<String>? qualifierStrings,
    final String? query,
  }) =>
      PersistedSearchState(
        sort: sort ?? this.sort,
        filterStrings: filterStrings ?? this.filterStrings,
        qualifierStrings: qualifierStrings ?? this.qualifierStrings,
        query: query ?? this.query,
      );
}
