import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/common/context_dock/models/dock_pill.dart';
import 'package:diohub/common/nav_center/models/entity_config.dart';
import 'package:diohub/common/nav_center/models/tab_config.dart';
import 'package:diohub/common/widgets/status_flag_row.dart';

/// Data-only variant for one line in the expanded zone. Shell pattern-matches to render.
sealed class ExpandedZoneDetail {
  const ExpandedZoneDetail();
}

/// Rendered by the shell as "Status: " + [message].
final class StatusMessage extends ExpandedZoneDetail {
  const StatusMessage(this.message);
  final String message;
}

/// Rendered by the shell as flags' labels joined by " · " (e.g. "Archived · Fork").
final class FlagSummary extends ExpandedZoneDetail {
  const FlagSummary(this.flags);
  final List<StatusFlag> flags;
}

/// Rendered by the shell as body-style text (main description/title line).
final class ExpandedZoneText extends ExpandedZoneDetail {
  const ExpandedZoneText(this.text);
  final String text;
}

/// Rendered by the shell as-is (e.g. global search bar).
final class ExpandedZoneLeading extends ExpandedZoneDetail {
  const ExpandedZoneLeading(this.child);
  final Widget child;
}

/// Default for [ScreenConfig.expandedZoneContent] when omitted.
final List<ExpandedZoneDetail> _defaultExpandedZoneContent =
    <ExpandedZoneDetail>[];

/// Top-level configuration for a NavCenter screen.
///
/// Each of the 7 screens produces one [ScreenConfig] from its provider data.
/// The [NavCenterShell] consumes it and renders everything.
@immutable
class ScreenConfig {
  ScreenConfig({
    required this.entity,
    required this.tabs,
    List<ExpandedZoneDetail>? expandedZoneContent,
    this.onRefresh,
    this.initialTabPath,
    this.onWillPop,
    this.screenDockActions,
    this.screenInlineControls,
    this.bottomOverlay,
  })  : expandedZoneContent =
            expandedZoneContent ?? _defaultExpandedZoneContent,
        visibleTabs = tabs
            .where((TabConfig p) => p.visible)
            .toList(growable: false);

  /// Entity identity, metadata, and actions.
  final EntityConfig entity;

  /// All navigation tabs (including conditional ones).
  /// [visibleTabs] filters this based on each tab's [visibleWhen].
  final List<TabConfig> tabs;

  /// Optional content in the expanded zone (collapsible when scrolled).
  /// Order in list = order on screen. Shell pattern-matches each element
  /// ([ExpandedZoneText], [StatusMessage], [FlagSummary], [ExpandedZoneLeading]).
  final List<ExpandedZoneDetail> expandedZoneContent;

  /// Pull-to-refresh callback. When non-null, the shell wraps the
  /// body in a [PullToRefreshWrapper].
  final Future<void> Function()? onRefresh;

  /// Optional deeplink path for the initial tab.
  /// Matched against [TabConfig.deeplinkPath] to resolve initial index.
  /// When null, the first visible tab is focused.
  final String? initialTabPath;

  /// Optional back-button handler. Called with current tab index; return
  /// false to consume the pop (e.g. clear code tree selection), true to allow.
  final Future<bool> Function(int tabIndex)? onWillPop;

  /// Pills shown in the bottom dock on **every** tab of this screen.
  /// Combined with tab-specific pills (screen pills come first).
  final List<DockPill> Function(BuildContext, WidgetRef)? screenDockActions;

  /// Pills shown in the nav context bar (top) on **every** tab of this screen.
  /// Rendered before tab-specific inline controls. Use for e.g. Bookmark.
  final List<DockPill> Function(BuildContext, WidgetRef)? screenInlineControls;

  /// Optional overlay widget rendered at the bottom of the shell Stack,
  /// above the action dock. Used for startup flow banners, etc.
  final Widget? bottomOverlay;

  /// Tabs that pass [TabConfig.visible].
  /// Computed once at construction. This is the list actually rendered by the shell.
  final List<TabConfig> visibleTabs;
}
