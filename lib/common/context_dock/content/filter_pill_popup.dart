import 'package:diohub/common/context_dock/models/dock_pill_descriptor.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/popup/popup_menu.dart';
import 'package:diohub/common/search_overlay/search_filter_sheet.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/providers/dock/dock_pill_state_provider.dart';
import 'package:diohub/providers/search/search_state_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hint-phase label: "N filter(s)" when qualifiers are active.
class FilterPillHint extends ConsumerWidget {
  const FilterPillHint({required this.scope, super.key});

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

/// Active-phase inline label next to the filter icon.
class FilterPillActiveLabel extends StatelessWidget {
  const FilterPillActiveLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Filters',
      style: Theme.of(context).textTheme.labelMedium,
    );
  }
}

/// Overlay popup: quick filters, "More filters" sheet, Done. On dismiss updates pill phase.
class FilterPillOverlay extends ConsumerWidget {
  const FilterPillOverlay({
    required this.scope,
    required this.descriptor,
    super.key,
  });

  final SearchScope scope;
  final DockPillDescriptor descriptor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void onDismiss() {
      final state = ref.read(searchStateNotifierProvider(scope));
      final notifier = ref.read(dockPillPhaseProvider(descriptor).notifier);
      if (state.isActive) {
        notifier.hint();
      } else {
        notifier.idle();
      }
    }

    final searchState = ref.watch(searchStateNotifierProvider(scope));
    final notifier = ref.read(searchStateNotifierProvider(scope).notifier);
    final actions = <ActionButtonData>[
      for (final qf in scope.quickFilters)
        CheckboxActionButton(
          label: qf.displayLabel,
          value: searchState.activeQuickFilter == qf,
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

    return PopupMenu(
      actions: actions,
      onDismiss: onDismiss,
    );
  }
}
