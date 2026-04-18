import 'package:diohub/common/nav_center/models/compose_bar_config.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/pagination/pagination.dart';
import 'package:diohub/common/search/client_text_matcher.dart';
import 'package:diohub/common/search/match_strategy.dart';
import 'package:diohub/common/search_overlay/list_search_bar.dart';
import 'package:diohub/common/wrappers/app_custom_scroll_view.dart';
import 'package:diohub/common/wrappers/search_scroll_wrapper.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

/// Shared list body that takes a [PageSource]. Used by [SliverListBody] (cursor)
/// and [SliverListBody.page] (page-based). Single implementation for both pagination types.
/// [itemBuilder] is (context, item) only; list items that need [ref] should be [Consumer] (or contain one).
class SourceSliverListBody<T> extends TabBody {
  SourceSliverListBody({
    required this.source,
    required this.idOf,
    required this.itemBuilder,
    this.pageSize = 20,
    this.refreshTrigger,
  }) : _controller = null,
       _refreshTriggerListener = null,
       _refreshListenerAdded = false;

  final PageSource<T> source;
  final String Function(T) idOf;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final int pageSize;
  final ValueNotifier<int>? refreshTrigger;

  PaginationController<T, T>? _controller;
  VoidCallback? _refreshTriggerListener;
  bool _refreshListenerAdded = false;

  PaginationController<T, T> get _paginationController {
    if (_controller != null) return _controller!;
    _controller = PaginationController<T, T>(
      source: source,
      idOf: idOf,
      pageSize: pageSize,
    );
    if (refreshTrigger != null && !_refreshListenerAdded) {
      _refreshListenerAdded = true;
      _refreshTriggerListener = () => _controller?.refresh();
      refreshTrigger!.addListener(_refreshTriggerListener!);
    }
    return _controller!;
  }

  /// Exposes the controller for client-side filtered list (e.g. [SliverListBody] with [clientFilter]).
  PaginationController<T, T> get controller => _paginationController;

  void refresh() => _paginationController.refresh();

  @override
  bool get canRefresh => true;

  @override
  Future<void>? performRefresh() =>
      _controller?.refresh() ?? Future<void>.value();

  @override
  List<Widget> buildSliversWithRef(
    final BuildContext context,
    final WidgetRef ref,
  ) {
    final spacing = context.spacing;
    final listSliver = PaginatedSliverList<T>(
      controller: _paginationController,
      itemBuilder: (final BuildContext ctx, final T item, final int index) {
        final child = itemBuilder(ctx, item);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (index > 0) SizedBox(height: spacing.itemSpacing),
            child,
          ],
        );
      },
    );
    return [SliverPadding(padding: spacing.listInset, sliver: listSliver)];
  }

  @override
  void dispose() {
    if (refreshTrigger != null && _refreshTriggerListener != null) {
      refreshTrigger!.removeListener(_refreshTriggerListener!);
      _refreshTriggerListener = null;
    }
    _controller?.dispose();
    _controller = null;
  }
}

/// Cursor-paginated list body. [buildSliversWithRef] returns list slivers for the shell's [AppCustomScrollView].
/// No nested scroll: uses [PaginatedSliverList] so the shell's ACSV is the only scroll view.
/// When [fetcherWithQuery] is non-null, a search bar is shown and the query is passed to the fetcher.
/// When [queryNotifier] is provided, that notifier drives the query and no in-body search bar is shown
/// (use [InlineSearchDockPill] with the same notifier in the dock).
/// When [clientFilter] is set with [queryNotifier] and [fetcher] (no [fetcherWithQuery]), the list
/// is filtered client-side by the query string.
class SliverListBody<T> extends TabBody {
  SliverListBody({
    this.fetcher,
    this.fetcherWithQuery,
    required this.itemBuilder,
    required this.getCursor,
    this.pageSize = 20,
    this.hintText = 'Filter',
    this.refreshTrigger,
    this.queryNotifier,
    this.clientFilter,
  }) : assert(fetcher != null || fetcherWithQuery != null),
       fetch = null,
       idOf = null,
       _delegate = null,
       _pageDelegate = null,
       _internalQueryNotifier = ValueNotifier('');

