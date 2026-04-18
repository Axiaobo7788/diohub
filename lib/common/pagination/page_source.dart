import 'package:diohub_models/models/pagination/page_slice.dart';

sealed class PageSource<T> {
  const PageSource();

  Future<PageSlice<T>> fetchForward(int count);
  void reset();
}

sealed class ForwardSource<T> extends PageSource<T> {
  const ForwardSource() : super();
}

final class CursorForwardSource<T> extends ForwardSource<T> {
  CursorForwardSource({required this.fetch});

  final Future<CursorPage<T>> Function({required int first, String? after})
      fetch;
  String? _afterCursor;

  @override
  Future<PageSlice<T>> fetchForward(int count) async {
    final page = await fetch(first: count, after: _afterCursor);
    _afterCursor = page.endCursor;
    return PageSlice<T>(
      items: page.items,
      hasNextPage: page.hasNextPage,
      totalCount: page.totalCount,
    );
  }

  @override
  void reset() {
    _afterCursor = null;
  }
}

final class PageNumberForwardSource<T> extends ForwardSource<T> {
  PageNumberForwardSource({
    required this.fetch,
    this.startPage = 1,
  }) : _page = startPage;

  final Future<List<T>> Function({required int page, required int perPage})
      fetch;
  final int startPage;
  int _page;

  @override
  Future<PageSlice<T>> fetchForward(int count) async {
    final items = await fetch(page: _page, perPage: count);
    _page++;
    return PageSlice<T>(
      items: items,
      hasNextPage: items.length >= count,
    );
  }

  @override
  void reset() {
    _page = startPage;
  }
}

/// Forward source that uses a single callback (e.g. mixed cursor/page logic).
final class SliceForwardSource<T> extends ForwardSource<T> {
  SliceForwardSource({
    required this.fetch,
    required this.resetState,
  });

  final Future<PageSlice<T>> Function(int count) fetch;
  final void Function() resetState;

  @override
  Future<PageSlice<T>> fetchForward(int count) => fetch(count);

  @override
  void reset() => resetState();
}

sealed class BidirectionalSource<T> extends PageSource<T> {
  const BidirectionalSource() : super();

  Future<PageSlice<T>> fetchBackward(int count);
  Future<AnchorResult<T>> resolveAnchor(String itemId);
  void resetBackward();
}

final class CursorBidirectionalSource<T> extends BidirectionalSource<T> {
  CursorBidirectionalSource({
    required this.forward,
    required this.backward,
    required this.anchor,
  });

  final Future<CursorPage<T>> Function({
    required int first,
    String? after,
  }) forward;
  final Future<CursorPage<T>> Function({
    required int last,
    String? before,
  }) backward;
  final Future<AnchorResult<T>> Function(String itemId) anchor;

  String? _afterCursor;
  String? _beforeCursor;

  @override
  Future<PageSlice<T>> fetchForward(int count) async {
    final page = await forward(first: count, after: _afterCursor);
    _afterCursor = page.endCursor;
    return PageSlice<T>(
      items: page.items,
      hasNextPage: page.hasNextPage,
      totalCount: page.totalCount,
    );
  }

  @override
  Future<PageSlice<T>> fetchBackward(int count) async {
    final page = await backward(last: count, before: _beforeCursor);
    _beforeCursor = page.startCursor;
    return PageSlice<T>(
      items: page.items,
      hasNextPage: page.hasNextPage,
      totalCount: page.totalCount,
    );
  }

  @override
  Future<AnchorResult<T>> resolveAnchor(String itemId) async {
    final result = await anchor(itemId);
    _afterCursor = result.forwardCursor;
    _beforeCursor = result.backwardCursor;
    return result;
  }

  @override
  void reset() {
    _afterCursor = null;
    _beforeCursor = null;
  }

  @override
  void resetBackward() {
    _beforeCursor = null;
  }
}
