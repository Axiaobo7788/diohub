import 'package:dio/dio.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';

/// Extracts a list from a Dio response, handling cases where the response
/// data might not be a list (e.g., a Map or null).
/// Returns an empty list if the data is not a List.
List<T> extractListFromResponse<T>(Response<dynamic> response) =>
    response.data is List ? List<T>.from(response.data as List) : <T>[];

/// Parses a paginated REST response into a typed [PaginatedResult].
/// Uses the Link header to determine [hasNextPage] and sets [endCursor]
/// to the next page number when applicable.
PaginatedResult<T> parsePaginatedRestResponse<T>({
  required Response<dynamic> response,
  required List<T> items,
  required int currentPage,
}) {
  final String? link = response.headers.value('link');
  final bool hasNextPage = link != null && link.contains('rel="next"');
  return PaginatedResult<T>(
    items: items,
    hasNextPage: hasNextPage,
    endCursor: hasNextPage ? '${currentPage + 1}' : null,
  );
}
