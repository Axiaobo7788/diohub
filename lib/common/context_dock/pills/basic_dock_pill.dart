import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:diohub/common/context_dock/models/dock_pill.dart';
import 'package:diohub/common/context_dock/models/pill_tap_behaviour.dart';

/// Fire-and-forget dock pill — taps an action, never changes phase.
///
/// Used for creation actions, navigation, and simple commands.
///
/// [onTapAction] is typed as `void Function(WidgetRef)` — the widget layer
/// supplies ref at invocation time. The pill declares WHAT to do;
/// [DockPillWidget] provides the HOW (the ref).
///
/// [label] is optional — when provided, renders as text next to icon
/// in idle phase (e.g. "ZIP", "Send", "Approve").
class BasicDockPill extends DockPill {
  BasicDockPill({
    required this.iconData,
    required this.onTapAction,
    this.label,
  });

  final IconData iconData;
  final String? label;

  /// Called by [DockPillWidget] when tapped.
  /// Widget layer passes its [WidgetRef] at invocation time.
  final void Function(WidgetRef ref) onTapAction;

  @override
  IconData get icon => iconData;

  @override
  PillTapBehaviour get tapBehaviour => const FireAndForget();

  @override
  void onTap(BuildContext context, WidgetRef ref) {
    onTapAction(ref);
  }

  @override
  Widget? buildContent(BuildContext context) {
    if (label == null) return null;
    return Text(
      label!,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall,
    );
  }
}
