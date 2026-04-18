import 'package:built_collection/built_collection.dart';

/// Result of a single timeline page fetch, with pagination metadata.
///
/// Result of a single timeline page fetch from the issues service.
class TimelinePageResult {
  const TimelinePageResult({
    required this.edges,
    required this.hasNextPage,
    this.hasPreviousPage = false,
    this.startCursor,
    this.endCursor,
  });

  final List<dynamic> edges;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final String? startCursor;
  final String? endCursor;
}
