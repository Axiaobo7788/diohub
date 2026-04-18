import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/context_dock/widgets/filter_popup_content.dart';
import 'package:diohub/common/misc/liquid_glass_wrapper.dart';
import 'package:diohub/common/nav_center/models/ambient_indicator.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/nav_center/overlays/tab_trailing.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub/providers/developer_mode_provider.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/models/search/search_state.dart';
import 'package:diohub/providers/search/search_state_notifier.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Content for the tab switcher popup: grouped tab tiles with header.
///
/// Used inside [PopupButton.popupBuilder] so the tab selector opens
/// as an anchored popup (barrier tap to dismiss). Tab tiles use
/// [kMinInteractiveDimension] and [compactSpacing].
class TabSwitcherOverlay extends ConsumerStatefulWidget {
  const TabSwitcherOverlay({
    required this.tabs,
    required this.currentIndex,
    required this.onSelect,
    required this.onDismiss,
    super.key,
  });

  final List<TabConfig> tabs;
  final int currentIndex;
  final void Function(int index) onSelect;
  final VoidCallback onDismiss;

  @override
  ConsumerState<TabSwitcherOverlay> createState() => _TabSwitcherOverlayState();
}

class _TabSwitcherOverlayState extends ConsumerState<TabSwitcherOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _stagger;
  late final int _totalItems;

  @override
  void initState() {
    super.initState();
    _totalItems = widget.tabs.length;
    _stagger = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (180 + _totalItems * 35).clamp(180, 500),
      ),
    )..forward();
  }

  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  Widget _wrapTile(int index, Widget child) {
    final start = (index * 0.07).clamp(0.0, 0.6);
    final end = (start + 0.5).clamp(0.0, 1.0);
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _stagger,
        curve: Interval(start, end, curve: kStateCurve),
      ),
      child: child,
    );
  }

  int _globalIndex(
    List<MapEntry<TabCategory, List<_IndexedTab>>> entries,
    int s,
    int i,
  ) {
    int idx = 0;
    for (int k = 0; k < s; k++) idx += entries[k].value.length;
    return idx + i;
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final deferredEnabled = isDeveloperMode(ref);
    final screenSize = MediaQuery.sizeOf(context);

    final Map<TabCategory, List<_IndexedTab>> grouped = {};
    for (int i = 0; i < widget.tabs.length; i++) {
      final category = widget.tabs[i].category;
      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(_IndexedTab(index: i, config: widget.tabs[i]));
    }

    final entries = grouped.entries.toList();

    final maxWidth = (screenSize.width * 0.6).clamp(280.0, double.infinity);
    final maxHeight = screenSize.height * 0.65;

    return LiquidGlassWrapper(
      size: RadiusSize.large,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Padding(
          padding: EdgeInsets.all(spacing.itemSpacing),
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            children: [
              for (int s = 0; s < entries.length; s++) ...[
                if (s > 0) SizedBox(height: spacing.sectionSpacing),
                if (entries.length > 1)
                  Padding(
                    padding: EdgeInsets.only(
                      top: s > 0 ? 0 : 0,
                      bottom: spacing.tightSpacing,
                      left: spacing.contentPadding.left,
                    ),
                    child: Text(
                      entries[s].key.label,
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                for (int i = 0; i < entries[s].value.length; i++)
                  _wrapTile(
                    _globalIndex(entries, s, i),
                    _buildPositionTile(
                      context,
                      indexed: entries[s].value[i],
                      isActive:
                          entries[s].value[i].index == widget.currentIndex,
                      deferredEnabled: deferredEnabled,
                    ),
                  ),
                if (s < entries.length - 1)
                  Padding(
                    padding: EdgeInsets.only(top: spacing.sectionSpacing),
                    child: Divider(height: 1, color: colorScheme.outline.tint),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String? _ambientSubtitle(AmbientIndicator? indicator) {
    if (indicator == null) return null;
    return switch (indicator) {
      BranchAmbient(:final ref) => 'on $ref',
      DiffStatAmbient(
        :final additions,
        :final deletions,
        :final changedFiles,
      ) =>
        '+$additions −$deletions${changedFiles != null ? ', $changedFiles files' : ''}',
      CIStatusAmbient(:final state) => switch (state) {
        StatusState.SUCCESS => 'Checks passing',
        StatusState.FAILURE || StatusState.ERROR => 'Checks failing',
        StatusState.PENDING => 'Checks pending',
        _ => null,
      },
      ReviewDecisionAmbient(:final decision) => switch (decision) {
        PullRequestReviewDecision.APPROVED => 'Approved',
        PullRequestReviewDecision.CHANGES_REQUESTED => 'Changes requested',
        PullRequestReviewDecision.REVIEW_REQUIRED => 'Review required',
        _ => null,
      },
      ProgressAmbient(:final completed, :final total) =>
        '$completed/$total complete',
      FilterChipAmbient(:final label) => label,
      _ => null,
    };
  }

  Widget _buildPositionTile(
    BuildContext context, {
    required _IndexedTab indexed,
    required bool isActive,
    required bool deferredEnabled,
  }) {
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final tab = indexed.config;
    final isInteractive = !tab.isDeferred || deferredEnabled;
    final radius = Theme.of(context).surface.radius(RadiusSize.small);
    final subtitle = _ambientSubtitle(tab.ambientIndicator);
    final hasPresets = tab.presets != null && tab.presets!.isNotEmpty;

    final tileContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              tab.icon,
              size: 20,
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            spacing.itemGap,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          tab.label,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: spacing.tightSpacing / 2),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),
            if (tab.trailing != null) TabTrailing(indicator: tab.trailing!),
            if (tab.searchScope != null) ...[
              spacing.tightGap,
              IconButton(
                icon: const Icon(Icons.filter_list_rounded, size: 20),
                onPressed: () {
                  AppSheet.simple<void>(
                    context,
                    bodyBuilder: (BuildContext ctx, StateSetter setState) =>
                        FilterPopupContent(
                          scope: tab.searchScope!,
                          positionLabel: tab.label,
                          tabIndex: indexed.index,
                          currentIndex: widget.currentIndex,
                          onSelectIndex: () => widget.onSelect(indexed.index),
                          onDismissOverlay: widget.onDismiss,
                          onCloseSheet: () => Navigator.of(ctx).pop(),
                        ),
                  );
                },
                style: IconButton.styleFrom(
                  minimumSize: const Size(
                    kMinInteractiveDimension,
                    kMinInteractiveDimension,
                  ),
                ),
              ),
            ],
            if (tab.isDeferred && !deferredEnabled) ...[
              spacing.tightGap,
              TintedChip(
                color: colorScheme.tertiary,
                icon: Icons.schedule_rounded,
                label: 'Coming Soon',
                size: RadiusSize.small,
              ),
            ],
          ],
        ),
        if (hasPresets && tab.searchScope != null)
          Padding(
            padding: EdgeInsets.only(top: spacing.tightSpacing),
            child: _PresetChipsRow(
              scope: tab.searchScope!,
              presets: tab.presets!,
              tabIndex: indexed.index,
              currentIndex: widget.currentIndex,
              onSelect: widget.onSelect,
              onDismiss: widget.onDismiss,
            ),
          ),
      ],
    );

    return Opacity(
      opacity: isInteractive ? 1.0 : Opacities.disabled,
      child: Material(
        color: isActive
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: isInteractive
              ? () {
                  widget.onSelect(indexed.index);
                  widget.onDismiss();
                }
              : null,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.contentPadding.left,
              vertical: spacing.itemSpacing,
            ),
            child: tileContent,
          ),
        ),
      ),
    );
  }
}

