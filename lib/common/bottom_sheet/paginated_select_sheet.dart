import 'dart:async';

import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/misc/async_error_widgets.dart';
import 'package:diohub/common/misc/button.dart';
import 'package:diohub/common/pagination/page_size.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/pagination/paginated_sliver_list.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Paginated single-select or multi-select sheet with optional server-side search.
///
/// Replaces: MultiSelectSheet, BranchSelectSheet, MilestoneSelectSheet,
/// ProjectIdsSelectSheet, AssigneeSelectSheet, LabelSelectSheet.
///
/// Uses [PaginationController] + [PaginatedSliverList]. [sourceBuilder] is called
/// with the current search [query] (or null) so the sheet can use [CursorForwardSource],
/// [PageNumberForwardSource], or any [ForwardSource]. When [searchable] is true,
/// changing the search debounces and rebuilds the controller with a new source.
///
/// Usage (cursor + search):
/// ```dart
/// PaginatedSelectSheet<LabelEdge>(
///   mode: SelectMode.multi,
///   sourceBuilder: (query) => CursorForwardSource(
///     fetch: ({first, after}) => repoNotifier.listLabelsGQL(first: first, after: after, query: query),
///   ),
///   idOf: (e) => e.node?.id ?? '',
///   titleOf: (e) => e.node?.name ?? '',
///   searchable: true,
///   onApplyMulti: (selected) => onLabelsChanged(selected),
/// )
/// ```
///
/// Usage (page-number, no search):
/// ```dart
/// PaginatedSelectSheet<Workflow>(
///   mode: SelectMode.single,
///   sourceBuilder: (_) => PageNumberForwardSource(
///     fetch: ({page, perPage}) => notifier.listWorkflows(page: page, perPage: perPage),
///   ),
///   idOf: (w) => w.id.toString(),
///   titleOf: (w) => w.name,
///   onSelectSingle: (w) => Navigator.pop(context, w),
/// )
/// ```
class PaginatedSelectSheet<T> extends ConsumerStatefulWidget {
  const PaginatedSelectSheet({
    required this.mode,
    required this.sourceBuilder,
    required this.idOf,
    required this.titleOf,
    super.key,
    this.subtitleOf,
    this.leadingOf,
    this.searchable = false,
    this.searchHint,
    this.searchDebounce = const Duration(milliseconds: 300),
    this.onSelectSingle,
    this.initialSelectedIds = const {},
    this.onApplyMulti,
    this.onApplyMultiWithIds,
    this.applyLabel = 'Apply',
    this.headerWidget,
    this.headerBuilder,
    this.pageSize = kDefaultPageSize,
    this.filter,
    this.transform,
    this.scrollController,
  });

  final SelectMode mode;

  /// Builds the [ForwardSource] for the list. Called with current search [query]
  /// (null when search is empty or [searchable] is false). When query changes,
  /// the sheet disposes the old controller and creates a new one with this source.
  final ForwardSource<T> Function(String? query) sourceBuilder;

  final String Function(T item) idOf;
  final String Function(T item) titleOf;
  final String? Function(T item)? subtitleOf;
  final Widget Function(BuildContext context, T item)? leadingOf;
  final bool searchable;
  final String? searchHint;
  final Duration searchDebounce;
  final void Function(T item)? onSelectSingle;
  final Set<String> initialSelectedIds;
  final void Function(List<T> selected)? onApplyMulti;

  /// Called on Apply with the full set of selected IDs (includes selections
  /// from header e.g. suggested reviewers). Use when the action only needs IDs.
  final void Function(Set<String> selectedIds)? onApplyMultiWithIds;

  final String applyLabel;
  final Widget? headerWidget;

  /// Header that receives current [selectedIds] and [onToggle] so it can share
  /// selection state (e.g. suggested reviewers). Takes precedence over [headerWidget].
  final Widget Function(
    Set<String> selectedIds,
    void Function(String id) onToggle,
  )?
  headerBuilder;

