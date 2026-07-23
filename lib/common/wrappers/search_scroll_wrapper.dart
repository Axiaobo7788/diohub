import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/search_overlay/filters.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/pagination/pagination.dart';
import 'package:diohub/common/search_overlay/search_type.dart';
import 'package:diohub/common/wrappers/app_custom_scroll_view.dart';
import 'package:diohub/models/search/search_type_config.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/search/issue_or_pull.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/models/search/search_state.dart';
import 'package:diohub/providers/search/search_state_notifier.dart';
import 'package:diohub/providers/search/search_type_counts_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

import 'package:diohub/common/nav_center/models/selection_state.dart';

/// Optional client-side filter for search result items.
typedef FilterFn = List<Object> Function(List<Object> items);

/// Optional presentation seam for search-backed pages that share pagination
/// and query state but render a page-specific row.
typedef SearchResultItemBuilder =
    Widget Function(BuildContext context, Object item, int index);

/// Test and integration seam for supplying a search adapter without replacing
/// the global API client.
typedef SearchTypeConfigFactory =
    SearchTypeConfig Function(WidgetRef ref, SearchScope scope);

/// Sliver-building search list for use inside a [CustomScrollView].
///
/// Use this when the list is part of a parent scroll view (e.g. NavCenter shell).
/// Returns a single sliver ([MultiSliver]) with header and paginated list.
/// For a full-screen scroll view, use [SearchScrollWrapper] which wraps this
/// in [AppCustomScrollView].
class SearchScrollSlivers extends ConsumerStatefulWidget {
  const SearchScrollSlivers(
    this.scope, {
    this.filterFn,
    this.showRepoNameOnIssues = true,
    this.showRepoOwner = true,
    this.firstPageLoadingBuilder,
    this.itemBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.listPadding,
    this.configFactory,
    this.onRefreshReady,
    this.onTotalCountChanged,
    super.key,
  });

  final SearchScope scope;
  final FilterFn? filterFn;
  final bool showRepoNameOnIssues;
  final bool showRepoOwner;
  final WidgetBuilder? firstPageLoadingBuilder;
  final SearchResultItemBuilder? itemBuilder;
  final WidgetBuilder? emptyBuilder;
  final Widget Function(BuildContext context, Object error, VoidCallback retry)?
  errorBuilder;
  final EdgeInsetsGeometry? listPadding;
  final SearchTypeConfigFactory? configFactory;

  /// When set, called with a callback that performs refresh once the internal
  /// pagination controller is ready. Used by [SearchListBody] for pull-to-refresh.
  final void Function(Future<void> Function()?)? onRefreshReady;
  final ValueChanged<int?>? onTotalCountChanged;

  @override
  ConsumerState<SearchScrollSlivers> createState() =>
      _SearchScrollSliversState();
}

class _SearchScrollSliversState extends ConsumerState<SearchScrollSlivers> {
  late final SearchTypeConfig _config;
  late final PaginationController<Object, Object> _paginationController;

  @override
  void initState() {
    super.initState();
    _config =
        widget.configFactory?.call(ref, widget.scope) ??
        widget.scope.searchType.config(
          ref,
          showRepoOwner: widget.showRepoOwner,
          showRepoNameOnIssues: widget.showRepoNameOnIssues,
        );
    _paginationController = PaginationController<Object, Object>(
      source: SliceForwardSource<Object>(
        fetch: (final int count) async {
          final SearchState state = ref.read(
            searchStateNotifierProvider(widget.scope),
          );
          final String query = state.apiQuery;
          final void Function(Map<String, dynamic>? rawData)? onCounts =
              widget.scope is TypedGlobalSearchScope
              ? (final Map<String, dynamic>? rawData) {
                  ref
                      .read(searchTypeCountsNotifierProvider.notifier)
                      .mergeFromResponse(
                        (widget.scope as TypedGlobalSearchScope).searchType,
                        rawData,
                      );
                }
              : null;
          AppLogger.info(
            'SearchScroll: fetching type=${ref.read(selectedSearchTypeProvider(widget.scope)).name} '
            'query="$query"',
            tag: 'SearchScroll',
          );
          try {
            return _config.fetchSlice(
              query: query,
              count: count,
              onRawResponse: onCounts,
            );
          } catch (e, st) {
            AppLogger.error(
              'SearchScroll: fetch failed for query="$query"',
              error: e,
              stackTrace: st,
              tag: 'SearchScroll',
            );
            rethrow;
          }
        },
        resetState: () => _config.resetState(),
      ),
      idOf: _config.itemId,
      filter: widget.filterFn,
      pageSize: 20,
    );
    _paginationController.state.addListener(_notifyTotalCount);
    widget.onRefreshReady?.call(() => _paginationController.refresh());
  }

  @override
  void dispose() {
    widget.onRefreshReady?.call(null);
    _paginationController.state.removeListener(_notifyTotalCount);
    _paginationController.dispose();
    super.dispose();
  }

  void _notifyTotalCount() {
    widget.onTotalCountChanged?.call(
      _paginationController.state.value.totalCount,
    );
  }

