import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/common/context_dock/models/dock_pill.dart';
import 'package:diohub/common/context_dock/pills/basic_dock_pill.dart';
import 'package:diohub/common/context_dock/pills/filter_chip_pill.dart';
import 'package:diohub/common/context_dock/pills/filter_dock_pill.dart';
import 'package:diohub/common/context_dock/pills/inline_search_dock_pill.dart';
import 'package:diohub/common/context_dock/pills/search_dock_pill.dart';
import 'package:diohub/common/context_dock/pills/sort_chip_pill.dart';
import 'package:diohub/common/nav_center/models/sort_binding.dart';
import 'package:diohub/common/nav_center/models/tab_action.dart';
import 'package:diohub/common/nav_center/models/tab_controls.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/providers/search/search_state_notifier.dart';
import 'package:diohub_models/models/search/sort_config.dart';
import 'package:diohub_models/models/search/sort_spec.dart';

/// Converts [TabControls] into inline pills (for top bar).
List<DockPill> inlinePillsFromControls(
  TabControls? controls,
  BuildContext context,
  WidgetRef ref,
) {
  if (controls == null) return [];

  return switch (controls) {
    SearchTabControls(:final scope) => [
      SortChipPill(binding: _searchSortBinding(scope, ref)),
    ],
    ClientListTabControls(:final sort) => [
      if (sort != null) SortChipPill(binding: sort),
    ],
    FilterableTabControls(
      :final sort,
      :final sections,
      :final stateNotifier,
      :final activeFilterCount,
      :final adapter,
    ) =>
      [
        if (sort != null) SortChipPill(binding: sort),
        if (adapter != null)
          FilterChipPill(
            adapter: adapter,
            sections: sections,
            activeFilterCount: activeFilterCount,
          ),
      ],
    SelectorTabControls(:final selectorPill, :final additionalControls) => [
      selectorPill,
      ...inlinePillsFromControls(additionalControls, context, ref),
    ],
    NoTabControls() => [],
  };
}

/// Helper to wrap SearchScope sort into a SortBinding.
SortBinding _searchSortBinding(SearchScope scope, WidgetRef ref) {
  final SortConfig sortConfig = scope.sortConfig;
  return SortBinding.typed<SortOption>(
    spec: SortSpec(
      options: sortConfig.options,
      defaultValue: sortConfig.defaultSort,
      labelOf: (opt) => opt.displayName,
    ),
    getValue: (ref) =>
        ref.watch(searchStateNotifierProvider(scope)).sort ??
        sortConfig.defaultSort,
    onSelected: (ref, value) =>
        ref.read(searchStateNotifierProvider(scope).notifier).updateSort(value),
  );
}

/// Converts [TabControls] into dock pills (for bottom dock).
List<DockPill> dockPillsFromControls(
  TabControls? controls,
  BuildContext context,
  WidgetRef ref,
) {
  if (controls == null) return [];

  return switch (controls) {
    SearchTabControls(:final scope) => [
      SearchDockPill(scope: scope),
      FilterDockPill(scope: scope),
    ],
    ClientListTabControls(:final searchQuery) => [
      if (searchQuery != null) InlineSearchDockPill(queryNotifier: searchQuery),
    ],
    FilterableTabControls(:final searchQuery) => [
      if (searchQuery != null) InlineSearchDockPill(queryNotifier: searchQuery),
    ],
    SelectorTabControls(:final additionalControls) => dockPillsFromControls(
      additionalControls,
      context,
      ref,
    ),
    NoTabControls() => [],
  };
}

/// Converts [TabAction] into a DockPill.
DockPill pillFromAction(TabAction action, BuildContext context, WidgetRef ref) {
  return switch (action) {
    CreateTabAction(:final icon, :final label, :final onTap) => BasicDockPill(
      iconData: icon,
      onTapAction: onTap,
      label: label,
    ),
    ComposeTabAction(:final pill) => pill,
    CustomTabAction(:final pill) => pill,
  };
}