  final int pageSize;
  final bool Function(T item)? filter;
  final List<T> Function(List<T> raw)? transform;
  final ScrollController? scrollController;

  @override
  ConsumerState<PaginatedSelectSheet<T>> createState() =>
      _PaginatedSelectSheetState<T>();
}

enum SelectMode { single, multi }

class _PaginatedSelectSheetState<T>
    extends ConsumerState<PaginatedSelectSheet<T>> {
  final Set<String> _selectedIds = {};
  late PaginationController<T, T> _controller;
  Timer? _debounce;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  ScrollController? _ownScrollController;

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(widget.initialSelectedIds);
    if (widget.scrollController == null) {
      _ownScrollController = ScrollController();
    }
    _controller = _createController();
  }

  ScrollController get _scrollController =>
      widget.scrollController ?? _ownScrollController!;

  PaginationController<T, T> _createController() {
    final String? query = _searchQuery.isEmpty
        ? null
        : _searchQuery.trim().isEmpty
        ? null
        : _searchQuery.trim();
    return PaginationController<T, T>(
      source: widget.sourceBuilder(query),
      idOf: widget.idOf,
      pageSize: widget.pageSize,
      transform: widget.transform,
      filter: widget.filter != null
          ? (List<T> items) => items.where((T i) => widget.filter!(i)).toList()
          : null,
    );
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(widget.searchDebounce, () {
      if (!mounted || value == _searchQuery) {
        return;
      }
      setState(() {
        _searchQuery = value;
        final PaginationController<T, T> old = _controller;
        _controller = _createController();
        old.dispose();
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _controller.dispose();
    _ownScrollController?.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _apply() {
    final List<T> items = _controller.state.value.items;
    final List<T> selected = items
        .where((T item) => _selectedIds.contains(widget.idOf(item)))
        .toList();
    widget.onApplyMulti?.call(selected);
  }

  @override
  Widget build(BuildContext context) {
    final AppSpacing spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.searchable)
          Padding(
            padding: spacing.sheetPadding,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: widget.searchHint ?? context.l10n.commonSearch,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
              ),
            ),
          ),
        if (widget.headerBuilder != null)
          widget.headerBuilder!(Set<String>.from(_selectedIds), _toggle)
        else if (widget.headerWidget != null)
          widget.headerWidget!,
        Expanded(
          child: SheetScrollBody(
            scrollController: _scrollController,
            slivers: <Widget>[
              SliverPadding(
                padding: spacing.sheetPadding,
                sliver: PaginatedSliverList<T>(
                  controller: _controller,
                  itemBuilder: (BuildContext context, T item, int index) {
                    final String id = widget.idOf(item);
                    return switch (widget.mode) {
                      SelectMode.single => ListTile(
                        title: Text(widget.titleOf(item)),
                        subtitle: widget.subtitleOf != null
                            ? Text(widget.subtitleOf!(item) ?? '')
                            : null,
                        leading: widget.leadingOf?.call(context, item),
                        onTap: () => widget.onSelectSingle?.call(item),
                      ),
                      SelectMode.multi => CheckboxListTile(
                        value: _selectedIds.contains(id),
                        onChanged: (_) => _toggle(id),
                        title: Text(widget.titleOf(item)),
                        subtitle: widget.subtitleOf != null
                            ? Text(widget.subtitleOf!(item) ?? '')
                            : null,
                        secondary: widget.leadingOf?.call(context, item),
                      ),
                    };
                  },
                  emptyBuilder: (_) =>
                      EmptyState(message: context.l10n.filterNoItemsFound),
                ),
              ),
            ],
          ),
        ),
        if (widget.mode == SelectMode.multi)
          Padding(
            padding: spacing.sheetPadding,
            child: Button(onTap: _apply, child: Text(widget.applyLabel)),
          ),
      ],
    );
  }
}
