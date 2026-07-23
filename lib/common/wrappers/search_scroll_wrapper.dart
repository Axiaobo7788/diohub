import 'dart:collection';

import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/common/nav_center/models/selection_state.dart';
import 'package:diohub/common/pagination/pagination.dart';
import 'package:diohub/common/search_overlay/filters.dart';
import 'package:diohub/common/search_overlay/search_type.dart';
import 'package:diohub/common/wrappers/app_custom_scroll_view.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/models/search/search_state.dart';
import 'package:diohub/models/search/search_type_config.dart';
import 'package:diohub/providers/search/search_state_notifier.dart';
import 'package:diohub/providers/search/search_type_counts_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/search/issue_or_pull.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

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
    this.querySessionCapacity = 1,
    this.animateQueryChanges = false,
    super.key,
  }) : assert(
         querySessionCapacity > 0,
         'querySessionCapacity must be positive.',
       ),
       assert(
         !animateQueryChanges || querySessionCapacity > 1,
         'Animated query changes require at least two retained sessions.',
       );

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

  /// Maximum number of recent query/type pagination sessions retained.
  ///
  /// The default keeps the existing one-query behavior. Repository Issues and
  /// Pull requests opt into a small bounded cache so Open/Closed switches can
  /// restore their already-loaded page without another first-page request.
  final int querySessionCapacity;

  /// Cross-fades between retained query sessions without rebuilding them.
  ///
  /// This is opt-in because a transition briefly keeps both slivers mounted.
  /// Callers enabling it must also retain more than one bounded session.
  final bool animateQueryChanges;

  @override
  ConsumerState<SearchScrollSlivers> createState() =>
      _SearchScrollSliversState();
}

class _SearchScrollSliversState extends ConsumerState<SearchScrollSlivers> {
  final LinkedHashMap<_SearchQuerySessionKey, _SearchPaginationSession>
  _sessions = LinkedHashMap<_SearchQuerySessionKey, _SearchPaginationSession>();
  _SearchQuerySessionKey? _activeSessionKey;
  bool _evictionScheduled = false;
  bool _refreshCallbackScheduled = false;

  @override
  void initState() {
    super.initState();
    _scheduleRefreshCallback();
  }

