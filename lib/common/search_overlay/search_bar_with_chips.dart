import 'dart:async';

import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/search_overlay/qualifier_chip.dart';
import 'package:diohub/common/search_overlay/qualifier_suggestion_overlay.dart';
import 'package:diohub/common/search_overlay/search_filter_sheet.dart';
import 'package:diohub/models/search/quick_filter.dart';
import 'package:diohub_models/models/search/search_expression.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/providers/search/search_state_notifier.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final RegExp _searchBarWsPattern = RegExp(r'\s+');

/// Chip bar: TextField + Filter button, qualifier chips, quick filter row.
/// Debounce 300ms; onSubmitted commits free text and dismisses suggestions.
class SearchBarWithChips extends ConsumerStatefulWidget {
  const SearchBarWithChips({
    required this.scope,
    this.hintText = 'Search',
    this.debounceMs = 300,
    this.onSearchSubmitted,
    super.key,
  });

  final SearchScope scope;
  final String hintText;
  final int debounceMs;

  /// Called after commitFreeText when user submits the search field (e.g. to navigate to search results).
  final VoidCallback? onSearchSubmitted;

  @override
  ConsumerState<SearchBarWithChips> createState() => _SearchBarWithChipsState();
}

class _SearchBarWithChipsState extends ConsumerState<SearchBarWithChips> {
  late final TextEditingController _controller;
  Timer? _debounce;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = ref.read(searchStateNotifierProvider(widget.scope));
    if (_controller.text != state.freeText) {
      _controller.text = state.freeText;
      _controller.selection =
          TextSelection.collapsed(offset: _controller.text.length);
    }
  }

  void _onChanged(String text) {
    ref
        .read(searchStateNotifierProvider(widget.scope).notifier)
        .setRawFreeText(text);
    _updateSuggestions(text);
    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: widget.debounceMs), () {
      if (!mounted) return;
      ref
          .read(searchStateNotifierProvider(widget.scope).notifier)
          .updateFreeText(text);
      final state = ref.read(searchStateNotifierProvider(widget.scope));
      if (_controller.text != state.freeText) {
        _controller.text = state.freeText;
        _controller.selection =
            TextSelection.collapsed(offset: _controller.text.length);
      }
    });
  }

  void _updateSuggestions(String text) {
    final tokens = text.trim().split(_searchBarWsPattern);
    final last = tokens.isNotEmpty ? tokens.last : '';
    setState(() {
      _showSuggestions = last.contains(':');
    });
  }

  /// Heuristic: no GitHub qualifier pattern (word:) in query.
  static bool _isNaturalLanguage(String query) {
    final t = query.trim();
    if (t.isEmpty) return false;
    return !RegExp(r'\w+:').hasMatch(t);
  }

  Future<void> _onSubmitted(String text) async {
    ref
        .read(searchStateNotifierProvider(widget.scope).notifier)
        .commitFreeText();
    var state = ref.read(searchStateNotifierProvider(widget.scope));
    _controller.text = state.freeText;
    _controller.selection =
        TextSelection.collapsed(offset: _controller.text.length);
    setState(() => _showSuggestions = false);

    widget.onSearchSubmitted?.call();
  }

  void _onSuggestionSelect(String completedToken) {
    final state = ref.read(searchStateNotifierProvider(widget.scope));
    final before = state.freeText.trim().split(_searchBarWsPattern);
    if (before.isEmpty) {
      _controller.text = completedToken;
    } else {
      before[before.length - 1] = completedToken;
      _controller.text = before.join(' ');
    }
    _controller.selection =
        TextSelection.collapsed(offset: _controller.text.length);
    ref
        .read(searchStateNotifierProvider(widget.scope).notifier)
        .updateFreeText(_controller.text);
    setState(() => _showSuggestions = false);
  }

  void _openFilterSheet() {
    unawaited(
      AppSheet.scrollable<void>(
        context,
        headerBuilder: (BuildContext ctx, StateSetter setState) =>
            SearchFilterSheet.buildHeader(ctx, widget.scope, ref),
        bodyBuilder: (BuildContext ctx, StateSetter setState,
                ScrollController scrollController) =>
            SearchFilterSheet(
                scope: widget.scope, scrollController: scrollController),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchStateNotifierProvider(widget.scope));
    final notifier =
        ref.read(searchStateNotifierProvider(widget.scope).notifier);
    final tokens = state.freeText.trim().split(_searchBarWsPattern);
    final lastToken = tokens.isNotEmpty ? tokens.last : '';
    final partialToken =
        _showSuggestions && lastToken.contains(':') ? lastToken : '';
    final parser = partialToken.isNotEmpty
        ? notifier.parserForPartial(partialToken)
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Row 1: TextField + Filter button
        Padding(
          padding: context.spacing.screenPadding,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    border: const OutlineInputBorder(),
                    contentPadding: context.spacing.cardContentPadding,
                  ),
                  onChanged: _onChanged,
                  onSubmitted: _onSubmitted,
                ),
              ),
              SizedBox(width: context.spacing.itemSpacing),
              IconButton(
                icon: const Icon(Icons.filter_list_rounded),
                onPressed: _openFilterSheet,
                tooltip: 'Filters',
              ),
            ],
          ),
        ),
        // Suggestions overlay when last token contains ':'
        if (partialToken.isNotEmpty && parser != null)
          Padding(
            padding: EdgeInsets.only(
                left: context.spacing.screenPadding.left,
                right: context.spacing.screenPadding.right),
            child: QualifierSuggestionOverlay(
              partialToken: partialToken,
              parser: parser,
              onSelect: _onSuggestionSelect,
            ),
          ),
        // Row 2: Qualifier chips + optional Sort chip
        if (state.activeQualifiers.isNotEmpty ||
            (state.sort != null && !state.sort!.isBestMatch)) ...[
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.screenPadding.left),
              children: [
                ...state.activeQualifiers.map(
                  (QualifierExpression q) => Padding(
                    padding:
                        EdgeInsets.only(right: context.spacing.itemSpacing),
                    child: QualifierChip(
                      expression: q,
                      onDelete: () => notifier.removeQualifier(q),
                    ),
                  ),
                ),
                if (state.sort != null && !state.sort!.isBestMatch)
                  Padding(
                    padding:
                        EdgeInsets.only(right: context.spacing.itemSpacing),
                    child: InputChip(
                      label: Text(state.sort!.displayName),
                      deleteIcon: const Icon(Icons.cancel, size: 18),
                      onDeleted: () => notifier.updateSort(null),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: context.spacing.itemSpacing),
        ],
        // Row 3: Quick filters
        if (widget.scope.quickFilters.isNotEmpty)
          Padding(
            padding: context.spacing.screenPadding,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.scope.quickFilters.map((QuickFilter qf) {
                final isSelected =
                    state.activeQualifiers.any((q) => q == qf.qualifier);
                return FilterChip(
                  label: Text(qf.displayLabel),
                  selected: isSelected,
                  onSelected: (_) {
                    if (isSelected) {
                      notifier.removeQualifier(qf.qualifier);
                    } else {
                      notifier.toggleQuickFilter(qf);
                    }
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
