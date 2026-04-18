import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub/common/popup/popup_action_item.dart'
    show PopupActionItem;
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

/// Horizontal row of icon-only action buttons (no labels).
///
/// Used for utility block in popup menus and peek quick actions (Open, Copy, Share).
/// Tooltip shows [ActionButtonData.label] for accessibility.
/// Same tap/sheet behavior as [PopupActionItem]: dismiss then run action (or open sheet).
/// Spacing and padding use [AppSpacing] from theme.
class ActionIconStrip extends StatelessWidget {
  const ActionIconStrip({
    required this.actions,
    this.onDismiss,
    this.iconSize = 20,
    this.spacing,
    super.key,
  });

  final List<ActionButtonData> actions;
  final VoidCallback? onDismiss;
  final double iconSize;

  /// Gap between icons. If null, uses [AppSpacing.itemSpacing] from theme.
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
          _buildIconButton(context, actions[i]),
        ],
      ],
    );
  }

  Widget _buildIconButton(
      final BuildContext context, final ActionButtonData action) {
    final Color iconColor = action.getIconColor(context);

    if (action is SheetActionButton) {
      final SheetActionButton sheetAction = action;
      return Tooltip(
        message: action.label,
        child: TapFeedback(
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
          child: Padding(
            padding: context.spacing.inputPadding,
            child: Icon(
              action.displayIcon,
              size: iconSize,
              color: action.enabled
                  ? iconColor
                  : context.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: action.label,
      child: TapFeedback(
        onTap: action.enabled
            ? () {
                if (action.handleTapAndShouldCollapse(onDismiss)) {
                  onDismiss?.call();
                }
              }
            : null,
        child: Padding(
          padding: context.spacing.inputPadding,
          child: Icon(
            action.displayIcon,
            size: iconSize,
            color: action.enabled
                ? iconColor
                : context.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
