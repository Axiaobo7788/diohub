import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:diohub/common/context_dock/models/dock_pill.dart';
import 'package:diohub/common/context_dock/models/dock_pill_phase.dart';
import 'package:diohub/common/context_dock/models/pill_tap_behaviour.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';

/// Generic popup+hint pill for sort, filter dropdowns, etc.
///
/// Never enters [ActivePhase] — opens a popup anchored to the pill.
/// Transitions to [HintPhase] when a non-default value is selected.
///
/// Stores pure data: [options], [defaultValue], [labelOf], [getValue].
/// [getValue] is called by the widget layer with its [WidgetRef] (e.g. from
/// ref.watch(provider)); [onSelected] is typed as `void Function(WidgetRef, T)`.
class PopupHintDockPill<T> extends DockPill {
  PopupHintDockPill({
    required this.iconData,
    required this.options,
    required this.defaultValue,
    required this.getValue,
    required this.onSelected,
    required this.labelOf,
    this.sections,
  });

  final IconData iconData;
  final List<T> options;
  final T defaultValue;

  /// Returns the current value when the hint/popup content is built.
  /// Called by [ConsumerWidget] with its [WidgetRef] (e.g. `(ref) => ref.watch(provider)`).
  final T Function(WidgetRef ref) getValue;

  /// Called by widget layer when user selects an option.
  final void Function(WidgetRef ref, T value) onSelected;

  final String Function(T) labelOf;

  /// Optional sections for grouped popup layout.
  final List<PopupSection<T>>? sections;

  @override
  IconData get icon => iconData;

  @override
  PillTapBehaviour get tapBehaviour => const PopupPill();

  @override
  Widget? buildPopupContent(VoidCallback onDismiss) {
    return _PopupHintPopupContent<T>(
      pill: this,
      onDismiss: onDismiss,
    );
  }

  @override
  List<ActionButtonData>? buildActions(WidgetRef ref, VoidCallback onDismiss) {
    final currentValue = getValue(ref);
    if (sections != null && sections!.isNotEmpty) {
      final list = <ActionButtonData>[];
      for (final section in sections!) {
        for (final option in section.items) {
          list.add(
            CheckboxActionButton(
              label: labelOf(option),
              value: option == currentValue,
              category: section.header,
              onChanged: (_) {
                onSelected(ref, option);
                value = option == defaultValue
                    ? const IdlePhase()
                    : const HintPhase();
                onDismiss();
              },
            ),
          );
        }
      }
      return list;
    }
    return [
      for (final option in options)
        CheckboxActionButton(
          label: labelOf(option),
          value: option == currentValue,
          onChanged: (_) {
            onSelected(ref, option);
            value =
                option == defaultValue ? const IdlePhase() : const HintPhase();
            onDismiss();
          },
        ),
    ];
  }

  @override
  Widget? buildContent(BuildContext context) {
    return switch (value) {
      HintPhase() => _PopupHintLabel<T>(
          getValue: getValue,
          labelOf: labelOf,
          defaultValue: defaultValue,
        ),
      _ => null,
    };
  }
}

/// Section header + items for grouped popup.
class PopupSection<T> {
  const PopupSection({this.header, required this.items});
  final String? header;
  final List<T> items;
}

/// Popup content for [PopupHintDockPill].
///
/// [ConsumerWidget] — calls [getValue](ref) to get current selection.
/// Calls [onSelected](ref, value) when user taps an option.
class _PopupHintPopupContent<T> extends ConsumerWidget {
  const _PopupHintPopupContent({
    required this.pill,
    required this.onDismiss,
  });

  final PopupHintDockPill<T> pill;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentValue = pill.getValue(ref);

    if (pill.sections != null && pill.sections!.isNotEmpty) {
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final section in pill.sections!)
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
                    _optionTile(context, ref, option, currentValue),
                ],
              ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final option in pill.options)
          _optionTile(context, ref, option, currentValue),
      ],
    );
  }

  Widget _optionTile(
    BuildContext context,
    WidgetRef ref,
    T option,
    T currentValue,
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
      title: Text(pill.labelOf(option)),
      onTap: () {
        pill.onSelected(ref, option);
        pill.value =
            option == pill.defaultValue ? const IdlePhase() : const HintPhase();
        onDismiss();
      },
    );
  }
}

/// Hint label showing the current non-default value.
///
/// [ConsumerWidget] — calls [getValue](ref) to read current value.
class _PopupHintLabel<T> extends ConsumerWidget {
  const _PopupHintLabel({
    required this.getValue,
    required this.labelOf,
    required this.defaultValue,
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
