import 'package:diohub/common/context_dock/models/dock_pill.dart';
import 'package:diohub/common/context_dock/models/dock_pill_phase.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/popup/popup_menu.dart';
import 'package:diohub/common/search_overlay/search_filter_sheet.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/providers/search/search_state_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dock pill for search qualifier filters.
///
/// Active: overlay with quick filters + active chips; optional "More" opens full sheet.
/// Hint: "N filters" when non-default qualifiers active. Idle: no filters.
class FilterDockPill extends DockPill {
  FilterDockPill({required this.scope});

  final SearchScope scope;

  @override
  IconData get icon => Icons.filter_list_rounded;

  @override
  void onMount(WidgetRef ref) {
    final state = ref.read(searchStateNotifierProvider(scope));
    if (state.isActive) value = const HintPhase();
  }

  @override
  void onTap(BuildContext context, WidgetRef ref) {
    value = const ActivePhase();
  }

  @override
  Widget? buildContent(BuildContext context) {
    return switch (value) {
      ActivePhase() => _FilterActiveContent(scope: scope, pill: this),
      HintPhase() => _FilterHintContent(scope: scope),
      IdlePhase() => null,
    };
  }

  @override
  List<ActionButtonData>? buildActions(WidgetRef ref, VoidCallback onDismiss) {
    final state = ref.watch(searchStateNotifierProvider(scope));
    final notifier = ref.read(searchStateNotifierProvider(scope).notifier);
    final actions = <ActionButtonData>[
      for (final qf in scope.quickFilters)
        CheckboxActionButton(
          label: qf.displayLabel,
          value: state.activeQuickFilter == qf,
          onChanged: (_) => notifier.toggleQuickFilter(qf),
        ),
      SheetActionButton(
        icon: Icons.tune_rounded,
        label: 'More filters',
        headerBuilder: (ctx, setState) =>
            SearchFilterSheet.buildHeader(ctx, scope, ref),
        sheetBuilder: (ctx, [scrollController]) => SearchFilterSheet(
            scope: scope, scrollController: scrollController!),
      ),
      MinorActionButton(
        icon: Icons.check_rounded,
        label: 'Done',
        onTap: onDismiss,
      ),
    ];
    return actions;
  }

  @override
  Widget? buildOverlay(BuildContext context) {
    if (value is! ActivePhase) return null;
    return _FilterOverlay(scope: scope, pill: this);
  }
}

class _FilterActiveContent extends ConsumerWidget {
  const _FilterActiveContent({required this.scope, required this.pill});

  final SearchScope scope;
  final DockPill pill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Text(
      'Filters',
      style: Theme.of(context).textTheme.labelMedium,
    );
  }
}

class _FilterOverlay extends ConsumerWidget {
  const _FilterOverlay({required this.scope, required this.pill});

  final SearchScope scope;
  final FilterDockPill pill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void onDismiss() {
      final state = ref.read(searchStateNotifierProvider(scope));
      pill.value = state.isActive ? const HintPhase() : const IdlePhase();
    }

    final actions = pill.buildActions(ref, onDismiss);
    return PopupMenu(
      actions: actions ?? [],
      onDismiss: onDismiss,
    );
  }
}

class _FilterHintContent extends ConsumerWidget {
  const _FilterHintContent({required this.scope});

  final SearchScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qualifiers = ref.watch(
      searchStateNotifierProvider(scope).select((s) => s.activeQualifiers),
    );
    final count = qualifiers.length;

    if (count == 0) return const SizedBox.shrink();

    return Text(
      '$count filter${count > 1 ? 's' : ''}',
      maxLines: 1,
      style: Theme.of(context).textTheme.labelSmall,
    );
  }
}
