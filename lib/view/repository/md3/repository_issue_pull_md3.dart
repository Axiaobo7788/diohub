import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/nav_center/models/preset.dart';
import 'package:diohub/common/search_overlay/search_filter_sheet.dart';
import 'package:diohub/common/wrappers/search_scroll_wrapper.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/models/search/quick_filter.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/models/search/search_state.dart';
import 'package:diohub/providers/search/search_state_notifier.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/view/repository/md3/repository_issue_pull_row.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/search/issue_or_pull.dart';
import 'package:diohub_models/models/search/qualifier.dart';
import 'package:diohub_models/models/search/search_expression.dart';
import 'package:diohub_models/models/search/sort_config.dart';
import 'package:diohub_models/models/search/sort_configs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RepositoryIssuePullKind { issues, pullRequests }

class RepositoryIssuesMd3Page extends StatelessWidget {
  const RepositoryIssuesMd3Page({
    required this.repoRef,
    required this.repo,
    required this.details,
    required this.signedIn,
    this.searchConfigFactory,
    this.onRefreshReady,
    this.onOpenProjects,
    super.key,
  });

  final RepoRef repoRef;
  final RepoCardData? repo;
  final RepoInfo? details;
  final bool signedIn;
  final SearchTypeConfigFactory? searchConfigFactory;
  final ValueChanged<Future<void> Function()?>? onRefreshReady;
  final VoidCallback? onOpenProjects;

  @override
  Widget build(final BuildContext context) => RepositoryIssuePullMd3Page(
    kind: RepositoryIssuePullKind.issues,
    repoRef: repoRef,
    repo: repo,
    details: details,
    signedIn: signedIn,
    searchConfigFactory: searchConfigFactory,
    onRefreshReady: onRefreshReady,
    onOpenProjects: onOpenProjects,
  );
}

class RepositoryPullRequestsMd3Page extends StatelessWidget {
  const RepositoryPullRequestsMd3Page({
    required this.repoRef,
    required this.repo,
    required this.details,
    required this.signedIn,
    this.searchConfigFactory,
    this.onRefreshReady,
    this.onOpenProjects,
    super.key,
  });

  final RepoRef repoRef;
  final RepoCardData? repo;
  final RepoInfo? details;
  final bool signedIn;
  final SearchTypeConfigFactory? searchConfigFactory;
  final ValueChanged<Future<void> Function()?>? onRefreshReady;
  final VoidCallback? onOpenProjects;

  @override
  Widget build(final BuildContext context) => RepositoryIssuePullMd3Page(
    kind: RepositoryIssuePullKind.pullRequests,
    repoRef: repoRef,
    repo: repo,
    details: details,
    signedIn: signedIn,
    searchConfigFactory: searchConfigFactory,
    onRefreshReady: onRefreshReady,
    onOpenProjects: onOpenProjects,
  );
}

/// Shared query, filter and pagination host used by the two Repository list
/// pages. Repository chrome remains owned by [RepositoryMd3Screen].
class RepositoryIssuePullMd3Page extends ConsumerStatefulWidget {
  const RepositoryIssuePullMd3Page({
    required this.kind,
    required this.repoRef,
    required this.repo,
    required this.details,
    required this.signedIn,
    this.searchConfigFactory,
    this.onRefreshReady,
    this.onOpenProjects,
    super.key,
  });

  final RepositoryIssuePullKind kind;
  final RepoRef repoRef;
  final RepoCardData? repo;
  final RepoInfo? details;
  final bool signedIn;
  final SearchTypeConfigFactory? searchConfigFactory;
  final ValueChanged<Future<void> Function()?>? onRefreshReady;
  final VoidCallback? onOpenProjects;

  @override
  ConsumerState<RepositoryIssuePullMd3Page> createState() =>
      _RepositoryIssuePullMd3PageState();
}

