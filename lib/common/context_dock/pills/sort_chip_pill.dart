import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/common/context_dock/models/dock_pill.dart';
import 'package:diohub/common/context_dock/models/dock_pill_phase.dart';
import 'package:diohub/common/context_dock/models/pill_tap_behaviour.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/nav_center/models/sort_binding.dart';

/// Pill that shows current sort option and opens popup to change it.
///
/// Accepts a type-safe [SortBinding] that preserves the sort type parameter T.
/// Used by all tab controls that need sorting (SearchTabControls, ClientListTabControls, FilterableTabControls).
class SortChipPill extends DockPill {
  SortChipPill({required this.binding});

  final SortBinding binding;

  @override
  IconData get icon => Icons.sort_rounded;

  @override
  PillTapBehaviour get tapBehaviour => const PopupPill();

  @override
  void onMount(WidgetRef ref) {
    switch (binding) {
      case TypedSortBinding<dynamic>(:final spec, :final getValue):
        final current = getValue(ref);
        value = current == spec.defaultValue
            ? const IdlePhase()
            : const HintPhase();
    }
  }

  @override
  Widget? buildPopupContent(VoidCallback onDismiss) {
    return null;
  }

  @override
  List<ActionButtonData>? buildActions(WidgetRef ref, VoidCallback onDismiss) {
    return switch (binding) {
      TypedSortBinding<dynamic>(
        :final spec,
        :final getValue,
        :final onSelected,
      ) =>
        [
          for (final option in spec.options)
            CheckboxActionButton(
              label: spec.labelOf(option),
              value: option == getValue(ref),
              onChanged: (_) {
                onSelected(ref, option);
                value = option == spec.defaultValue
                    ? const IdlePhase()
                    : const HintPhase();
                onDismiss();
              },
            ),
        ],
    };
  }

  @override
  Widget? buildContent(BuildContext context) {
    return switch (value) {
      HintPhase() => _SortChipHintContent(pill: this),
      _ => null,
    };
  }
}

class _SortChipHintContent extends ConsumerWidget {
  const _SortChipHintContent({required this.pill});

  final SortChipPill pill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (pill.binding) {
      TypedSortBinding<dynamic>(:final spec, :final getValue) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          spec.labelOf(getValue(ref)),
          style: Theme.of(context).textTheme.labelSmall,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    };
  }
}
