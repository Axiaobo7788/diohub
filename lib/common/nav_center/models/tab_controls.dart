import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:diohub/common/context_dock/models/dock_pill.dart';
import 'package:diohub/common/nav_center/models/preset.dart';
import 'package:diohub/common/nav_center/models/sort_binding.dart';
import 'package:diohub/common/search_overlay/filter_section_def.dart';
import 'package:diohub/common/search_overlay/filter_state_adapter.dart';
import 'package:diohub/models/search/search_scope.dart';

part 'tab_controls.freezed.dart';

/// Polymorphic abstraction for tab-level controls.
///
/// Replaces the ad-hoc inlineControls/dockActions pattern with a
/// single sealed hierarchy that the shell dispatches on.
///
/// Each variant defines WHAT controls the tab needs; the shell
/// renders the HOW (which pills, where they go).
@freezed
sealed class TabControls with _$TabControls {
  /// GitHub search-powered lists (Issues, PRs, Discussions, Repos).
  /// Shell auto-renders: SortChip in IC, SearchDockPill + FilterDockPill in DA.
  const factory TabControls.search({
    required SearchScope scope,
    List<NavigationPreset>? presets,
    @Default(false) bool supportsSelection,
  }) = SearchTabControls;

  /// Client-filtered lists (Followers, Stars, Branches, Labels, Tags).
  /// Shell auto-renders: optional SortChip in IC, optional InlineSearchDockPill in DA.
  const factory TabControls.clientList({
    ValueNotifier<String>? searchQuery,
    SortBinding? sort,
  }) = ClientListTabControls;

  /// Compound-filter lists (Bookmarks, Inbox, Threads, Commits).
  /// Shell auto-renders: SortChip + FilterChip(count) in IC, optional search in DA.
  /// FilterChip tap opens UnifiedFilterSheet.
  const factory TabControls.filterable({
    required List<FilterSectionDef> sections,
    required ChangeNotifier stateNotifier,
    required int Function() activeFilterCount,
    FilterStateAdapter? adapter,
    SortBinding? sort,
    ValueNotifier<String>? searchQuery,
  }) = FilterableTabControls;

  /// Context selectors (Branch, Workflow) that are domain-specific pills.
  /// Shell renders the pill as-is in IC.
  const factory TabControls.selector({
    required DockPill selectorPill,
    TabControls? additionalControls,
  }) = SelectorTabControls;

  /// No controls (README, Activity, Settings, Logs, History).
  const factory TabControls.none() = NoTabControls;
}
