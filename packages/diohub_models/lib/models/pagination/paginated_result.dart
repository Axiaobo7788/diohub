/// Cursor-based page fetch for paginated lists.
/// Returns a tuple of (items, hasNextPage, endCursor).
/// Used by [SliverListBody] for cursor-based lists.
typedef PaginatedFetcher<T> = Future<PaginatedResult<T>> Function({
  String? after,
  int first,
  bool refresh,
});

/// Like [PaginatedFetcher] but with an optional [query] for server-side filter/search.
/// Used by [SliverListBody] when [SliverListBody.fetcherWithQuery] is set (e.g. Labels, Branches, Tags).
typedef PaginatedFetcherWithQuery<T> = Future<PaginatedResult<T>> Function({
  String? after,
  int first,
  bool refresh,
  String? query,
});

/// Local interface for lens serialization.
abstract interface class LensSerializable {
  Map<String, dynamic> toLensJson();
}

/// Result of a paginated fetch.
/// Use [PaginatedResult.fromEdges] when a service returns a GraphQL-style
/// edges list and pageInfo so the same type is used app-wide.
class PaginatedResult<T> implements LensSerializable {
  const PaginatedResult({
    required this.items,
    required this.hasNextPage,
    this.endCursor,
    this.startCursor,
    this.totalCount,
  });

  /// From a GraphQL-style edges list and pageInfo (hasNextPage, endCursor).
  factory PaginatedResult.fromEdges(
    final List<T> edges,
    final bool hasNextPage,
    final String? endCursor, {
    final String? startCursor,
  }) =>
      PaginatedResult<T>(
        items: edges,
        hasNextPage: hasNextPage,
        endCursor: endCursor,
        startCursor: startCursor,
      );

  final List<T> items;
  final bool hasNextPage;
  final String? endCursor;
  final String? startCursor;
  final int? totalCount;

  @override
  Map<String, dynamic> toLensJson() => {
        'items': items.map((e) => _serializeItem(e)).toList(),
        'has_next_page': hasNextPage,
        if (endCursor != null) 'end_cursor': endCursor,
        if (startCursor != null) 'start_cursor': startCursor,
        if (totalCount != null) 'total_count': totalCount,
      };

  static dynamic _serializeItem(dynamic item) {
    if (item is LensSerializable) return item.toLensJson();
    if (item is Map) return item;
    return (item as dynamic).toJson();
  }
}
