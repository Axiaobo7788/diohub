import 'package:diohub/common/misc/action_card_style.dart';
import 'package:diohub/common/misc/action_icon_strip.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/liquid_glass_wrapper.dart';
import 'package:diohub/common/popup/popup_action_layout.dart';
import 'package:diohub/common/popup/popup_action_item.dart';
import 'package:diohub/common/popup/popup_prominent_row.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_anchor/flutter_anchor.dart' show Anchor;

/// How to lay out actions in the popup: vertical list, icon strip, or row.
enum PopupActionLayout {
  /// Vertical list of action cards (default).
  list,

  /// Horizontal icon-only strip with tooltips.
  iconStrip,

  /// Horizontal row of labeled action cards.
  row,
}

/// A popup menu container that displays a list of actions
///
/// Uses LiquidGlassWrapper for consistent styling with toolbars.
/// Groups actions by category and shows dividers between groups.
///
/// Entrance animation is handled by the parent (e.g. [Anchor]'s
/// transitionBuilder or [showGeneralDialog]'s route transition)
/// to avoid double-stacked opacity which causes a visible flicker.
class PopupMenu extends StatelessWidget {
  const PopupMenu({
    required this.actions,
    this.title,
    this.subtitle,
    this.maxHeight,
    this.actionLayout = PopupActionLayout.list,
    this.onDismiss,
    super.key,
  });

  /// List of actions to display
  final List<ActionButtonData> actions;

  /// Optional title displayed in the header
  final String? title;

  /// Optional subtitle displayed in the header
  final String? subtitle;

  /// Maximum height of the menu
  /// If null, the menu will size to its content
  final double? maxHeight;

  /// How to lay out actions: list, icon strip, or row.
  final PopupActionLayout actionLayout;

  /// Callback when the menu should be dismissed
  final VoidCallback? onDismiss;

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;

    return LiquidGlassWrapper(
      size: RadiusSize.large,
      child: Padding(
        padding: EdgeInsets.all(spacing.itemSpacing),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.5,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ..._buildHeader(context, spacing),
                ..._buildActions(context, spacing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static bool _isUrlTitle(final String title) => title.contains('://');

  List<Widget> _buildHeader(
      final BuildContext context, final AppSpacing spacing) {
    if (title == null) return <Widget>[];
    final bool isUrlTitle = _isUrlTitle(title!);
    return <Widget>[
      Padding(
        padding: EdgeInsets.only(
          left: spacing.tightSpacing,
          right: spacing.tightSpacing,
          bottom: spacing.sectionSpacing,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title!,
              style: isUrlTitle
                  ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      )
                  : Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
              maxLines: isUrlTitle ? 1 : 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...<Widget>[
              SizedBox(height: spacing.tightSpacing),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildActions(
      final BuildContext context, final AppSpacing spacing) {
    switch (actionLayout) {
      case PopupActionLayout.iconStrip:
        return <Widget>[
          ActionIconStrip(
            actions: actions,
            onDismiss: onDismiss,
          ),
        ];
      case PopupActionLayout.row:
        return <Widget>[
          ProminentActionsRow(
            actions: actions,
            style: ActionCardStyle.utilityPopup(context),
            onDismiss: onDismiss,
          ),
        ];
      case PopupActionLayout.list:
        final Map<String?, List<ActionButtonData>> grouped =
            groupActionsByCategory(actions);
        final List<String?> categories = grouped.keys.toList();
        return categories
            .asMap()
            .entries
            .expand((final MapEntry<int, String?> entry) {
          final int index = entry.key;
          final String? category = entry.value;
          final List<ActionButtonData> categoryActions = grouped[category]!;

          return <Widget>[
            if (category != null) ...<Widget>[
              if (title != null || index > 0)
                SizedBox(height: spacing.itemSpacing),
              CategoryHeader(category: category),
              SizedBox(height: spacing.itemSpacing),
            ],
            ...categoryActions
                .asMap()
                .entries
                .expand((final MapEntry<int, ActionButtonData> actionEntry) {
              final int actionIndex = actionEntry.key;
              final ActionButtonData action = actionEntry.value;
              return <Widget>[
                PopupActionItem(
                  action: action,
                  onTap: () {
                    if (action.handleTapAndShouldCollapse(onDismiss)) {
                      onDismiss?.call();
                    }
                  },
                ),
                if (actionIndex < categoryActions.length - 1)
                  SizedBox(height: spacing.itemSpacing),
              ];
            }),
            if (index < categories.length - 1)
              SizedBox(height: spacing.itemSpacing),
          ];
        }).toList();
    }
  }
}