  /// Creates a [SliverListBody] with client-side text filtering.
  ///
  /// Replaces the common pattern of manually writing [clientFilter] closures.
  /// When [queryNotifier] is null, filtering is disabled ([clientFilter] is null).
  factory SliverListBody.textFilter({
    required List<String? Function(T item)> fields,
    MatchStrategy strategy = const SubstringMatch(),
    ValueNotifier<String>? queryNotifier,
    required PaginatedFetcher<T> fetcher,
    required Widget Function(BuildContext context, T item) itemBuilder,
    required String? Function(T? item) getCursor,
    int pageSize = 20,
    String hintText = 'Filter',
    ValueNotifier<int>? refreshTrigger,
  }) => SliverListBody<T>(
    fetcher: fetcher,
    itemBuilder: itemBuilder,
    getCursor: getCursor,
    pageSize: pageSize,
    hintText: hintText,
    refreshTrigger: refreshTrigger,
    queryNotifier: queryNotifier,
    clientFilter: queryNotifier == null
        ? null
        : ClientTextMatcher<T>(
            fields: fields,
            strategy: strategy,
          ).toClientFilter(),
  );

  /// Page-based constructor. Use [SliverListBody.page] factory instead.
  SliverListBody._page({
    required Future<List<T>> Function({required int page, required int perPage})
    this.fetch,
    required this.idOf,
    required this.itemBuilder,
    this.pageSize = 20,
    this.refreshTrigger,
  }) : fetcher = null,
       fetcherWithQuery = null,
       getCursor = _throwCursor,
       hintText = 'Filter',
       queryNotifier = null,
       clientFilter = null,
       _delegate = null,
       _pageDelegate = null,
       _internalQueryNotifier = ValueNotifier('');

  static String? _throwCursor<T>(T? _) =>
      throw StateError('page-based body has no cursor');

  /// Cursor-based fetch (no query). Use when no search bar is needed.
  final PaginatedFetcher<T>? fetcher;

  /// Fetch with optional query (search bar). When set, [ListSearchBar] is shown above the list (unless [queryNotifier] is set).
  final PaginatedFetcherWithQuery<T>? fetcherWithQuery;

  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Extracts cursor from last item for next page (e.g. [T] is edge type with `.cursor`).
  final String? Function(T? item) getCursor;
  final int pageSize;
  final String hintText;

  /// When non-null (and [fetcherWithQuery] is set), the list refreshes when this notifier's value changes.
  final ValueNotifier<int>? refreshTrigger;

  /// When non-null, this notifier drives the search query and no in-body [ListSearchBar] is shown.
  /// Use with [InlineSearchDockPill] so the dock pill and list share the same query.
  final ValueNotifier<String>? queryNotifier;

  /// When non-null with [queryNotifier] and [fetcher] (no [fetcherWithQuery]), filters displayed items by query (client-side).
  final bool Function(T item, String query)? clientFilter;

  /// Page-based fetch (only set when using [SliverListBody.page]).
  final Future<List<T>> Function({required int page, required int perPage})?
  fetch;
  final String Function(T)? idOf;

  ValueNotifier<String> get _queryNotifier =>
      queryNotifier ?? _internalQueryNotifier;
  final ValueNotifier<String> _internalQueryNotifier;
  SourceSliverListBody<T>? _delegate;
  SourceSliverListBody<T>? _pageDelegate;

  bool get _isPageMode => fetch != null;

  bool get _hasSearch => fetcherWithQuery != null;