  Widget _buildItem(
    final BuildContext context,
    final Object item,
    final int index,
    final SelectionState selection,
    final String positionKey,
  ) {
    final SearchResultItemBuilder? itemBuilder = widget.itemBuilder;
    if (itemBuilder != null) {
      return itemBuilder(context, item, index);
    }
    final Widget card = _config.buildItem(context, item, index);
    if (widget.scope.searchType == SearchType.issuesPulls) {
      return _wrapIssuePullWithSelection(
        context,
        item as IssueOrPull,
        index,
        selection,
        positionKey,
        card,
      );
    }
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.itemSpacing),
      child: card,
    );
  }

  Widget _wrapIssuePullWithSelection(
    final BuildContext context,
    final IssueOrPull item,
    final int index,
    final SelectionState selection,
    final String positionKey,
    final Widget card,
  ) {
    final spacing = context.spacing;
    final String itemId;
    final Object refForSelection;
    switch (item) {
      case IssueResult(:final data):
        itemId = data.id;
        refForSelection = IssueRef.fromIssueCardFields(data);
      case PullResult(:final data):
        itemId = data.id;
        refForSelection = PullRequestRef.fromPullCardFields(data);
    }
    final bool isSelected = selection.selectedIds.contains(itemId);
    final notifier = ref.read(selectionModeProvider(positionKey).notifier);
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.itemSpacing),
      child: GestureDetector(
        onLongPress: () => notifier.toggle(itemId, refForSelection),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selection.isActive) ...[
              Padding(
                padding: EdgeInsets.only(top: spacing.sectionSpacing),
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => notifier.toggle(itemId, refForSelection),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              spacing.itemGap,
            ],
            Expanded(child: card),
          ],
        ),
      ),
    );
  }

  Widget _defaultFirstPageLoadingBuilder(final BuildContext context) =>
      _config.buildLoadingShimmer(context);

  @override
  Widget build(final BuildContext context) {
    final SearchState state = ref.watch(
      searchStateNotifierProvider(widget.scope),
    );
    ref.listen<SearchState>(searchStateNotifierProvider(widget.scope), (
      _,
      final SearchState next,
    ) {
      if (next.apiQuery != state.apiQuery) _paginationController.refresh();
    });
    ref.listen<SearchType>(selectedSearchTypeProvider(widget.scope), (_, __) {
      _paginationController.refresh();
    });

    final SearchType selectedType = ref.watch(
      selectedSearchTypeProvider(widget.scope),
    );
    final Widget listSliver = PaginatedSliverList<Object>(
      key: ValueKey<String>('${state.apiQuery}_${selectedType.name}'),
      controller: _paginationController,
      itemBuilder:
          (final BuildContext context, final Object item, final int index) =>
              _buildItem(
                context,
                item,
                index,
                ref.watch(selectionModeProvider(widget.scope.tabKey)),
                widget.scope.tabKey,
              ),
      loadingBuilder:
          widget.firstPageLoadingBuilder ?? _defaultFirstPageLoadingBuilder,
      emptyBuilder: widget.emptyBuilder,
      errorBuilder: widget.errorBuilder,
    );

    final spacing = context.spacing;
    return MultiSliver(
      children: <Widget>[
        SliverPadding(
          padding: widget.listPadding ?? spacing.listInset,
          sliver: listSliver,
        ),
      ],
    );
  }
}

/// Paginated search list driven by [SearchScope] and [searchStateNotifierProvider].
///
/// Watches [searchStateNotifierProvider(scope)]; state changes refresh pagination.
/// Fetch uses [SearchState.apiQuery] and [selectedSearchTypeProvider(scope)].
/// When used as the body of a route (standalone), this is the single scroll view.
///
/// **Do not use inside shell positions.** Shell positions must use [SearchListBody]
/// (which uses [SearchScrollSlivers]) so the shell's [AppCustomScrollView] is the only scroll view.
class SearchScrollWrapper extends ConsumerWidget {
  const SearchScrollWrapper(
    this.scope, {
    this.filterFn,
    this.showRepoNameOnIssues = true,
    this.showRepoOwner = true,
    this.firstPageLoadingBuilder,
    this.itemBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.listPadding,
    this.configFactory,
    this.onTotalCountChanged,
    super.key,
  });

  final SearchScope scope;
  final FilterFn? filterFn;
  final bool showRepoNameOnIssues;
  final bool showRepoOwner;
  final WidgetBuilder? firstPageLoadingBuilder;
  final SearchResultItemBuilder? itemBuilder;
  final WidgetBuilder? emptyBuilder;
  final Widget Function(BuildContext context, Object error, VoidCallback retry)?
  errorBuilder;
  final EdgeInsetsGeometry? listPadding;
  final SearchTypeConfigFactory? configFactory;
  final ValueChanged<int?>? onTotalCountChanged;

  @override
  Widget build(final BuildContext context, final WidgetRef _ref) {
    return AppCustomScrollView(
      slivers: <Widget>[
        SearchScrollSlivers(
          scope,
          filterFn: filterFn,
          showRepoNameOnIssues: showRepoNameOnIssues,
          showRepoOwner: showRepoOwner,
          firstPageLoadingBuilder: firstPageLoadingBuilder,
          itemBuilder: itemBuilder,
          emptyBuilder: emptyBuilder,
          errorBuilder: errorBuilder,
          listPadding: listPadding,
          configFactory: configFactory,
          onTotalCountChanged: onTotalCountChanged,
        ),
      ],
    );
  }
}