class _RepositoryIssuePullMd3PageState
    extends ConsumerState<RepositoryIssuePullMd3Page> {
  static const double _issuesSidebarBreakpoint = 768;
  static const double _issuesSidebarWidth = 244;
  static const double _compactToolbarBreakpoint = 520;

  late SearchScope _scope;
  late final TextEditingController _searchController;
  Timer? _searchDebounce;
  Future<void> Function()? _refreshList;
  String? _countQuery;
  int? _currentQueryCount;
  String? _pendingSearchText;
  bool _searchReady = false;
  int _searchInitializationGeneration = 0;

  bool get _isIssues => widget.kind == RepositoryIssuePullKind.issues;

  List<NavigationPreset> get _presets =>
      _isIssues ? NavigationPresets.issues : NavigationPresets.pulls;

  @override
  void initState() {
    super.initState();
    _scope = _createScope();
    _searchController = TextEditingController();
    _scheduleDefaultPresetInitialization();
  }

  @override
  void didUpdateWidget(covariant RepositoryIssuePullMd3Page oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repoRef != widget.repoRef || oldWidget.kind != widget.kind) {
      _scope = _createScope();
      _searchController.clear();
      _countQuery = null;
      _currentQueryCount = null;
      _scheduleDefaultPresetInitialization();
    }
    if (oldWidget.onRefreshReady != widget.onRefreshReady) {
      widget.onRefreshReady?.call(_refreshList);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    widget.onRefreshReady?.call(null);
    _searchController.dispose();
    super.dispose();
  }

  SearchScope _createScope() {
    return _isIssues
        ? SearchScope.repoIssues(repo: widget.repoRef)
        : SearchScope.repoPulls(repo: widget.repoRef);
  }

  void _initializeDefaultPreset() {
    ref
        .read(searchStateNotifierProvider(_scope).notifier)
        .initializeDefaultPreset(_presets);
  }

  void _scheduleDefaultPresetInitialization() {
    _searchReady = false;
    final int generation = ++_searchInitializationGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _searchInitializationGeneration) {
        return;
      }
      _initializeDefaultPreset();
      if (mounted) {
        setState(() => _searchReady = true);
      }
    });
  }

  void _onSearchChanged(final String value) {
    _pendingSearchText = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _applySearch(value);
      }
    });
  }

  void _submitSearch(final String value) {
    _searchDebounce?.cancel();
    _applySearch(value);
  }

  void _applySearch(final String value) {
    _pendingSearchText = null;
    final notifier = ref.read(searchStateNotifierProvider(_scope).notifier);
    notifier
      ..setRawFreeText(value)
      ..commitFreeText();
  }

  void _applyIssuesPreset(
    final NavigationPreset preset, {
    final SortOption? sort,
  }) {
    _searchDebounce?.cancel();
    _pendingSearchText = null;
    final notifier = ref.read(searchStateNotifierProvider(_scope).notifier);
    notifier
      ..applyPreset(preset)
      ..updateSort(sort);
  }

  void _resetToDefaultPreset() {
    _applyIssuesPreset(_presets.first);
  }

  void _setStatus(final bool closed) {
    ref
        .read(searchStateNotifierProvider(_scope).notifier)
        .toggleQuickFilter(
          QuickFilter(
            qualifier: QualifierExpression(
              closed ? Qualifier.isClosed : Qualifier.isOpen,
            ),
            displayLabel: closed
                ? context.l10n.repoClosed
                : context.l10n.repoOpen,
          ),
        );
  }

  Future<void> _refresh() async {
    await _refreshList?.call();
  }

  void _openFilters() {
    if (!widget.signedIn) {
      _openCreate();
      return;
    }
    unawaited(
      AppSheet.scrollable<void>(
        context,
        headerBuilder:
            (final BuildContext context, final StateSetter setState) =>
                SearchFilterSheet.buildHeader(
                  context,
                  _scope,
                  ref,
                  onClearAll: _resetToDefaultPreset,
                ),
        bodyBuilder:
            (
              final BuildContext context,
              final StateSetter setState,
              final ScrollController scrollController,
            ) => SearchFilterSheet(
              scope: _scope,
              scrollController: scrollController,
            ),
      ),
    );
  }

  void _openCreate() {
    if (!widget.signedIn) {
      unawaited(context.router.push<void>(const AuthRoute()));
      return;
    }
    if (_isIssues) {
      unawaited(
        context.router.push<void>(
          NewIssueRoute(repoRef: widget.repoRef, template: null),
        ),
      );
    } else {
      unawaited(
        context.router.push<void>(NewPullRequestRoute(repoRef: widget.repoRef)),
      );
    }
  }

  bool get _creationEnabled {
    final RepoInfo? details = widget.details;
    if (!widget.signedIn) {
      return true;
    }
    if (details == null ||
        details.isArchived ||
        details.isDisabled ||
        details.isLocked) {
      return false;
    }
    return !_isIssues || details.hasIssuesEnabled;
  }

  void _onTotalCountChanged(final int? totalCount) {
    if (!mounted) {
      return;
    }
    final String query = ref.read(searchStateNotifierProvider(_scope)).apiQuery;
    if (_countQuery == query && _currentQueryCount == totalCount) {
      return;
    }
    setState(() {
      _countQuery = query;
      _currentQueryCount = totalCount;
    });
  }

  @override
  Widget build(final BuildContext context) {
    if (_isIssues && widget.details?.hasIssuesEnabled == false) {
      return _RepositoryIssuePullUnavailable(
        title: context.l10n.repoIssuesUnavailable,
        body: context.l10n.repoIssuesDisabled,
      );
    }

    final SearchState searchState = ref.watch(
      searchStateNotifierProvider(_scope),
    );
    if (_pendingSearchText == null &&
        _searchController.text != searchState.freeText) {
      _searchController.value = TextEditingValue(
        text: searchState.freeText,
        selection: TextSelection.collapsed(offset: searchState.freeText.length),
      );
    }
    final bool closed = _isClosed(searchState);
    final int? currentCount = _countQuery == searchState.apiQuery
        ? _currentQueryCount
        : null;
    final int? repositoryOpenCount = _isIssues
        ? widget.repo?.issues.totalCount
        : widget.repo?.pullRequests.totalCount;

    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        final bool showIssuesSidebar =
            _isIssues && constraints.maxWidth >= _issuesSidebarBreakpoint;
        final Widget content = _buildListContent(
          context,
          searchState: searchState,
          compactToolbar:
              constraints.maxWidth -
                  (showIssuesSidebar ? _issuesSidebarWidth : 0) <
              _compactToolbarBreakpoint,
          detailedFilters:
              constraints.maxWidth -
                  (showIssuesSidebar ? _issuesSidebarWidth : 0) >=
              960,
          closed: closed,
          openCount: closed
              ? repositoryOpenCount
              : currentCount ?? repositoryOpenCount,
          closedCount: closed ? currentCount : null,
        );
        if (!showIssuesSidebar) {
          return content;
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              key: const ValueKey<String>('repository-issues-sidebar'),
              width: _issuesSidebarWidth,
              child: _buildIssuesSidebar(context, searchState),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: content),
          ],
        );
      },
    );
  }

  Widget _buildListContent(
    final BuildContext context, {
    required final SearchState searchState,
    required final bool compactToolbar,
    required final bool detailedFilters,
    required final bool closed,
    required final int? openCount,
    required final int? closedCount,
  }) {
    final double horizontalPadding = compactToolbar ? 16 : 24;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        key: ValueKey<String>(
          _isIssues
              ? 'repository-issues-scroll'
              : 'repository-pull-requests-scroll',
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              24,
              horizontalPadding,
              16,
            ),
            sliver: SliverToBoxAdapter(
              child: _buildToolbar(
                context,
                searchState: searchState,
                compact: compactToolbar,
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            sliver: SliverToBoxAdapter(
              child: _RepositoryStatusHeader(
                closed: closed,
                openCount: openCount,
                closedCount: closedCount,
                compact: compactToolbar,
                detailedFilters: detailedFilters,
                isIssues: _isIssues,
                onOpen: () => _setStatus(false),
                onClosed: () => _setStatus(true),
                onFilter: _openFilters,
                onSort: (final SortOption option) => ref
                    .read(searchStateNotifierProvider(_scope).notifier)
                    .updateSort(option),
              ),
            ),
          ),
          if (!widget.signedIn)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                24,
              ),
              sliver: SliverFillRemaining(
                hasScrollBody: false,
                child: _RepositoryIssuePullSignIn(
                  isIssues: _isIssues,
                  onSignIn: _openCreate,
                ),
              ),
            )
          else if (!_searchReady)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                24,
              ),
              sliver: const SliverToBoxAdapter(
                child: _RepositoryIssuePullLoading(),
              ),
            )
          else
            SearchScrollSlivers(
              _scope,
              key: ValueKey<String>(
                'repository-${widget.kind.name}-${widget.repoRef.fullName}',
              ),
              showRepoNameOnIssues: false,
              showRepoOwner: false,
              configFactory: widget.searchConfigFactory,
              listPadding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                24,
              ),
              onRefreshReady: (final Future<void> Function()? callback) {
                _refreshList = callback;
                widget.onRefreshReady?.call(callback == null ? null : _refresh);
              },
              onTotalCountChanged: _onTotalCountChanged,
              itemBuilder:
                  (
                    final BuildContext context,
                    final Object item,
                    final int index,
                  ) {
                    final RepositoryIssuePullRowData row =
                        RepositoryIssuePullRowData.fromSearchResult(
                          item as IssueOrPull,
                        );
                    return RepositoryIssuePullRow(
                      data: row,
                      onTap: () => unawaited(row.ref.navigate(context, ref)),
                    );
                  },
              firstPageLoadingBuilder: (final BuildContext context) =>
                  const _RepositoryIssuePullLoading(),
              emptyBuilder: (final BuildContext context) =>
                  _RepositoryIssuePullEmpty(
                    isIssues: _isIssues,
                    closed: closed,
                  ),
              errorBuilder:
                  (
                    final BuildContext context,
                    final Object error,
                    final VoidCallback retry,
                  ) => _RepositoryIssuePullError(error: error, onRetry: retry),
            ),
        ],
      ),
    );
  }

  Widget _buildToolbar(
    final BuildContext context, {
    required final SearchState searchState,
    required final bool compact,
  }) {
    final String title = _isIssues
        ? context.l10n.repoAllIssues
        : context.l10n.repoPullRequests;
    final String createLabel = _isIssues
        ? context.l10n.repoNewIssue
        : context.l10n.repoNewPullRequest;
    final int filterCount = searchState.activeQualifiers.where((
      final QualifierExpression expression,
    ) {
      return !expression.qualifier.toQueryString().startsWith('is:');
    }).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _creationEnabled ? _openCreate : null,
              icon: Icon(widget.signedIn ? Icons.add : Icons.login, size: 18),
              label: Text(createLabel),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            if (!compact) ...<Widget>[
              Badge(
                isLabelVisible: filterCount > 0,
                label: Text('$filterCount'),
                child: OutlinedButton.icon(
                  onPressed: _openFilters,
                  icon: const Icon(Icons.filter_list, size: 18),
                  label: Text(context.l10n.repoFilters),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: TextField(
                key: ValueKey<String>(
                  _isIssues
                      ? 'repository-issues-search'
                      : 'repository-pull-requests-search',
                ),
                controller: _searchController,
                onChanged: _onSearchChanged,
                onSubmitted: _submitSearch,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: _isIssues
                      ? context.l10n.repoSearchIssues
                      : context.l10n.repoSearchPullRequests,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: compact
                      ? IconButton(
                          onPressed: _openFilters,
                          tooltip: context.l10n.repoFilters,
                          icon: Badge(
                            isLabelVisible: filterCount > 0,
                            label: Text('$filterCount'),
                            child: const Icon(Icons.filter_list),
                          ),
                        )
                      : null,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        if (!_isIssues && !compact) ...<Widget>[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: _openFilters,
                  icon: const Icon(Icons.label_outline, size: 18),
                  label: Text(context.l10n.repoLabels),
                ),
                OutlinedButton.icon(
                  onPressed: _openFilters,
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  label: Text(context.l10n.repoMilestones),
                ),
              ],
            ),
          ),
        ],
        if (searchState.activeQualifiers.any(
              (final QualifierExpression expression) =>
                  !expression.qualifier.toQueryString().startsWith('is:'),
            ) ||
            searchState.sort != null) ...<Widget>[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final QualifierExpression expression
                  in searchState.activeQualifiers.where(
                    (final QualifierExpression expression) =>
                        !expression.qualifier.toQueryString().startsWith('is:'),
                  ))
                InputChip(
                  label: Text(expression.toQueryFragment()),
                  onDeleted: () => ref
                      .read(searchStateNotifierProvider(_scope).notifier)
                      .removeQualifier(expression),
                ),
              if (searchState.sort != null && !searchState.sort!.isBestMatch)
                InputChip(
                  label: Text(_localizedSortOption(context, searchState.sort!)),
                  onDeleted: () => ref
                      .read(searchStateNotifierProvider(_scope).notifier)
                      .updateSort(null),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildIssuesSidebar(
    final BuildContext context,
    final SearchState searchState,
  ) {
    final List<String> assignees = searchState.activeQualifierValues(
      'assignee',
    );
    final List<String> authors = searchState.activeQualifierValues('author');
    final List<String> mentions = searchState.activeQualifierValues('mentions');
    final String? sortKey = searchState.sort?.key;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 24),
      children: <Widget>[
        _SidebarDestination(
          icon: Icons.adjust_outlined,
          label: context.l10n.repoIssues,
          selected:
              assignees.isEmpty &&
              authors.isEmpty &&
              mentions.isEmpty &&
              sortKey != 'updated-desc',
          onTap: () => _applyIssuesPreset(NavigationPresets.issues.first),
        ),
        _SidebarDestination(
          icon: Icons.people_outline,
          label: context.l10n.repoAssignedToMe,
          selected: assignees.isNotEmpty,
          onTap: () => _applyIssuesPreset(NavigationPresets.issues[2]),
        ),
        _SidebarDestination(
          icon: Icons.sentiment_satisfied_alt_outlined,
          label: context.l10n.repoCreatedByMe,
          selected: authors.isNotEmpty,
          onTap: () => _applyIssuesPreset(NavigationPresets.issues[3]),
        ),
        _SidebarDestination(
          icon: Icons.alternate_email,
          label: context.l10n.repoMentioned,
          selected: mentions.isNotEmpty,
          onTap: () => _applyIssuesPreset(NavigationPresets.issues[4]),
        ),
        _SidebarDestination(
          icon: Icons.schedule,
          label: context.l10n.repoRecentActivity,
          selected: sortKey == 'updated-desc',
          onTap: () => _applyIssuesPreset(
            NavigationPresets.issues.first,
            sort: SearchSortConfigs.issuesPullsSort.options.firstWhere(
              (final SortOption option) => option.key == 'updated-desc',
            ),
          ),
        ),
        const Divider(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(
            context.l10n.repoViews,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (widget.onOpenProjects != null)
          _SidebarDestination(
            icon: Icons.view_module_outlined,
            label: context.l10n.repoProjects,
            onTap: widget.onOpenProjects!,
          ),
        _SidebarDestination(
          icon: Icons.flag_outlined,
          label: context.l10n.repoMilestones,
          onTap: _openFilters,
        ),
        _SidebarDestination(
          icon: Icons.label_outline,
          label: context.l10n.repoLabels,
          onTap: _openFilters,
        ),
      ],
    );
  }

  static bool _isClosed(final SearchState state) {
    final List<String> values = state.activeQualifierValues('is');
    return values.contains('closed') || values.contains('merged');
  }
}

class _RepositoryStatusHeader extends StatelessWidget {
  const _RepositoryStatusHeader({
    required this.closed,
    required this.openCount,
    required this.closedCount,
    required this.compact,
    required this.detailedFilters,
    required this.isIssues,
    required this.onOpen,
    required this.onClosed,
    required this.onFilter,
    required this.onSort,
  });

  final bool closed;
  final int? openCount;
  final int? closedCount;
  final bool compact;
  final bool detailedFilters;
  final bool isIssues;
  final VoidCallback onOpen;
  final VoidCallback onClosed;
  final VoidCallback onFilter;
  final ValueChanged<SortOption> onSort;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: <Widget>[
          if (compact)
            Expanded(
              child: _StatusButton(
                selected: !closed,
                icon: Icons.adjust,
                label: context.l10n.repoOpen,
                count: openCount,
                compact: true,
                onPressed: onOpen,
              ),
            )
          else
            _StatusButton(
              selected: !closed,
              icon: Icons.adjust,
              label: context.l10n.repoOpen,
              count: openCount,
              compact: false,
              onPressed: onOpen,
            ),
          if (compact)
            Expanded(
              child: _StatusButton(
                selected: closed,
                icon: Icons.check,
                label: context.l10n.repoClosed,
                count: closedCount,
                compact: true,
                onPressed: onClosed,
              ),
            )
          else
            _StatusButton(
              selected: closed,
              icon: Icons.check,
              label: context.l10n.repoClosed,
              count: closedCount,
              compact: false,
              onPressed: onClosed,
            ),
          if (!compact) const Spacer(),
          if (detailedFilters) ...<Widget>[
            _HeaderFilterButton(
              label: context.l10n.repoAuthor,
              onPressed: onFilter,
            ),
            _HeaderFilterButton(
              label: context.l10n.repoLabels,
              onPressed: onFilter,
            ),
            _HeaderFilterButton(
              label: context.l10n.repoMilestones,
              onPressed: onFilter,
            ),
            if (!isIssues)
              _HeaderFilterButton(
                label: context.l10n.repoReviews,
                onPressed: onFilter,
              ),
            _HeaderFilterButton(
              label: context.l10n.repoAssignee,
              onPressed: onFilter,
            ),
          ] else if (!compact)
            TextButton.icon(
              onPressed: onFilter,
              icon: const Icon(Icons.tune, size: 18),
              label: Text(context.l10n.repoFilters),
            ),
          PopupMenuButton<SortOption>(
            tooltip: context.l10n.repoSort,
            icon: const Icon(Icons.sort),
            onSelected: onSort,
            itemBuilder: (final BuildContext context) => SearchSortConfigs
                .issuesPullsSort
                .options
                .map(
                  (final SortOption option) => PopupMenuItem<SortOption>(
                    value: option,
                    child: Text(_localizedSortOption(context, option)),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

String _localizedSortOption(
  final BuildContext context,
  final SortOption option,
) {
  return switch (option.key) {
    'best' => context.l10n.filterOptionBestMatch,
    'created-desc' => context.l10n.filterOptionNewest,
    'created-asc' => context.l10n.filterOptionOldest,
    'comments-desc' => context.l10n.filterOptionMostComments,
    'updated-desc' => context.l10n.filterOptionRecentlyUpdated,
    _ => option.displayName,
  };
}

class _HeaderFilterButton extends StatelessWidget {
  const _HeaderFilterButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(final BuildContext context) => TextButton(
    onPressed: onPressed,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label),
        const Icon(Icons.arrow_drop_down, size: 18),
      ],
    ),
  );
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.count,
    required this.compact,
    required this.onPressed,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final int? count;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(final BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: selected
          ? Theme.of(context).colorScheme.onSurface
          : Theme.of(context).colorScheme.onSurfaceVariant,
      minimumSize: const Size(0, 48),
      padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 12),
      textStyle: TextStyle(
        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
      ),
    ),
    child: Row(
      mainAxisAlignment: compact
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 18),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            count == null ? label : '$label $count',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

class _SidebarDestination extends StatelessWidget {
  const _SidebarDestination({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(final BuildContext context) => ListTile(
    dense: true,
    selected: selected,
    selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    leading: Icon(icon, size: 20),
    title: Text(label),
    onTap: onTap,
  );
}

class _RepositoryIssuePullLoading extends StatelessWidget {
  const _RepositoryIssuePullLoading();

  @override
  Widget build(final BuildContext context) {
    final Color color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Column(
      key: const ValueKey<String>('repository-issue-pull-loading'),
      children: <Widget>[
        for (int index = 0; index < 4; index++)
          Container(
            height: 76,
            decoration: BoxDecoration(
              color: color.withValues(alpha: index.isEven ? 0.45 : 0.28),
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                right: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RepositoryIssuePullEmpty extends StatelessWidget {
  const _RepositoryIssuePullEmpty({
    required this.isIssues,
    required this.closed,
  });

  final bool isIssues;
  final bool closed;

  @override
  Widget build(final BuildContext context) => _RepositoryIssuePullStatePanel(
    key: const ValueKey<String>('repository-issue-pull-empty'),
    icon: isIssues ? Icons.adjust_outlined : Icons.call_merge_outlined,
    title: isIssues
        ? (closed
              ? context.l10n.repoNoClosedIssues
              : context.l10n.repoNoOpenIssues)
        : (closed
              ? context.l10n.repoNoClosedPullRequests
              : context.l10n.repoNoOpenPullRequests),
    body: context.l10n.repoAdjustSearchFilters,
  );
}

class _RepositoryIssuePullError extends StatelessWidget {
  const _RepositoryIssuePullError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(final BuildContext context) => _RepositoryIssuePullStatePanel(
    key: const ValueKey<String>('repository-issue-pull-error'),
    icon: Icons.error_outline,
    title: context.l10n.repoIssuePullLoadError,
    body: error.toString(),
    action: OutlinedButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh),
      label: Text(context.l10n.commonRetry),
    ),
  );
}

class _RepositoryIssuePullSignIn extends StatelessWidget {
  const _RepositoryIssuePullSignIn({
    required this.isIssues,
    required this.onSignIn,
  });

  final bool isIssues;
  final VoidCallback onSignIn;

  @override
  Widget build(final BuildContext context) => _RepositoryIssuePullStatePanel(
    key: const ValueKey<String>('repository-issue-pull-sign-in'),
    icon: Icons.lock_outline,
    title: context.l10n.repoSignInRequired,
    body: isIssues
        ? context.l10n.repoSignInToBrowseIssues
        : context.l10n.repoSignInToBrowsePullRequests,
    action: FilledButton.icon(
      onPressed: onSignIn,
      icon: const Icon(Icons.login),
      label: Text(context.l10n.commonSignIn),
    ),
  );
}

class _RepositoryIssuePullUnavailable extends StatelessWidget {
  const _RepositoryIssuePullUnavailable({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(final BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: _RepositoryIssuePullStatePanel(
        icon: Icons.block_outlined,
        title: title,
        body: body,
      ),
    ),
  );
}

class _RepositoryIssuePullStatePanel extends StatelessWidget {
  const _RepositoryIssuePullStatePanel({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: colorScheme.outlineVariant),
          right: BorderSide(color: colorScheme.outlineVariant),
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 32, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (action != null) ...<Widget>[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}