class _PresetChipsRow extends ConsumerWidget {
  const _PresetChipsRow({
    required this.scope,
    required this.presets,
    required this.tabIndex,
    required this.currentIndex,
    required this.onSelect,
    required this.onDismiss,
  });

  final SearchScope scope;
  final List<NavigationPreset> presets;
  final int tabIndex;
  final int currentIndex;
  final void Function(int index) onSelect;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.spacing;
    final searchState = ref.watch(searchStateNotifierProvider(scope));
    final notifier = ref.read(searchStateNotifierProvider(scope).notifier);

    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: spacing.tightSpacing,
      runSpacing: spacing.tightSpacing,
      children: [
        for (final preset in presets)
          GestureDetector(
            onTap: () {
              notifier.applyPreset(preset);
              onSelect(tabIndex);
              onDismiss();
            },
            child: TintedChip(
              color: _presetMatchesState(preset, searchState)
                  ? colorScheme.primary
                  : colorScheme.outline,
              icon: Icons.filter_list_rounded,
              label: preset.label,
            ),
          ),
      ],
    );
  }

  bool _presetMatchesState(NavigationPreset preset, SearchState state) {
    if (preset.qualifier.isEmpty) return state.displayQuery.isEmpty;
    return state.displayQuery.contains(preset.qualifier) ||
        state.apiQuery.contains(preset.qualifier);
  }
}

class _IndexedTab {
  const _IndexedTab({required this.index, required this.config});
  final int index;
  final TabConfig config;
}
