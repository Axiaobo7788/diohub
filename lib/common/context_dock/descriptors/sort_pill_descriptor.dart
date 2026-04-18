import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:diohub/common/context_dock/content/sort_pill_popup.dart';
import 'package:diohub/common/context_dock/models/dock_pill_descriptor.dart';
import 'package:diohub/common/context_dock/pills/popup_hint_dock_pill.dart';

/// Generic descriptor for sort/option selection pill with popup.
/// Active: shows popup with radio-button options.
/// Hint: displays current value when non-default.
@immutable
final class SortPillDescriptor<T> extends DockPillDescriptor {
  const SortPillDescriptor({
    required IconData icon,
    required this.options,
    required this.getValue,
    required this.onSelected,
    required this.labelOf,
    required this.defaultValue,
    this.sections,
  }) : super(icon: icon);

  final List<T> options;
  final T Function(WidgetRef ref) getValue;
  final void Function(WidgetRef ref, T value) onSelected;
  final String Function(T) labelOf;
  final T defaultValue;
  final List<PopupSection<T>>? sections;

  @override
  List<Object?> get props => [
    ...super.props,
    options,
    getValue,
    onSelected,
    labelOf,
    defaultValue,
    sections,
  ];

  @override
  DockPillKind get kind => DockPillKind.popup;

  @override
  Widget? buildContent(final PillPhase phase, final BuildContext context) {
    return switch (phase) {
      PillPhase.active => null,
      PillPhase.hint => SortPillHint<T>(
        getValue: getValue,
        labelOf: labelOf,
        defaultValue: defaultValue,
      ),
      PillPhase.idle => null,
    };
  }

  @override
  Widget? buildOverlay(final PillPhase phase, final BuildContext context) {
    if (phase != PillPhase.active) return null;
    return SortPillPopup<T>(
      descriptor: this,
      options: options,
      getValue: getValue,
      onSelected: onSelected,
      labelOf: labelOf,
      defaultValue: defaultValue,
      sections: sections,
    );
  }
}
