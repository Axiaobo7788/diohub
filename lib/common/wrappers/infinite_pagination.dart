import 'package:dio/dio.dart';
import 'package:diohub/app/global.dart';
import 'package:diohub/common/misc/button.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/wrappers/infinite_scroll_wrapper.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

/// Controller for managing infinite pagination state.
/// Provides methods to build sliver lists or regular lists with pagination.
class InfinitePaginationController<T> {
  InfinitePaginationController({
    required this.future,
    required this.builder,
    this.filterFn,
    this.pageNumber = 1,
    this.pageSize = 10,
    final EdgeInsets Function(BuildContext)? paddingBuilder,
    this.separatorBuilder,
    this.listEndIndicator = true,
    this.firstPageLoadingBuilder,
    this.emptyBuilder,
    this.enableStaggeredAnimation = true,
  }) : paddingBuilder = paddingBuilder ?? ((final _) => const EdgeInsets.symmetric(vertical: 16,));

  final ScrollWrapperFuture<T> future;
  final ScrollWrapperBuilder<T> builder;
  final FilterFn<T>? filterFn;
  final int pageNumber;
  final int pageSize;
  final EdgeInsets Function(BuildContext) paddingBuilder;
  final IndexedWidgetBuilder? separatorBuilder;
  final bool listEndIndicator;
  final WidgetBuilder? firstPageLoadingBuilder;
  final WidgetBuilder? emptyBuilder;
  final bool enableStaggeredAnimation;

  PagingController<int, _ListItem<T>>? _pagingController;
  bool _refresh = false;
  final Set<int> _animatedItems = <int>{};
  bool _hasStartedAnimating = false;

  PagingController<int, _ListItem<T>> get _controller {
    _pagingController ??= PagingController<int, _ListItem<T>>(
      value: PagingState<int, _ListItem<T>>(),
      fetchPage: _fetchPage,
      getNextPageKey: (final PagingState<int, _ListItem<T>> state) {
        if (state.pages == null || state.pages!.isEmpty) return 0;
        if (state.lastPageIsEmpty) return null;
        return state.nextIntPageKey;
      },
    );
    // Trigger initial page load on first access
    if (_pagingController!.value.pages == null ||
        _pagingController!.value.pages!.isEmpty) {
      _pagingController!.fetchNextPage();
    }
    return _pagingController!;
  }

  /// Refresh the pagination data.
  void refresh() {
    _refresh = true;
    _animatedItems.clear();
    _hasStartedAnimating = false;
    _controller.refresh();
  }

  /// Dispose the controller.
  void dispose() {
    _pagingController?.dispose();
    _pagingController = null;
  }

  Future<List<_ListItem<T>>> _fetchPage(final int pageKey) async {
    try {
      final int currentPageNumber = pageNumber + pageKey;

      final List<T> newItems = await future(
        ScrollWrapperFutureArguments<T>(
          pageNumber: currentPageNumber,
          pageSize: pageSize,
          refresh: _refresh,
          lastItem: (_pagingController?.value.items?.isNotEmpty ?? false)
              ? _pagingController!.value.items!.last.item
              : null,
        ),
      );

      List<T> filteredItems;
      if (filterFn != null) {
        filteredItems = filterFn!(newItems) ?? <T>[];
      } else {
        filteredItems = newItems;
      }

      if (filteredItems.length < pageSize) {
        _refresh = false;
      }

      return filteredItems
          .map((final T e) => _ListItem<T>(e, refresh: _refresh))
          .toList();
    } on DioException catch (error, s) {
      log.e(error.response?.data, stackTrace: s);
      rethrow;
    } catch (error) {
      log.e(
        'Pagination exception',
        error: error,
      );
      rethrow;
    }
  }

  Widget _buildItemBuilder(
    final BuildContext context,
    final PagingState<int, _ListItem<T>> state,
    final _ListItem<T> item,
    final int index,
  ) {
    final bool isRefresh = item.refreshChildren;

    bool shouldAnimate = false;
    if (enableStaggeredAnimation) {
      final bool isFirstPage = index < pageSize;
      final bool isInitialLoadPhase = _animatedItems.isEmpty ||
          (_animatedItems.isNotEmpty &&
              _animatedItems.every((final int i) => i < pageSize));

      shouldAnimate = !_animatedItems.contains(index) &&
          (isRefresh || (isFirstPage && isInitialLoadPhase));

      if (shouldAnimate) {
        _animatedItems.add(index);
        if (!_hasStartedAnimating) {
          _hasStartedAnimating = true;
        }
      }
    }

    final List<_ListItem<T>>? items = state.items;
    final T? previousItem =
        index > 0 && items != null ? items[index - 1].item : null;
    final T? nextItem = index < (items?.length ?? 0) - 1 && items != null
        ? items[index + 1].item
        : null;

    Widget child = builder(
      context,
      ScrollWrapperBuilderData<T>(
        item: item.item,
        index: index,
        refresh: isRefresh,
        isCurrentlyLast: (state.items?.length ?? 0) - 1 == index,
        previousItem: previousItem,
        nextItem: nextItem,
      ),
    );

    if (enableStaggeredAnimation && shouldAnimate) {
      child = _StaggeredAnimatedItem(
        key: ValueKey('animated_${item.item.hashCode}_$index'),
        index: index,
        shouldAnimate: shouldAnimate,
        child: child,
      );
    }

    final EdgeInsets paddingValue = paddingBuilder(context);
    return Padding(
      padding:  EdgeInsets.only(left: paddingValue.left, right: paddingValue.right,),
      child: Column(
        children: <Widget>[
          if (index == 0)
            SizedBox(
              height: paddingValue.top,
            ),
          child,
          if (index == (state.items?.length ?? 0) - 1)  SizedBox(
              height: paddingValue.bottom,
            ),
        ],
      ),
    );
  }

