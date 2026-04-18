import 'package:diohub_models/models/pagination/paginated_result.dart';

/// What the controller receives. No cursors, no page numbers.
class PageSlice<T> {
  const PageSlice({
    required this.items,
    this.hasNextPage = true,
    this.totalCount,
  });

  final List<T> items;
  final bool hasNextPage;
  final int? totalCount;
}

/// Re-export for backward compatibility during migration
typedef CursorPage<T> = PaginatedResult<T>;

/// Anchor resolution result (bidirectional deep-link).
class AnchorResult<T> {
  const AnchorResult({
    required this.items,
    this.hasMoreForward = true,
    this.hasMoreBackward = true,
    this.forwardCursor,
    this.backwardCursor,
    this.totalCount,
  });

  final List<T> items;
  final bool hasMoreForward;
  final bool hasMoreBackward;
  final String? forwardCursor;
  final String? backwardCursor;
  final int? totalCount;
}