  SourceSliverListBody<T> get _sourceDelegate {
    if (_delegate != null) return _delegate!;
    final useQuery = _hasSearch;
    _delegate = SourceSliverListBody<T>(
      source: CursorForwardSource<T>(
        fetch: ({required int first, String? after}) async {
          if (useQuery) {
            final result = await fetcherWithQuery!(
              after: after,
              first: first,
              refresh: after == null,
              query: _queryNotifier.value.isEmpty ? null : _queryNotifier.value,
            );
            return CursorPage<T>(
              items: result.items,
              hasNextPage: result.hasNextPage,
              endCursor: result.endCursor,
              totalCount: result.totalCount,
            );
          }
          final result = await fetcher!(
            after: after,
            first: first,
            refresh: after == null,
          );
          return CursorPage<T>(
            items: result.items,
            hasNextPage: result.hasNextPage,
            endCursor: result.endCursor,
            totalCount: result.totalCount,
          );
        },
      ),
      idOf: (T e) => getCursor(e) ?? '',
      itemBuilder: itemBuilder,
      pageSize: pageSize,
      refreshTrigger: refreshTrigger,
    );
    return _delegate!;
  }

  SourceSliverListBody<T> get _pageSourceDelegate {
    if (_pageDelegate != null) return _pageDelegate!;
    _pageDelegate = SourceSliverListBody<T>(
      source: PageNumberForwardSource<T>(fetch: fetch!),
      idOf: idOf!,
      itemBuilder: itemBuilder,
      pageSize: pageSize,
      refreshTrigger: refreshTrigger,
    );
    return _pageDelegate!;
  }

  /// Page-based pagination. Use for REST APIs that use [page] and [per_page].
  /// No cursor/string flow; [PageNumberForwardSource] handles page increment and hasMore.
  factory SliverListBody.page({
    required Future<List<T>> Function({required int page, required int perPage})
    fetch,
    required String Function(T) idOf,
    required Widget Function(BuildContext context, T item) itemBuilder,
    int pageSize = 20,
    ValueNotifier<int>? refreshTrigger,
  }) => SliverListBody<T>._page(
    fetch: fetch,
    idOf: idOf,
    itemBuilder: itemBuilder,
    pageSize: pageSize,
    refreshTrigger: refreshTrigger,
  );

  @override
  bool get canRefresh => true;

  @override
  Future<void>? performRefresh() {
    if (_isPageMode) return _pageSourceDelegate.performRefresh();
    return _sourceDelegate.performRefresh();
  }

  bool get _hasClientFilter =>
      queryNotifier != null && clientFilter != null && fetcher != null;

  @override
  List<Widget> buildSliversWithRef(
    final BuildContext context,
    final WidgetRef ref,
  ) {
    if (_isPageMode) {
      return _pageSourceDelegate.buildSliversWithRef(context, ref);
    }
    if (_hasClientFilter) {
      final delegate = _sourceDelegate;
      final spacing = context.spacing;
      return <Widget>[
        SliverPadding(
          padding: spacing.listInset,
          sliver: _ClientFilteredSliverList<T>(
            controller: delegate.controller,
            queryNotifier: queryNotifier!,
            clientFilter: clientFilter!,
            itemBuilder: (ctx, item) => itemBuilder(ctx, item),
            spacing: spacing,
          ),
        ),
      ];
    }
    final delegate = _sourceDelegate;
    final padded = delegate.buildSliversWithRef(context, ref);
    if (_hasSearch) {
      final showInBodySearchBar = queryNotifier == null;
      return <Widget>[
        if (showInBodySearchBar)
          SliverToBoxAdapter(
            child: ListSearchBar(
              queryNotifier: _queryNotifier,
              hintText: hintText,
              onQueryChanged: () => delegate.refresh(),
            ),
          ),
        ...padded,
      ];
    }
    return padded;
  }

