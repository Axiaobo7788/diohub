import 'dart:async';

import 'package:diohub/common/context_dock/models/dock_pill.dart';
import 'package:diohub/common/context_dock/models/dock_pill_phase.dart';
import 'package:diohub/common/context_dock/pills/basic_dock_pill.dart';
import 'package:diohub/common/context_dock/pills/compose_dock_pill.dart';
import 'package:diohub/providers/compose/compose_draft_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compose pill for issue/PR comments.
///
/// Active: multi-line compose area + [Send, Attach, Bold, Italic, Expand].
/// Hint: "Draft" when draft text exists. Idle: no draft.
///
/// Constructor takes pure data — no WidgetRef.
class CommentDockPill extends ComposeDockPill {
  CommentDockPill({
    required this.entityType,
    required this.entityId,
    required this.submitComment,
  }) : super(persistenceKey: 'compose_${entityType}_$entityId');

  final String entityType;
  final String entityId;

  /// Mutation to submit the comment. Widget layer provides ref.
  final Future<void> Function(WidgetRef ref, String text) submitComment;

  @override
  IconData get icon => Icons.chat_bubble_outline_rounded;

  @override
  Future<void> onSubmit(WidgetRef ref, String text) => submitComment(ref, text);

  @override
  List<DockPill> buildCompanions() => [
        BasicDockPill(
          iconData: Icons.attach_file_rounded,
          onTapAction: (_) {
            // TODO: pick attachment
          },
        ),
        BasicDockPill(
          iconData: Icons.format_bold_rounded,
          onTapAction: (_) {
            // TODO: insertMarkdown('**', '**')
          },
        ),
        BasicDockPill(
          iconData: Icons.format_italic_rounded,
          onTapAction: (_) {
            // TODO: insertMarkdown('_', '_')
          },
        ),
        BasicDockPill(
          iconData: Icons.open_in_full_rounded,
          onTapAction: (_) {
            // TODO: navigate to full editor
          },
        ),
        BasicDockPill(
          iconData: Icons.send_rounded,
          label: 'Send',
          onTapAction: (ref) async {
            final text = getCurrentText().trim();
            if (text.isEmpty) return;
            try {
              await onSubmit(ref, text);
              await ref
                  .read(composeDraftProvider(DraftKey.pill(persistenceKey))
                      .notifier)
                  .clear();
              value = const IdlePhase();
            } catch (e, st) {
              debugPrintStack(stackTrace: st, label: e.toString());
              // Draft is preserved; snackbar would need context from widget layer
            }
          },
        ),
      ];
}
