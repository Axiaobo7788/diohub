import 'package:dio/dio.dart';
import 'package:diohub/app/app_logger.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';

/// Parse a REST search response (`/search/*`) into a [PaginatedResult].
PaginatedResult<T> parseRestSearchResponse<T>(
  final Response<dynamic> response, {
  required final T Function(Map<String, dynamic>) fromJson,
  required final int page,
  required final int perPage,
}) {
  final Map<String, dynamic>? body = response.data as Map<String, dynamic>?;
  final List<dynamic>? rawItems = body?['items'] as List<dynamic>?;
  final int totalCount = body?['total_count'] as int? ?? 0;

  final List<T> items = <T>[];
  for (final dynamic e in rawItems ?? <dynamic>[]) {
    if (e is Map<String, dynamic>) {
      try {
        items.add(fromJson(e));
      } on Object catch (err, st) {
        AppLogger.warning('Skipping malformed search item',
            error: err, stackTrace: st);
      }
    }
  }

  return PaginatedResult<T>(
    items: items,
    hasNextPage: page * perPage < totalCount,
    totalCount: totalCount,
  );
}
