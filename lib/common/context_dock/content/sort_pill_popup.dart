import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:diohub/common/context_dock/models/dock_pill_descriptor.dart';
import 'package:diohub/common/context_dock/pills/popup_hint_dock_pill.dart';
import 'package:diohub/providers/dock/dock_pill_state_provider.dart';

/// Hint label showing current non-default sort/filter value.
class SortPillHint<T> extends ConsumerWidget {
  const SortPillHint({
    required this.getValue,
    required this.labelOf,
    required this.defaultValue,
    super.key,
  });

  final T Function(WidgetRef ref) getValue;
  final String Function(T) labelOf;
  final T defaultValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentValue = getValue(ref);
    if (currentValue == defaultValue) return const SizedBox.shrink();

    return Text(
      labelOf(currentValue),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall,
    );
  }
}

/// Overlay popup for sort/option selection. Calls [onSelected](ref, value); updates pill phase on selection.
class SortPillPopup<T> extends ConsumerWidget {
  const SortPillPopup({
    required this.descriptor,
    required this.options,
    required this.getValue,
    required this.onSelected,
    required this.labelOf,
    required this.defaultValue,
    this.sections,
    super.key,
  });

  final DockPillDescriptor descriptor;
  final List<T> options;
  final T Function(WidgetRef ref) getValue;
  final void Function(WidgetRef ref, T value) onSelected;
  final String Function(T) labelOf;
  final T defaultValue;
  final List<PopupSection<T>>? sections;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentValue = getValue(ref);

    void onTap(T option) {
      onSelected(ref, option);
      final notifier = ref.read(dockPillPhaseProvider(descriptor).notifier);
      if (option == defaultValue) {
        notifier.idle();
      } else {
        notifier.hint();
      }
    }

    if (sections != null && sections!.isNotEmpty) {
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final section in sections!)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (section.header != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        section.header!,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  for (final option in section.items)
                    _optionTile(context, ref, option, currentValue, onTap),
                ],
              ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final option in options)
          _optionTile(context, ref, option, currentValue, onTap),
      ],
    );
  }

  Widget _optionTile(
    BuildContext context,
    WidgetRef ref,
    T option,
    T currentValue,
    void Function(T) onTap,
  ) {
    final isSelected = option == currentValue;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        size: 20,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface,
      ),
      title: Text(labelOf(option)),
      onTap: () => onTap(option),
    );
  }
}