  @override
  void dispose() {
    if (_isPageMode) {
      _internalQueryNotifier.dispose();
      _pageDelegate?.dispose();
      _pageDelegate = null;
    } else {
      // Dispose internal notifier when we use it (_hasSearch) or when we use external (queryNotifier != null) so we don't leak it.
      if (_hasSearch || queryNotifier != null) _internalQueryNotifier.dispose();
      _delegate?.dispose();
      _delegate = null;
    }
  }
}

/// Sliver that shows [controller]'s items filtered by [queryNotifier] using [clientFilter].
/// Rebuilds when the notifier or controller state changes.
class _ClientFilteredSliverList<T> extends StatefulWidget {
  const _ClientFilteredSliverList({
    required this.controller,
    required this.queryNotifier,
    required this.clientFilter,
    required this.itemBuilder,
    required this.spacing,
  });

  final PaginationController<T, T> controller;
  final ValueNotifier<String> queryNotifier;
  final bool Function(T item, String query) clientFilter;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final AppSpacing spacing;

  @override
  State<_ClientFilteredSliverList<T>> createState() =>
      _ClientFilteredSliverListState<T>();
}

class _ClientFilteredSliverListState<T>
    extends State<_ClientFilteredSliverList<T>> {
  late VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _listener = () => setState(() {});
    widget.queryNotifier.addListener(_listener);
    widget.controller.state.addListener(_listener);
  }

  @override
  void didUpdateWidget(covariant _ClientFilteredSliverList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.queryNotifier != widget.queryNotifier) {
      oldWidget.queryNotifier.removeListener(_listener);
      widget.queryNotifier.addListener(_listener);
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.state.removeListener(_listener);
      widget.controller.state.addListener(_listener);
    }
  }

  @override
  void dispose() {
    widget.queryNotifier.removeListener(_listener);
    widget.controller.state.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.controller.state.value.items;
    final query = widget.queryNotifier.value.trim().toLowerCase();
    final filtered = query.isEmpty
        ? items
        : items.where((T i) => widget.clientFilter(i, query)).toList();
    final spacing = widget.spacing;
    return SliverList.builder(
      itemCount: filtered.length,
      itemBuilder: (BuildContext context, int index) {
        final item = filtered[index];
        final child = widget.itemBuilder(context, item);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (index > 0) SizedBox(height: spacing.itemSpacing),
            child,
          ],
        );
      },
    );
  }
}

/// Diff file list fetch (PR files, commit changed files).
/// TODO(future): Replace dynamic with concrete type when body type is wired.
typedef DiffFetcher = Future<List<dynamic>> Function({bool refresh});

/// Code tree fetch (repository code browser).
/// TODO(future): Replace dynamic with concrete type when body type is wired.
typedef TreeFetcher =
    Future<List<dynamic>> Function({required String path, required String ref});

/// Body that creates and delegates to an inner [TabBody] in [buildSliversWithRef],
/// so [ref] is only used at build time. Use when the inner body needs [ref] (e.g. for
/// refresh trigger or fetcher). Caches the inner body after first build.
class DelegatingTabBody extends TabBody {
  DelegatingTabBody({required this.createBody});

  final TabBody Function(WidgetRef ref) createBody;

  TabBody? _inner;

  @override
  List<Widget> buildSliversWithRef(BuildContext context, WidgetRef ref) {
    _inner ??= createBody(ref);
    return _inner!.buildSliversWithRef(context, ref);
  }

  @override
  bool get canRefresh => _inner?.canRefresh ?? false;

  @override
  Future<void>? performRefresh() => _inner?.performRefresh();

  @override
  void dispose() {
    _inner?.dispose();
    _inner = null;
  }
}

/// Body that stacks multiple sections, each with a header and a [TabBody].
/// Use for Security (Dependabot + Code Scanning) or other multi-section tabs.
class SectionedSliverBody extends TabBody {
  SectionedSliverBody({required this.sections});

  final List<({String title, TabBody body})> sections;

  @override
  bool get canRefresh => sections.any((s) => s.body.canRefresh);