  @override
  void didUpdateWidget(covariant SearchScrollSlivers oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope != widget.scope) {
      _disposeSessions();
    }
    if (oldWidget.onRefreshReady != widget.onRefreshReady) {
      _scheduleRefreshCallback();
    }
    if (oldWidget.querySessionCapacity != widget.querySessionCapacity) {
      _scheduleEviction();
    }
  }

  @override
  void dispose() {
    widget.onRefreshReady?.call(null);
    _disposeSessions();
    super.dispose();
  }

  void _scheduleRefreshCallback() {
    if (_refreshCallbackScheduled) {
      return;
    }
    _refreshCallbackScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshCallbackScheduled = false;
      if (mounted) {
        widget.onRefreshReady?.call(_refreshActiveSession);
      }
    });
  }

  Future<void> _refreshActiveSession() {
    final _SearchPaginationSession? session = _sessions[_activeSessionKey];
    return session?.controller.refresh() ?? Future<void>.value();
  }

  _SearchPaginationSession _activateSession(final _SearchQuerySessionKey key) {
    if (_activeSessionKey == key) {
      return _sessions[key]!;
    }

    final _SearchPaginationSession session =
        _sessions.remove(key) ?? _createSession(key);
    _sessions[key] = session;
    _activeSessionKey = key;
    _scheduleTotalCountNotification(key, session);
    _scheduleEviction();
    return session;
  }

  _SearchPaginationSession _createSession(final _SearchQuerySessionKey key) {
    final SearchTypeConfig config =
        widget.configFactory?.call(ref, widget.scope) ??
        widget.scope.searchType.config(
          ref,
          showRepoOwner: widget.showRepoOwner,
          showRepoNameOnIssues: widget.showRepoNameOnIssues,
        );
    final PaginationController<Object, Object> controller =
        PaginationController<Object, Object>(
          source: SliceForwardSource<Object>(
            fetch: (final int count) async {
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
                'SearchScroll: fetching type=${key.searchType.name} '
                'query="${key.query}"',
                tag: 'SearchScroll',
              );
              try {
                return config.fetchSlice(
                  query: key.query,
                  count: count,
                  onRawResponse: onCounts,
                );
              } catch (e, st) {
                AppLogger.error(
                  'SearchScroll: fetch failed for query="${key.query}"',
                  error: e,
                  stackTrace: st,
                  tag: 'SearchScroll',
                );
                rethrow;
              }
            },
            resetState: config.resetState,
          ),
          idOf: config.itemId,
          filter: widget.filterFn,
          pageSize: 20,
        );
    void notifyTotalCount() {
      if (mounted && _activeSessionKey == key) {
        widget.onTotalCountChanged?.call(controller.state.value.totalCount);
      }
    }

    controller.state.addListener(notifyTotalCount);
    return _SearchPaginationSession(
      config: config,
      controller: controller,
      notifyTotalCount: notifyTotalCount,
    );
  }

  void _scheduleTotalCountNotification(
    final _SearchQuerySessionKey key,
    final _SearchPaginationSession session,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _activeSessionKey == key) {
        widget.onTotalCountChanged?.call(
          session.controller.state.value.totalCount,
        );
      }
    });
  }

  void _scheduleEviction() {
    if (_sessions.length <= widget.querySessionCapacity || _evictionScheduled) {
      return;
    }
    _evictionScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evictionScheduled = false;
      if (!mounted) {
        return;
      }
      while (_sessions.length > widget.querySessionCapacity) {
        final _SearchQuerySessionKey candidate = _sessions.keys.firstWhere(
          (final _SearchQuerySessionKey key) => key != _activeSessionKey,
        );
        _sessions.remove(candidate)?.dispose();
      }
    });
  }

  void _disposeSessions() {
    for (final _SearchPaginationSession session in _sessions.values) {
      session.dispose();
    }
    _sessions.clear();
    _activeSessionKey = null;
  }

  Widget _buildItem(
    final BuildContext context,
    final Object item,
    final int index,
    final SelectionState selection,
    final String positionKey,
    final SearchTypeConfig config,
  ) {
    final SearchResultItemBuilder? itemBuilder = widget.itemBuilder;
    if (itemBuilder != null) {
      return itemBuilder(context, item, index);
    }
    final Widget card = config.buildItem(context, item, index);
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

  @override
  Widget build(final BuildContext context) {
    final SearchState state = ref.watch(
      searchStateNotifierProvider(widget.scope),
    );
    final SearchType selectedType = ref.watch(
      selectedSearchTypeProvider(widget.scope),
    );
    final _SearchQuerySessionKey sessionKey = _SearchQuerySessionKey(
      query: state.apiQuery,
      searchType: selectedType,
    );
    final _SearchPaginationSession session = _activateSession(sessionKey);
    final Widget listSliver = PaginatedSliverList<Object>(
      key: ValueKey<String>('${state.apiQuery}_${selectedType.name}'),
      controller: session.controller,
      itemBuilder:
          (final BuildContext context, final Object item, final int index) =>
              _buildItem(
                context,
                item,
                index,
                ref.watch(selectionModeProvider(widget.scope.tabKey)),
                widget.scope.tabKey,
                session.config,
              ),
      loadingBuilder:
          widget.firstPageLoadingBuilder ??
          (final BuildContext context) =>
              session.config.buildLoadingShimmer(context),
      emptyBuilder: widget.emptyBuilder,
      errorBuilder: widget.errorBuilder,
    );
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final Widget transitionedListSliver = widget.animateQueryChanges
        ? SliverAnimatedSwitcher(
            key: const ValueKey<String>('search-query-session-transition'),
            duration: reduceMotion ? Duration.zero : kContentTransitionDuration,
            switchInCurve: kContentTransitionCurve,
            switchOutCurve: kContentTransitionCurve,
            child: listSliver,
          )
        : listSliver;

    final spacing = context.spacing;
    return MultiSliver(
      children: <Widget>[
        SliverPadding(
          padding: widget.listPadding ?? spacing.listInset,
          sliver: transitionedListSliver,
        ),
      ],
    );
  }
}

@immutable
class _SearchQuerySessionKey {
  const _SearchQuerySessionKey({required this.query, required this.searchType});

  final String query;
  final SearchType searchType;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is _SearchQuerySessionKey &&
          query == other.query &&
          searchType == other.searchType;

  @override
  int get hashCode => Object.hash(query, searchType);
}

class _SearchPaginationSession {
  const _SearchPaginationSession({
    required this.config,
    required this.controller,
    required this.notifyTotalCount,
  });

  final SearchTypeConfig config;
  final PaginationController<Object, Object> controller;
  final VoidCallback notifyTotalCount;

  void dispose() {
    controller.state.removeListener(notifyTotalCount);
    controller.dispose();
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
