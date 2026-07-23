import 'package:diohub/common/context_dock/context_dock.dart';
import 'package:diohub/common/context_dock/widgets/dock_overlay.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/collapsible_app_bar.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/nav_center/models/tab_action.dart';
import 'package:diohub/common/nav_center/models/tab_controls.dart';
import 'package:diohub/common/nav_center/shell/context_bar_sliver.dart';
import 'package:diohub/common/nav_center/shell/controls_dispatcher.dart';
import 'package:diohub/common/nav_center/overlays/entity_info_popup.dart';
import 'package:diohub/common/popup/animated_menu_icon.dart';
import 'package:diohub/common/popup/entity_popup_menu.dart';
import 'package:diohub/common/popup/popup_button.dart';
import 'package:diohub/common/nav_center/shell/nav_center_refresh_scope.dart';
import 'package:diohub/common/nav_center/shell/tab_page_view.dart';
import 'package:diohub/common/widgets/status_flag_row.dart';
import 'package:diohub/common/wrappers/inner_box_scrolled_provider.dart';
import 'package:diohub/providers/search/search_state_notifier.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Declarative shell for all Navigation Center screens.
///
/// Receives a fully-built [ScreenConfig] and orchestrates the scroll host,
/// collapse bar, context actions bar, tab page view, and overlay
/// mount points. Ephemeral UI state (current tab, overlay visibility) is managed via [ValueNotifier]s.
///
/// Descendants access the shell via [NavCenterShell.of(context)].
///
/// ```
/// Scaffold > SafeArea > Stack [
///   DynamicScroll(
///     bar: CollapseBar(entity tappable → entity overlay),
///     headerSlivers: [..., PremiumBannerSliver?, NavContextBarSliver],
///     body: InnerBoxScrolledProvider > PositionPageView,
///   ),
///   ActionDockOverlay (bottom action pills),
///   (entity tap → PopupButton with EntityInfoContent),
///   NavigationOverlay (conditional),
/// ]
/// ```
class NavCenterShell extends ConsumerStatefulWidget {
  const NavCenterShell({
    required this.config,
    this.initialTabIndex = 0,
    super.key,
  });

  /// The complete declarative configuration for this screen.
  /// Built by screen-level config builders from provider-watched data.
  final ScreenConfig config;

  /// Index into [ScreenConfig.visibleTabs] for the initially-focused
  /// tab. Default 0 (first visible tab). May be resolved from
  /// a deeplink path by the screen-level config builder.
  final int initialTabIndex;

  /// Retrieve the nearest ancestor [NavCenterShellState].
  ///
  /// Throws if no [NavCenterShell] is above [context] in the tree.
  /// Used by overlays, compose bar, and action handlers to drive shell state.
  static NavCenterShellState of(BuildContext context) {
    final state = context.findAncestorStateOfType<NavCenterShellState>();
    assert(state != null, 'No NavCenterShell found above this context');
    return state!;
  }

  @override
  ConsumerState<NavCenterShell> createState() => NavCenterShellState();
}

class NavCenterShellState extends ConsumerState<NavCenterShell> {
  // ── Ephemeral UI state ──────────────────────────────────────────────

  /// Index into [visibleTabs] for the currently-displayed tab.
  late final ValueNotifier<int> _tabIndex;

  /// Whether a paginated list is currently refreshing (pull-to-refresh).
  /// Exposed via [NavCenterRefreshScope]; app bar shows pulse when true.
  final ValueNotifier<bool> _isRefreshing = ValueNotifier<bool>(false);

  // ── Derived getters ─────────────────────────────────────────────────

  /// Convenience: the list of tabs with [TabConfig.visible] true.
  List<TabConfig> get visibleTabs => widget.config.visibleTabs;

  /// The [ScreenConfig] this shell was created with.
  ScreenConfig get config => widget.config;

  // ── Public API (used by descendants via NavCenterShell.of) ──────────

  /// Jump to the tab at [index] in [visibleTabs].
  void switchTab(int index) => _tabIndex.value = index;

