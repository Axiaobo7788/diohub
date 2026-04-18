import 'package:freezed_annotation/freezed_annotation.dart';

part 'pagination_sort.freezed.dart';

enum SortDirection { asc, desc }

/// Sort configuration for a paginated list.
@freezed
abstract class PaginationSort with _$PaginationSort {
  const PaginationSort._();

  const factory PaginationSort({
    required String field,
    required String label,
    @Default(SortDirection.asc) SortDirection direction,
  }) = _PaginationSort;

  PaginationSort reversed() => copyWith(
        direction: direction == SortDirection.asc
            ? SortDirection.desc
            : SortDirection.asc,
      );
}