  @override
  Future<void>? performRefresh() async {
    for (final s in sections) {
      final f = s.body.performRefresh();
      if (f != null) await f;
    }
    return null;
  }

  @override
  List<Widget> buildSliversWithRef(
    final BuildContext context,
    final WidgetRef ref,
  ) {
    final spacing = context.spacing;
    final theme = Theme.of(context);
    final List<Widget> result = [];
    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      if (i > 0) {
        result.add(SliverToBoxAdapter(child: spacing.sectionGap));
      }
      result.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              left: spacing.listInset.left,
              right: spacing.listInset.right,
              bottom: spacing.tightSpacing,
            ),
            child: Text(
              section.title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
      result.addAll(section.body.buildSliversWithRef(context, ref));
    }
    return result;
  }

  @override
  void dispose() {
    for (final s in sections) {
      s.body.dispose();
    }
  }
}

/// Body that shows one of several sub-bodies based on a watched tab index.
/// Use for tabs with nav pills (e.g. Keys: SSH / GPG / Signing).
/// Caches sub-bodies lazily and disposes them on [dispose].
class TabSwitcherBody extends TabBody {
  TabSwitcherBody({
    required this.tabIndexProvider,
    required this.createBodyForTab,
  });

  /// A provider or listenable that [ref.watch] can observe for the current tab index.
  final ProviderListenable<int> tabIndexProvider;
  final TabBody Function(int tabIndex) createBodyForTab;

  final List<TabBody?> _bodies = [null, null, null];
  int _lastIndex = 0;

  @override
  bool get canRefresh => _bodies[_lastIndex]?.canRefresh ?? false;

  @override
  Future<void>? performRefresh() => _bodies[_lastIndex]?.performRefresh();

  @override
  List<Widget> buildSliversWithRef(
    final BuildContext context,
    final WidgetRef ref,
  ) {
    final int index = ref.watch(tabIndexProvider).clamp(0, _bodies.length - 1);
    _lastIndex = index;
    _bodies[index] ??= createBodyForTab(index);
    return _bodies[index]!.buildSliversWithRef(context, ref);
  }

  @override
  void dispose() {
    for (var i = 0; i < _bodies.length; i++) {
      _bodies[i]?.dispose();
      _bodies[i] = null;
    }
  }
}

/// Determines how a tab's body is rendered by the framework.
///
/// The shell always wraps body content in [AppCustomScrollView]. Each body type
/// returns slivers (e.g. [SliverFillRemaining] wrapping its content).
/// State that must be shared (e.g. search controller, refresh trigger) lives on
/// the body instance; call [dispose] when the shell is disposed.
sealed class TabBody {
  const TabBody();

  /// Slivers to display inside the shell's [AppCustomScrollView]. Body types
  /// may wrap their content in [SliverFillRemaining] or other slivers.
  /// The shell and any caller with [ref] use this single entry point; ignore [ref] if not needed.
  List<Widget> buildSliversWithRef(
    final BuildContext context,
    final WidgetRef ref,
  ) => [];

  /// Whether this body supports pull-to-refresh. When true, [performRefresh]
  /// will return a non-null future. Use this to decide whether to pass [onRefresh]
  /// without calling [performRefresh] (which would start a refresh).
  bool get canRefresh => false;

  /// When [canRefresh] is true, starts a refresh and returns a [Future] that
  /// completes when the first page of that refresh has finished (success or error).
  /// The shell uses it for pull-to-refresh and drives the app bar pulse.
  Future<void>? performRefresh() => null;

  /// Called by the shell when disposed. Override to dispose body-held state.
  void dispose() {}
}

/// Search-only list body. The framework uses [SearchScrollSlivers] so the
/// shell's [AppCustomScrollView] is the only scroll view (no nesting).
/// Use this for Issues, Pulls, Repositories tabs that use search/filter/sort.
/// Presets and context actions come from [TabConfig].
/// Optional [leading] (e.g. pinned issues) is shown above the search list.
/// Pull-to-refresh is wired via [onRefreshReady] from [SearchScrollSlivers].
class SearchListBody extends TabBody {
  SearchListBody({required this.scope, this.leading});