  // ── Lifecycle ───────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final length = visibleTabs.length;
    int index = length > 0 ? widget.initialTabIndex.clamp(0, length - 1) : 0;
    final path = widget.config.initialTabPath;
    if (path != null && path.isNotEmpty && length > 0) {
      final found = visibleTabs.indexWhere((p) => p.deeplinkPath == path);
      if (found >= 0) index = found;
    }
    _tabIndex = ValueNotifier<int>(index);
    _tabIndex.addListener(_initializeActiveTabDefaultPreset);
    _initializeActiveTabDefaultPreset();
  }

  @override
  void dispose() {
    _tabIndex.removeListener(_initializeActiveTabDefaultPreset);
    _tabIndex.dispose();
    _isRefreshing.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant NavCenterShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config != oldWidget.config) {
      final length = visibleTabs.length;
      if (length == 0) {
        _tabIndex.value = 0;
      } else {
        final current = _tabIndex.value;
        _tabIndex.value = current.clamp(0, length - 1);
      }
      _initializeActiveTabDefaultPreset();
    }
  }

  void _initializeActiveTabDefaultPreset() {
    if (visibleTabs.isEmpty) return;
    final int index = _tabIndex.value.clamp(0, visibleTabs.length - 1);
    final TabConfig tab = visibleTabs[index];
    final scope = tab.searchScope;
    final presets = tab.presets;
    if (scope == null || presets == null || presets.isEmpty) return;
    ref
        .read(searchStateNotifierProvider(scope).notifier)
        .initializeDefaultPreset(presets);
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    Widget content = NavCenterRefreshScope(
      notifier: _isRefreshing,
      child: Stack(
        children: [
          _buildMainContent(context),
          if (widget.config.bottomOverlay != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: 56 + context.spacing.screenPadding.bottom,
                  ),
                  child: widget.config.bottomOverlay!,
                ),
              ),
            ),
          Consumer(
            builder: (context, ref, _) {
              return ValueListenableBuilder<int>(
                valueListenable: _tabIndex,
                builder: (_, index, __) {
                  if (visibleTabs.isEmpty) return const SizedBox.shrink();
                  final tab = visibleTabs[index];
                  final screenPills =
                      widget.config.screenDockActions?.call(context, ref) ?? [];

                  // NEW: Dispatch on controls/actions if present
                  List<DockPill> pills;
                  if (tab.controls != null ||
                      (tab.actions != null && tab.actions!.isNotEmpty)) {
                    final dockFromControls = tab.controls != null
                        ? _dockPillsFromControls(tab.controls!, context, ref)
                        : <DockPill>[];
                    final dockFromActions = tab.actions != null
                        ? tab.actions!
                              .map(
                                (action) =>
                                    _pillFromAction(action, context, ref),
                              )
                              .toList()
                        : <DockPill>[];
                    pills = <DockPill>[
                      // Selection feature moved to premium
                      ...screenPills,
                      ...dockFromControls,
                      ...dockFromActions,
                    ];
                  } else {
                    // LEGACY: Use dockActions
                    final tabDockActions =
                        tab.dockActions?.call(context, ref) ?? [];
                    pills = <DockPill>[
                      // Selection feature moved to premium
                      ...screenPills,
                      ...tabDockActions,
                    ];
                  }

                  return DockOverlay(
                    pills: pills,
                    initialActivePillIndex: null,
                    tabIndex: index,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
    if (widget.config.onWillPop != null) {
      content = PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) async {
          if (didPop) return;
          final allow = await widget.config.onWillPop!(_tabIndex.value);
          if (context.mounted && allow) {
            Navigator.of(context).pop();
          }
        },
        child: content,
      );
    }
    return ref
        .read(premiumLifecycleProvider)
        .buildAppOverlay(
          context,
          ref,
          child: Scaffold(body: SafeArea(bottom: false, child: content)),
        );
  }

  Widget _buildMainContent(BuildContext context) {
    final List<ExpandedZoneDetail> content = widget.config.expandedZoneContent;
    final bool hasExpanded = content.isNotEmpty;
    return DynamicScroll(
      bar: _buildCollapseBar(),
      expanded: hasExpanded
          ? (BuildContext ctx) => _buildExpandedZone(ctx, content)
          : null,
      headerSlivers: _buildHeaderSlivers,
      headerVisible: true,
      bodyBuilder: _buildBody,
    );
  }

  Widget _buildExpandedZone(
    BuildContext ctx,
    List<ExpandedZoneDetail> content,
  ) {
    final spacing = ctx.spacing;
    final theme = Theme.of(ctx);
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final List<Widget> children = <Widget>[];
    for (final ExpandedZoneDetail detail in content) {
      if (children.isNotEmpty) {
        children.add(spacing.itemGap);
      }
      switch (detail) {
        case ExpandedZoneText(:final text):
          if (text.isNotEmpty) {
            children.add(
              Text(
                text,
                style: bodyStyle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }
        case ExpandedZoneLeading(:final child):
          children.add(child);
        case StatusMessage(:final message):
          children.add(
            Text.rich(
              TextSpan(
                style: labelStyle,
                children: <InlineSpan>[
                  TextSpan(
                    text: 'Status: ',
                    style: labelStyle?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: message),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          );
        case FlagSummary(:final flags):
          if (flags.isNotEmpty) {
            children.add(
              Text(
                flags.map((StatusFlag f) => f.label).join(' · '),
                style: labelStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }
      }
    }
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    if (children.length == 1) {
      return children.single;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  // ── Collapse Bar ────────────────────────────────────────────────────

  Widget _buildEntityPopupContent(VoidCallback onDismiss) {
    return EntityInfoContent(
      entity: widget.config.entity,
      onDismiss: onDismiss,
    );
  }

  Widget _buildEntityActionsKebab() {
    final entity = widget.config.entity;
    if (entity.actionSections.isEmpty) return const SizedBox.shrink();

    final sections = <PopupMenuSection>[
      ...entity.actionSections,
      if (widget.config.onRefresh != null)
        PopupMenuSection(
          style: PopupSectionStyle.utility,
          actions: [
            MinorActionButton(
              icon: Icons.refresh_rounded,
              label: 'Refresh',
              onTap: () {
                _isRefreshing.value = true;
                widget.config.onRefresh!().whenComplete(() {
                  _isRefreshing.value = false;
                });
              },
              dismissBehavior: ActionDismissBehavior.immediate,
            ),
          ],
        ),
    ];

    return PopupButton(
      buttonBuilder: (_, showMenu) => Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: showMenu,
          borderRadius: BorderRadius.circular(
            Theme.of(context).surface.radius(RadiusSize.small),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.compactSpacing,
              vertical: context.spacing.tightSpacing,
            ),
            child: AnimatedMenuIcon.compact(isOpen: false),
          ),
        ),
      ),
      animatedButtonBuilder: (_, showMenu, isOpen) => Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: showMenu,
          borderRadius: BorderRadius.circular(
            Theme.of(context).surface.radius(RadiusSize.small),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.compactSpacing,
              vertical: context.spacing.tightSpacing,
            ),
            child: AnimatedMenuIcon.compact(isOpen: isOpen),
          ),
        ),
      ),
      popupBuilder: (_, onDismiss) =>
          EntityPopupMenu(sections: sections, onDismiss: onDismiss),
    );
  }

  CollapseBar _buildCollapseBar() {
    final entity = widget.config.entity;
    return CollapseBar(
      leading: entity.leading != null
          ? PopupButton(
              popupBuilder: (_, onDismiss) =>
                  _buildEntityPopupContent(onDismiss),
              buttonBuilder: (_, showMenu) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: showMenu,
                child: entity.leading,
              ),
            )
          : null,
      title: PopupButton(
        popupBuilder: (_, onDismiss) => _buildEntityPopupContent(onDismiss),
        buttonBuilder: (_, showMenu) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: showMenu,
          child: entity.title,
        ),
      ),
      subtitle: entity.subtitle,
      statusIndicators: entity.statusIndicators,
      action: _buildEntityActionsKebab(),
    );
  }

  // ── Header Slivers ──────────────────────────────────────────────────

  List<Widget> _buildHeaderSlivers(
    BuildContext context,
    bool innerBoxIsScrolled,
  ) {
    final entitySlivers = widget.config.entity.headerSlivers;
    final premiumScreens = ref.read(premiumScreensProvider);
    return <Widget>[
      if (entitySlivers != null && entitySlivers.isNotEmpty) ...entitySlivers,
      if (premiumScreens.downloadBannerSliver(context, ref) != null)
        premiumScreens.downloadBannerSliver(context, ref)!,
      ContextBarSliver(
        tabs: visibleTabs,
        tabIndex: _tabIndex,
        switchTab: switchTab,
        isInnerBoxScrolled: innerBoxIsScrolled,
        screenInlineControls: widget.config.screenInlineControls,
        inlinePillsFromControlsFn: (controls, context, ref) =>
            inlinePillsFromControls(controls, context, ref),
      ),
    ];
  }

  // ── Body ────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, DynamicScrollMetrics metrics) {
    return InnerBoxScrolledProvider(
      isInnerBoxScrolled: metrics.innerBoxIsScrolled,
      child: TabPageView(tabs: visibleTabs, tabIndex: _tabIndex),
    );
  }

  // ── Controls/Actions Dispatch ───────────────────────────────────────

  List<DockPill> _dockPillsFromControls(
    TabControls controls,
    BuildContext context,
    WidgetRef ref,
  ) {
    return dockPillsFromControls(controls, context, ref);
  }

  DockPill _pillFromAction(
    TabAction action,
    BuildContext context,
    WidgetRef ref,
  ) {
    return pillFromAction(action, context, ref);
  }
}
