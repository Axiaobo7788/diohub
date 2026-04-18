import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:diohub/common/context_dock/content/filter_pill_popup.dart';
import 'package:diohub/common/context_dock/models/dock_pill_descriptor.dart';
import 'package:diohub/models/search/search_scope.dart';

/// Descriptor for search filter pill with popup actions.
/// Active: shows quick filter toggles + "More filters" sheet action.
/// Hint: displays filter count.
@immutable
final class FilterPillDescriptor extends DockPillDescriptor {
  const FilterPillDescriptor({required this.scope})
    : super(icon: Icons.filter_list_rounded);

  final SearchScope scope;

  @override
  List<Object?> get props => [...super.props, scope];

  @override
  DockPillKind get kind => DockPillKind.popup;

  @override
  Widget? buildContent(final PillPhase phase, final BuildContext context) {
    return switch (phase) {
      PillPhase.active => const FilterPillActiveLabel(),
      PillPhase.hint => FilterPillHint(scope: scope),
      PillPhase.idle => null,
    };
  }

  @override
  Widget? buildOverlay(final PillPhase phase, final BuildContext context) {
    if (phase != PillPhase.active) return null;
    return FilterPillOverlay(scope: scope, descriptor: this);
  }
}
