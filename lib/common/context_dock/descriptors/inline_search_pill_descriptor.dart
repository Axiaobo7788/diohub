import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:diohub/common/context_dock/content/inline_search_pill_content.dart';
import 'package:diohub/common/context_dock/models/dock_pill_descriptor.dart';

/// Descriptor for inline search pill (non-scope, writes to ValueNotifier).
/// Active: TextField with 300ms debounce.
/// Hint: truncated query.
@immutable
final class InlineSearchPillDescriptor extends DockPillDescriptor {
  const InlineSearchPillDescriptor({required this.queryNotifier})
    : super(icon: Icons.search_rounded);

  final ValueNotifier<String> queryNotifier;

  @override
  List<Object?> get props => [...super.props, queryNotifier];

  @override
  DockPillKind get kind => DockPillKind.activate;

  @override
  Widget? buildContent(final PillPhase phase, final BuildContext context) {
    return switch (phase) {
      PillPhase.active => InlineSearchPillContent(
        descriptor: this,
        queryNotifier: queryNotifier,
      ),
      PillPhase.hint => InlineSearchPillHint(queryNotifier: queryNotifier),
      PillPhase.idle => null,
    };
  }

  @override
  Widget? buildOverlay(final PillPhase phase, final BuildContext context) =>
      null;
}
