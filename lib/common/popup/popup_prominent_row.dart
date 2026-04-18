import 'package:diohub/common/misc/action_card.dart';
import 'package:diohub/common/misc/action_card_style.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// Horizontal row of 2–4 primary action cards with consistent gap.
///
/// Use for primary section when all actions are simple (no [ExpandableActionButton],
/// no [SheetActionButton]). Caller is responsible for filtering.
/// Each card uses the same [ActionCardStyle] (e.g. [ActionCardStyle.primaryPopup]).
/// On tap: runs action then calls [onDismiss] (e.g. to close popup/toolbar).
/// Gap between cards uses [AppSpacing.itemSpacing] from theme.
class ProminentActionsRow extends StatelessWidget {
  const ProminentActionsRow({
    required this.actions,
    this.style = ActionCardStyle.primaryPopup,
    this.onDismiss,
    this.spacing,
    super.key,
  });

  final List<ActionButtonData> actions;
  final ActionCardStyle style;
  final VoidCallback? onDismiss;

  /// Gap between cards. If null, uses [AppSpacing.itemSpacing] from theme.
  final double? spacing;

  @override
  Widget build(final BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();
    final double gap = spacing ?? context.spacing.itemSpacing;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < actions.length; i++) ...<Widget>[
          if (i > 0) SizedBox(width: gap),
          _buildCard(context, actions[i]),
        ],
      ],
    );
  }

  Widget _buildCard(final BuildContext context, final ActionButtonData action) {
    if (action is SheetActionButton) {
      final SheetActionButton sheetAction = action;
      return ActionCard(
        action: action,
        style: style,
        onTap: action.enabled
            ? () {
                onDismiss?.call();
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

    return ActionCard(
      action: action,
      style: style,
      onTap: action.enabled
          ? () {
              if (action.handleTapAndShouldCollapse(onDismiss)) {
                onDismiss?.call();
              }
            }
          : null,
    );
  }
}