  final SearchScope scope;

  /// Optional widget shown above the search list (e.g. pinned issues).
  final Widget? leading;

  Future<void> Function()? _performRefresh;

  @override
  bool get canRefresh => _performRefresh != null;

  @override
  Future<void>? performRefresh() =>
      _performRefresh?.call() ?? Future<void>.value();

  @override
  List<Widget> buildSliversWithRef(
    final BuildContext context,
    final WidgetRef ref,
  ) {
    return <Widget>[
      if (leading != null) SliverToBoxAdapter(child: leading!),
      SearchScrollSlivers(
        scope,
        onRefreshReady: (final Future<void> Function()? fn) {
          _performRefresh = fn;
        },
      ),
    ];
  }
}

/// Body that shows a [leading] widget above a [child] body's slivers.
/// Use to add a fixed block (e.g. environments list) above a paginated list.
class LeadingTabBody extends TabBody {
  LeadingTabBody({required this.leading, required this.child});

  final Widget leading;
  final TabBody child;

  @override
  bool get canRefresh => child.canRefresh;

  @override
  Future<void>? performRefresh() => child.performRefresh();

  @override
  List<Widget> buildSliversWithRef(
    final BuildContext context,
    final WidgetRef ref,
  ) {
    return <Widget>[
      SliverToBoxAdapter(child: leading),
      ...child.buildSliversWithRef(context, ref),
    ];
  }

  @override
  void dispose() => child.dispose();
}

/// Body that supplies slivers from a callback. Use for tabs whose content
/// is naturally sliver-based (e.g. issue/PR discussion, participants, settings).
/// No inner scroll view: slivers go directly into the shell's [AppCustomScrollView].
/// Optional [refreshFuture] or [refreshRegistrar] wires pull-to-refresh.
class SliverBuilderBody extends TabBody {
  const SliverBuilderBody({
    required this.sliverBuilder,
    this.composeBar,
    this.refreshFuture,
    this.refreshRegistrar,
  });

  final List<Widget> Function(BuildContext context, WidgetRef ref)
  sliverBuilder;
  final ComposeBarConfig? composeBar;

  /// When set, pull-to-refresh calls this future. Use for e.g. ref.refresh(provider).
  final Future<void> Function()? refreshFuture;

  /// When set, [sliverBuilder] can register refresh via this notifier (e.g. NotificationsInboxContent.onRefreshReady). canRefresh/performRefresh use the registered callback.
  final ValueNotifier<Future<void> Function()?>? refreshRegistrar;

  @override
  bool get canRefresh =>
      refreshFuture != null ||
      (refreshRegistrar != null && refreshRegistrar!.value != null);

  @override
  Future<void>? performRefresh() {
    if (refreshFuture != null) return refreshFuture!();
    final fn = refreshRegistrar?.value;
    return fn != null ? fn() : null;
  }

  @override
  List<Widget> buildSliversWithRef(
    final BuildContext context,
    final WidgetRef ref,
  ) => sliverBuilder(context, ref);
}

/// Settings body — scrollable list of [SettingsSection] groups.
class SettingsBody extends TabBody {
  const SettingsBody({required this.sections});

  final List<Widget> sections;

  @override
  List<Widget> buildSliversWithRef(
    final BuildContext context,
    final WidgetRef ref,
  ) {
    final spacing = context.spacing;
    return [
      SliverPadding(
        padding: spacing.pagePadding,
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((final context, final index) {
            if (index.isOdd) return spacing.sectionGap;
            return sections[index ~/ 2];
          }, childCount: sections.isEmpty ? 0 : sections.length * 2 - 1),
        ),
      ),
    ];
  }
}
