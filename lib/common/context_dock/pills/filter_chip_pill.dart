import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/common/context_dock/models/dock_pill.dart';
import 'package:diohub/common/context_dock/models/dock_pill_phase.dart';
import 'package:diohub/common/context_dock/models/pill_tap_behaviour.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/search_overlay/filter_section_def.dart';
import 'package:diohub/common/search_overlay/filter_state_adapter.dart';
import 'package:diohub/common/search_overlay/unified_filter_sheet.dart';

/// Pill that shows "Filter (N)" badge and opens [UnifiedFilterSheet].
///
/// Used by [FilterableTabControls]. Shows active filter count in HintPhase.
class FilterChipPill extends DockPill {
  FilterChipPill({
    required this.adapter,
    required this.sections,
    required this.activeFilterCount,
    this.cacheKey,
  });

  final FilterStateAdapter adapter;
  final List<FilterSectionDef> sections;
  final int Function() activeFilterCount;
  final String? cacheKey;

  @override
  IconData get icon => Icons.filter_list_rounded;

  @override
  PillTapBehaviour get tapBehaviour => const PopupPill();

  @override
  void onMount(WidgetRef ref) {
    final count = activeFilterCount();
    value = count > 0 ? const HintPhase() : const IdlePhase();
    
    adapter.addListener(() {
      final newCount = activeFilterCount();
      value = newCount > 0 ? const HintPhase() : const IdlePhase();
    });
  }

  @override
  List<ActionButtonData>? buildActions(WidgetRef ref, VoidCallback onDismiss) {
    return [
      SheetActionButton(
        icon: Icons.filter_list_rounded,
        label: 'Filters',
        headerBuilder: (ctx, setState) =>
            UnifiedFilterSheet.buildHeader(ctx, adapter),
        sheetBuilder: (ctx, [scrollController]) => UnifiedFilterSheet(
          adapter: adapter,
          scrollController: scrollController!,
          cacheKey: cacheKey,
        ),
      ),
      MinorActionButton(
        icon: Icons.check_rounded,
        label: 'Done',
        onTap: onDismiss,
      ),
    ];
  }

  @override
  Widget? buildContent(BuildContext context) {
    return switch (value) {
      HintPhase() => _FilterChipHintContent(
          count: activeFilterCount(),
        ),
      _ => null,
    };
  }
}

class _FilterChipHintContent extends StatelessWidget {
  const _FilterChipHintContent({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