  PagedChildBuilderDelegate<_ListItem<T>> _buildDelegate(
    final BuildContext context,
    final PagingState<int, _ListItem<T>> state,
  ) => PagedChildBuilderDelegate<_ListItem<T>>(
      itemBuilder: (final BuildContext context, final _ListItem<T> item, final int index) =>
          _buildItemBuilder(context, state, item, index),
      firstPageProgressIndicatorBuilder: firstPageLoadingBuilder ??
          (final BuildContext context) => const Padding(
                padding: EdgeInsets.all(32),
                child: LoadingIndicator(),
              ),
      newPageProgressIndicatorBuilder: (final BuildContext context) =>
          const Padding(
        padding: EdgeInsets.all(32),
        child: LoadingIndicator(),
      ),
      noItemsFoundIndicatorBuilder: emptyBuilder ??
          (final BuildContext context) {
            final EdgeInsets paddingValue = paddingBuilder(context);
            return Center(
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: paddingValue.top,
                  ),
                  const Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Nothing to see here.',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
      noMoreItemsIndicatorBuilder: (final BuildContext context) {
        final EdgeInsets paddingValue = paddingBuilder(context);
        return listEndIndicator
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      Text(
                        '----*----',
                        style: context.textTheme.labelSmall?.asHint(),
                      ),
                      SizedBox(
                        height: paddingValue.bottom,
                      ),
                    ],
                  ),
                ),
              )
            : Padding(
                padding: EdgeInsets.only(bottom: paddingValue.bottom),
                child: Container(),
              );
      },
      firstPageErrorIndicatorBuilder: (final BuildContext context) =>
          _FirstPageErrorIndicator(
        onTryAgain: () => _controller.refresh(),
        error: state.error,
      ),
    );

  /// Builds a sliver list for use in CustomScrollView.
  Widget buildSliverList(final BuildContext context, {final Key? key}) => ValueListenableBuilder<PagingState<int, _ListItem<T>>>(
      valueListenable: _controller,
      builder: (final BuildContext context, final PagingState<int, _ListItem<T>> state, final _) =>
          PagedSliverList<int, _ListItem<T>>.separated(
        key: key,
        state: state,
        fetchNextPage: _controller.fetchNextPage,
        separatorBuilder: separatorBuilder ?? (final _, final __) => Container(),
        builderDelegate: _buildDelegate(context, state),
      ),
    );

  /// Builds a regular ListView.
  Widget buildListView(
    final BuildContext context, {
    final ScrollController? scrollController,
    final bool shrinkWrap = false,
    final ScrollPhysics? physics,
    final Key? key,
  }) => ValueListenableBuilder<PagingState<int, _ListItem<T>>>(
      valueListenable: _controller,
      builder: (final BuildContext context, final PagingState<int, _ListItem<T>> state, final _) =>
          PagedListView<int, _ListItem<T>>.separated(
        key: key,
        state: state,
        fetchNextPage: _controller.fetchNextPage,
        scrollController: scrollController,
        shrinkWrap: shrinkWrap,
        physics: physics,
        separatorBuilder: separatorBuilder ?? (final _, final __) => Container(),
        builderDelegate: _buildDelegate(context, state),
      ),
    );
}

class _ListItem<T> {
  _ListItem(this.item, {required this.refresh});

  final T item;
  bool refresh;

  bool get refreshChildren {
    final bool temp = refresh;
    refresh = false;
    return temp;
  }
}

class _FirstPageErrorIndicator extends StatelessWidget {
  const _FirstPageErrorIndicator({
    required this.error,
    this.onTryAgain,
  });

  final Object? error;
  final VoidCallback? onTryAgain;

  @override
  Widget build(final BuildContext context) => _FirstPageExceptionIndicator(
        title: 'Something went wrong',
        message: error is Error
            ? (error! as Error).stackTrace.toString()
            : error.toString(),
        onTryAgain: onTryAgain,
      );
}

class _FirstPageExceptionIndicator extends StatelessWidget {
  const _FirstPageExceptionIndicator({
    required this.title,
    this.message,
    this.onTryAgain,
  });

  final String title;
  final String? message;
  final VoidCallback? onTryAgain;

  @override
  Widget build(final BuildContext context) => Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 32,
          horizontal: 16,
        ),
        child: Button(
          onTap: onTryAgain,
          child: const Text(
            'Retry',
          ),
        ),
      ),
    );
}

/// Widget that animates items in with a staggered delay
class _StaggeredAnimatedItem extends StatefulWidget {
  const _StaggeredAnimatedItem({
    required this.index,
    required this.shouldAnimate,
    required this.child,
    super.key,
  });

  final int index;
  final bool shouldAnimate;
  final Widget child;

  @override
  State<_StaggeredAnimatedItem> createState() => _StaggeredAnimatedItemState();
}

class _StaggeredAnimatedItemState extends State<_StaggeredAnimatedItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    if (widget.shouldAnimate) {
      _controller.value = 0.0;
      final int delay = (widget.index * 50).clamp(0, 300);
      WidgetsBinding.instance.addPostFrameCallback((final _) {
        Future<void>.delayed(Duration(milliseconds: delay), () async {
          if (mounted && _controller.status == AnimationStatus.dismissed) {
            await _controller.forward();
          }
        });
      });
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: widget.child,
        ),
      );
}
