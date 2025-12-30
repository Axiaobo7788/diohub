// ignore_for_file: avoid_classes_with_only_static_members

import 'package:diohub/utils/pagination/graphql_pagination_helper.dart';

/// Response structure for paginated nested data
class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.nodes,
    required this.pageInfo,
  });

  final List<T> nodes;
  final PageInfo pageInfo;
}

/// Helper for paginating nested structures (e.g., commits within repos)
class NestedPaginationHelper {
  /// Paginate a nested connection (e.g., commits within repos)
  /// 
  /// [parentItems] - List of parent items (e.g., repositories)
  /// [fetchPage] - Function that fetches a page for a parent item given a cursor
  /// [getParentKey] - Function to extract parent key from a child item
  /// [maxPagesPerParent] - Optional maximum pages per parent item
  static Future<Map<K, List<T>>> paginateNestedConnection<K, T>({
    required List<K> parentItems,
    required Future<PaginatedResponse<T>> Function(K parent, String? cursor) fetchPage,
    required K Function(T item) getParentKey,
    int? maxPagesPerParent,
  }) async {
    final result = <K, List<T>>{};

    for (final parent in parentItems) {
      final items = <T>[];
      String? cursor;
      var hasNext = true;
      var pageCount = 0;

      while (hasNext) {
        if (maxPagesPerParent != null && pageCount >= maxPagesPerParent) {
          break;
        }

        final response = await fetchPage(parent, cursor);
        items.addAll(response.nodes);
        hasNext = response.pageInfo.hasNextPage;
        cursor = response.pageInfo.endCursor;
        pageCount++;
      }

      result[parent] = items;
    }

    return result;
  }
}

