import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/common/context_dock/models/dock_pill.dart';
import 'package:diohub/common/nav_center/models/ambient_indicator.dart';
import 'package:diohub/common/nav_center/models/preset.dart';
import 'package:diohub/common/nav_center/models/tab_action.dart';
import 'package:diohub/common/nav_center/models/tab_controls.dart';
import 'package:diohub/common/nav_center/models/trailing_indicator.dart';
import 'package:diohub/models/search/search_scope.dart';

/// Category for grouping tabs in the [TabSwitcherOverlay].
///
/// Groups are rendered as sections with sticky headers:
/// - [primary]: Main content tabs (Readme, Code, Issues, etc.)
/// - [content]: Secondary content (License, Releases, Discussions)
/// - [social]: Social connections (Followers, Following)
/// - [settings]: Configuration (Settings, Themes, Accounts)
/// - [other]: Uncategorized (Packages, Projects, Sponsors)
enum TabCategory {
  primary('Primary'),
  content('Content'),
  social('Social'),
  settings('Settings'),
  other('Other');

  const TabCategory(this.label);

  /// Display label for the category header in [TabSwitcherOverlay].
  final String label;

  /// Icon for the category header.
  IconData get icon => switch (this) {
    TabCategory.primary => Icons.star_rounded,
    TabCategory.content => Icons.article_rounded,
    TabCategory.social => Icons.people_rounded,
    TabCategory.settings => Icons.settings_rounded,
    TabCategory.other => Icons.more_horiz_rounded,
  };
}

/// Configuration for a single navigation tab within a screen.
///
/// The [NavCenterShell] reads this to:
/// 1. Render the tab row in [TabSwitcherOverlay] (label + icon + trailing)
/// 2. Supply pills for the context dock
/// 3. Render the tab body in [TabPageView]
/// 4. Apply visibility gating ([visible])
/// 5. Apply deferred state ([isDeferred] + developer mode)
@immutable
class TabConfig {
  const TabConfig({
    required this.label,
    required this.icon,
    this.category = TabCategory.primary,
    this.tint,
    this.trailing,
    this.inlineControls,
    this.dockActions,
    this.controls,
    this.actions,
    this.ambientIndicator,
    required this.body,
    this.visible = true,
    this.isDeferred = false,
    this.deeplinkPath,
    this.keepAlive = true,
    this.supportsSelection = false,
    this.searchScope,
    this.presets,
  });

  /// Display label in the tab switcher overlay and for accessibility.
  final String label;

  /// Icon shown in the tab switcher overlay row.
  final IconData icon;

  /// Optional semantic tint color for the tab icon in the context pill
  /// and any other chrome that wants to reflect tab identity.
  final Color? tint;

  /// Group for the tab switcher overlay sections.
  final TabCategory category;

  /// Trailing indicator for the tab switcher overlay row (count badge, icon, etc.).
  /// Null → no trailing widget.
  final TrailingIndicator? trailing;

  /// Navigation-context pills shown in the top bar when this tab is focused.
  /// Branch, sort, workflow selector, commit filter. Null → top bar shows only
  /// the context pill.
  ///
  /// LEGACY: Use [controls] for new tabs. This field will be removed after migration.
  final List<DockPill> Function(BuildContext, WidgetRef)? inlineControls;

  /// Action pills shown in the bottom dock when this tab is focused.
  /// Search, filter, comment, new issue, download. Null → bottom dock is hidden.
  ///
  /// LEGACY: Use [actions] for new tabs. This field will be removed after migration.
  final List<DockPill> Function(BuildContext, WidgetRef)? dockActions;

  /// NEW: Polymorphic controls (sort, filter, search, selectors).
  /// When non-null, shell dispatches on this instead of [inlineControls]/[dockActions].
  final TabControls? controls;

  /// NEW: List of tab actions (create, compose, download).
  /// Shell converts these to DockPill instances and appends to dock.
  final List<TabAction>? actions;

  /// Search scope for this tab (e.g. for preset application).
  final SearchScope? searchScope;

  /// Presets (e.g. "Open", "Closed") for search tabs.
  final List<NavigationPreset>? presets;

  /// Ambient metadata indicator shown in the dock FAB. Null → no ambient indicator.
  final AmbientIndicator? ambientIndicator;

  /// The tab body as a widget. Widget owns its own lifecycle (controllers, disposal).
  final Widget body;

  /// When false, the tab is excluded from [ScreenConfig.visibleTabs].
  /// Used for conditional tabs (e.g. Issues only when `hasIssuesEnabled`).
  final bool visible;

  /// When true, the tab is visible in the tab switcher overlay but
  /// non-interactive unless developer mode is enabled. Rendered at 40%
  /// opacity with "Coming Soon" badge.
  final bool isDeferred;

  /// URL path segment for deep linking. Null → not deep-linkable.
  /// Must match existing [DynamicTab.deeplinkPath] values for migration
  /// compatibility.
  final String? deeplinkPath;

  /// When true, the tab body is kept alive when swiping away
  /// (uses [AutomaticKeepAliveClientMixin]). Default true.
  /// Set to false for rarely-visited tabs to save memory.
  final bool keepAlive;

  /// When true, this tab supports multi-select and shows [SelectionDockPill]
  /// in the dock. Set for Home Issues, Home Pulls, Home Inbox, Repo Issues, Repo PRs.
  final bool supportsSelection;
}
