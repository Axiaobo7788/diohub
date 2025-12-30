// ignore_for_file: avoid_classes_with_only_static_members

import 'package:diohub/app/api_handler/dio.dart';

/// PageInfo structure for GraphQL pagination
class PageInfo {
  const PageInfo({
    required this.hasNextPage,
    required this.endCursor,
  });

  final bool hasNextPage;
  final String? endCursor;
}

/// Generic pagination helper for GraphQL connections
///
/// This helper abstracts the common pattern of paginating through GraphQL
/// connections by following the cursor-based pagination pattern used by GitHub's API.
///
/// **Why this pattern?**
/// - GitHub GraphQL API uses cursor-based pagination (not offset-based)
/// - Each page returns a cursor that must be used to fetch the next page
/// - This is more efficient than offset pagination for large datasets
class GraphQLPaginationHelper {
  /// Paginate through a GraphQL connection
  ///
  /// **How it works:**
  /// 1. Fetches first page with null cursor
  /// 2. Extracts nodes and pageInfo from response
  /// 3. Continues fetching while hasNextPage is true
  /// 4. Uses endCursor from previous page for next request
  ///
  /// **Why extractors are functions:**
  /// - Different GraphQL queries have different response structures
  /// - Allows reuse across different connection types (repos, PRs, issues, etc.)
  /// - Keeps the helper generic and type-safe
  ///
  /// [fetchPage] - Function that fetches a page given a cursor
  /// [extractNodes] - Function that extracts nodes from the response
  /// [getPageInfo] - Function that extracts PageInfo from the response
  /// [maxPages] - Optional maximum number of pages to fetch (safety limit)
  static Future<List<T>> paginateConnection<T>({
    required Future<GQLResponse> Function(String? cursor) fetchPage,
    required List<T> Function(dynamic response) extractNodes,
    required PageInfo Function(dynamic response) getPageInfo,
    int? maxPages,
  }) async {
    final allNodes = <T>[];
    String? cursor;
    var pageCount = 0;
    var hasNext = true;

    // Loop until no more pages available
    // Note: We check hasNextPage AFTER fetching, not before, because:
    // - First request uses null cursor (no way to know if there's more)
    // - Subsequent requests check pageInfo from previous response
    while (hasNext) {
      // Safety check: prevent infinite loops if API misbehaves
      if (maxPages != null && pageCount >= maxPages) {
        break;
      }

      final response = await fetchPage(cursor);

      // Validate response before processing
      // This prevents null pointer errors downstream
      if (response.data == null) {
        throw Exception('Pagination query returned no data');
      }

      final nodes = extractNodes(response.data);
      final pageInfo = getPageInfo(response.data);

      // Accumulate nodes from all pages
      allNodes.addAll(nodes);

      // Update pagination state for next iteration
      hasNext = pageInfo.hasNextPage;
      cursor = pageInfo.endCursor;
      pageCount++;
    }

    return allNodes;
  }
}
