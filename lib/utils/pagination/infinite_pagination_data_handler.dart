class PageRequest<T> {
  const PageRequest({
    this.page,
    this.pageSize,
    this.refresh,
    this.lastItem,
  });

  final int? page;
  final int? pageSize;
  final bool? refresh;
  final T? lastItem;
}

class InfinitePaginationDataHandler<T, R> {
  InfinitePaginationDataHandler({
    required this.fetchPage,
    this.groupItems,
    this.filterItems,
    this.tryMergeBoundary,
  });

  final Future<List<T>> Function(PageRequest<T> request) fetchPage;

  final List<R> Function(List<T> items)? groupItems;

  final List<R> Function(List<R> items)? filterItems;

  final R? Function(R previousLast, R nextFirst)? tryMergeBoundary;
}
