import 'package:diohub/common/context_dock/models/dock_pill.dart';
import 'package:diohub/common/context_dock/models/pill_tap_behaviour.dart';
import 'package:diohub/common/popup/popup_button.dart';
import 'package:diohub/common/popup/popup_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compact chip rendering a [DockPill] inside the [ContextPill].
/// For [PopupPill]: owns a [PopupButton] with [DockPill.buildActions] or
/// [DockPill.buildPopupContent]. For [ActivatePill]/[FireAndForget]: calls
/// [DockPill.onTap] on tap (with optional upgrade check).
class InlineControlChip extends ConsumerWidget {
  const InlineControlChip({required this.pill, super.key});

  final DockPill pill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = pill.buildContent(context);

    Widget chipContent(bool isOpen) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            pill.icon,
            size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          if (content != null) ...[const SizedBox(width: 4), content],
        ],
      ),
    );

    void handleTap() {
      pill.onTap(context, ref);
    }

    switch (pill.tapBehaviour) {
      case PopupPill():
        return PopupButton(
          buttonBuilder: (_, showMenu) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: showMenu,
            child: chipContent(false),
          ),
          popupBuilder: (_, close) {
            final actions = pill.buildActions(ref, close);
            if (actions != null && actions.isNotEmpty) {
              return PopupMenu(actions: actions, onDismiss: close);
            }
            return pill.buildPopupContent(close) ?? const SizedBox.shrink();
          },
        );
      case FireAndForget():
      case ActivatePill():
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: handleTap,
          child: chipContent(false),
        );
    }
  }
}
