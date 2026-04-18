import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:diohub/common/context_dock/content/search_pill_content.dart';
import 'package:diohub/common/context_dock/models/dock_pill_descriptor.dart';
import 'package:diohub/models/search/search_scope.dart';

/// Descriptor for scope-based search pill.
/// Active: auto-focused TextField with 300ms debounce.
/// Hint: truncated search query.
@immutable
final class SearchPillDescriptor extends DockPillDescriptor {
  const SearchPillDescriptor({required this.scope, super.startsActive})
    : super(icon: Icons.search_rounded);

  final SearchScope scope;

  @override
  List<Object?> get props => [...super.props, scope];

  @override
  DockPillKind get kind => DockPillKind.activate;

  @override
  Widget? buildContent(final PillPhase phase, final BuildContext context) {
    return switch (phase) {
      PillPhase.active => SearchPillContent(scope: scope, descriptor: this),
      PillPhase.hint => SearchPillHint(scope: scope),
      PillPhase.idle => null,
    };
  }

  @override
  Widget? buildOverlay(final PillPhase phase, final BuildContext context) =>
      null;
}
