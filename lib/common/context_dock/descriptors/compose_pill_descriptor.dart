import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:diohub/common/context_dock/content/compose_pill_content.dart';
import 'package:diohub/common/context_dock/descriptors/basic_pill_descriptor.dart';
import 'package:diohub/common/context_dock/models/dock_pill_descriptor.dart';
import 'package:diohub/providers/compose/compose_draft_notifier.dart';
import 'package:diohub/providers/dock/dock_pill_state_provider.dart';

/// Descriptor for compose pill (comment/review).
/// Active: multi-line text field with draft persistence (500ms debounce).
/// Hint: displays custom hint or "Draft" when text exists.
/// Companions: Submit and Cancel pills.
@immutable
final class ComposePillDescriptor extends DockPillDescriptor {
  const ComposePillDescriptor({
    required this.icon,
    required this.persistenceKey,
    required this.onSubmit,
    this.hintOverride,
  }) : super(icon: icon);

  @override
  final IconData icon;

  /// Draft storage key (used with compose draft provider).
  final String persistenceKey;

  /// Submit callback. Called when Submit companion is tapped.
  final Future<void> Function(WidgetRef ref, String text) onSubmit;

  /// Optional hint override (e.g. review: "N pending"). Default: shows "Draft".
  final Widget? Function(BuildContext context)? hintOverride;

  @override
  List<Object?> get props => [
    ...super.props,
    persistenceKey,
    icon,
    onSubmit,
    hintOverride,
  ];

  @override
  DockPillKind get kind => DockPillKind.activate;

  @override
  List<DockPillDescriptor> get companions => [
    BasicPillDescriptor(
      icon: Icons.send_rounded,
      label: 'Submit',
      onTapAction: (ref) {
        ref.read(composePillSubmitRequestedProvider(this).notifier).state =
            true;
      },
    ),
    BasicPillDescriptor(
      icon: Icons.close_rounded,
      label: 'Cancel',
      onTapAction: (ref) async {
        // Clear draft
        final draftKey = DraftKey.pill(persistenceKey);
        await ref.read(composeDraftProvider(draftKey).notifier).clear();
        // Go idle
        ref.read(dockPillPhaseProvider(this).notifier).idle();
      },
    ),
  ];

  @override
  Widget? buildContent(final PillPhase phase, final BuildContext context) {
    return switch (phase) {
      PillPhase.active => ComposePillContent(
        persistenceKey: persistenceKey,
        descriptor: this,
        onSubmit: onSubmit,
      ),
      PillPhase.hint =>
        hintOverride?.call(context) ??
            Text('Draft', style: Theme.of(context).textTheme.labelSmall),
      PillPhase.idle => null,
    };
  }

  @override
  Widget? buildOverlay(final PillPhase phase, final BuildContext context) =>
      null;
}
