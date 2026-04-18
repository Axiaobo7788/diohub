import 'package:diohub/common/context_dock/models/dock_pill.dart';
import 'package:diohub/common/context_dock/widgets/dock_pill_widget.dart';
import 'package:diohub/common/context_dock/widgets/context_pill.dart';
import 'package:diohub/common/context_dock/widgets/pill_entrance.dart';
import 'package:diohub/common/misc/floating_glass_pill.dart';
import 'package:diohub/common/nav_center/models/tab_config.dart';
import 'package:diohub/common/nav_center/models/tab_controls.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// Pinned sliver that shows the navigation context bar (screen pills + context pill)
/// below the collapse bar. Each pill glasses itself; no outer glass.
/// [isInnerBoxScrolled] comes from the header builder; when true, pills use glass.
class ContextBarSliver extends StatelessWidget {
  const ContextBarSliver({
    required this.tabs,
    required this.tabIndex,
    required this.switchTab,
    required this.isInnerBoxScrolled,
    this.screenInlineControls,
    this.inlinePillsFromControlsFn,
    super.key,
  });

  final List<TabConfig> tabs;
  final ValueNotifier<int> tabIndex;
  final void Function(int) switchTab;
  final bool isInnerBoxScrolled;
  final List<DockPill> Function(BuildContext, WidgetRef)? screenInlineControls;
  final List<DockPill> Function(TabControls, BuildContext, WidgetRef)? inlinePillsFromControlsFn;

  @override
  Widget build(BuildContext context) {
    return SliverPinnedHeader(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxHeight <= 0 || constraints.maxWidth <= 0) {
            return const SizedBox.shrink();
          }
          return _ContextBarContent(
            tabs: tabs,
            tabIndex: tabIndex,
            switchTab: switchTab,
            isInnerBoxScrolled: isInnerBoxScrolled,
            screenInlineControls: screenInlineControls,
            inlinePillsFromControlsFn: inlinePillsFromControlsFn,
          );
        },
      ),
    );
  }
}

class _ContextBarContent extends ConsumerWidget {
  const _ContextBarContent({
    required this.tabs,
    required this.tabIndex,
    required this.switchTab,
    required this.isInnerBoxScrolled,
    this.screenInlineControls,
    this.inlinePillsFromControlsFn,
  });

  final List<TabConfig> tabs;
  final ValueNotifier<int> tabIndex;
  final void Function(int) switchTab;
  final bool isInnerBoxScrolled;
  final List<DockPill> Function(BuildContext, WidgetRef)? screenInlineControls;
  final List<DockPill> Function(TabControls, BuildContext, WidgetRef)? inlinePillsFromControlsFn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.spacing;
    final style = GlassPillStyle.dockPill(context);
    final screenControls = screenInlineControls?.call(context, ref) ?? [];

    return ValueListenableBuilder<int>(
      valueListenable: tabIndex,
      builder: (context, index, _) {
        if (tabs.isEmpty) return const SizedBox.shrink();
        
        final tab = tabs[index];
        
        // NEW: Dispatch on controls if present
        List<DockPill> inlineControlPills;
        if (tab.controls != null && inlinePillsFromControlsFn != null) {
          inlineControlPills = inlinePillsFromControlsFn!(tab.controls!, context, ref);
        } else {
          // LEGACY: Use inlineControls
          inlineControlPills = tab.inlineControls?.call(context, ref) ?? [];
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(
            spacing.screenPadding.left,
            spacing.tightSpacing,
            spacing.screenPadding.right,
            spacing.tightSpacing,
          ),
          child: Row(
            children: [
              for (final (pillIdx, pill) in [...screenControls, ...inlineControlPills].indexed)
                PillEntrance(
                  key: ValueKey(('bar', pillIdx)),
                  visible: true,
                  axis: Axis.horizontal,
                  animateEntrance: false,
                  child: Padding(
                    padding: EdgeInsets.only(right: spacing.tightSpacing),
                    child: GlassPill(
                      style: style,
                      isFloating: isInnerBoxScrolled,
                      child: DockPillWidget(pill: pill),
                    ),
                  ),
                ),
              Expanded(
                child: GlassPill(
                  style: style,
                  isFloating: isInnerBoxScrolled,
                  child: ContextPill(
                    tabs: tabs,
                    tabIndex: tabIndex,
                    switchTab: switchTab,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
