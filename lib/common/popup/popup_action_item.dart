import 'package:diohub/common/misc/action_card.dart';
import 'package:diohub/common/misc/action_card_style.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/expandable_action_card.dart';
import 'package:flutter/material.dart';

/// Renders an ActionButtonData in popup menu context
class PopupActionItem extends StatelessWidget {
  const PopupActionItem({
    required this.action,
    this.onTap,
    super.key,
  });

  final ActionButtonData action;
  final VoidCallback? onTap;

  @override
  Widget build(final BuildContext context) {
    // Delegate to ExpandableActionCard for expandable actions
    if (action is ExpandableActionButton) {
      return ExpandableActionCard(
        action: action as ExpandableActionButton,
        style: ActionCardStyle.popup,
        onOptionSelected: onTap,
      );
    }

    // Sheet actions dismiss the menu then open a bottom sheet
    if (action is SheetActionButton) {
      final SheetActionButton sheetAction = action as SheetActionButton;
      return ActionCard(
        action: action,
        onTap: action.enabled
            ? () {
                onTap?.call(); // dismiss popup
                WidgetsBinding.instance.addPostFrameCallback((final _) {
  // ignore: prefer_async_await
                  sheetAction.openSheet(context).then((final result) {
                    sheetAction.onResult?.call(result);
                  });
                });
              }
            : null,
      );
    }

    // Standard action: parent supplies onTap that runs handleTapAndShouldCollapse(dismiss) and conditionally dismisses
    return ActionCard(
      action: action,
      onTap: action.enabled ? onTap : null,
    );
  }
}
