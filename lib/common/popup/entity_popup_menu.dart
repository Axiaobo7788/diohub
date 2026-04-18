import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/common/misc/action_card.dart';
import 'package:diohub/common/misc/action_card_style.dart';
import 'package:diohub/common/misc/action_icon_strip.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/expandable_action_card.dart';
import 'package:diohub/common/misc/liquid_glass_wrapper.dart';
import 'package:diohub/common/misc/popup_section_label.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PopupSectionStyle { primary, standard, utility }

class PopupMenuSection {
  const PopupMenuSection({
    required this.actions,
    this.style = PopupSectionStyle.standard,
    this.headerLabel,
    this.customContent,
  });

  final List<ActionButtonData> actions;
  final PopupSectionStyle style;

  /// Optional label shown above the section (e.g. "Manage", "Quick actions").
  final String? headerLabel;

  /// Optional custom widget (e.g. pinned repos list). Rendered after header, before actions.
  final Widget? customContent;
}

class EntityPopupMenu extends StatefulWidget {
  const EntityPopupMenu({
    required this.sections,
    this.onDismiss,
    super.key,
  });

  final List<PopupMenuSection> sections;
  final VoidCallback? onDismiss;

  @override
  State<EntityPopupMenu> createState() => _EntityPopupMenuState();
}

class _EntityPopupMenuState extends State<EntityPopupMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  int _totalItems = 0;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (mounted) {
        _entranceController.forward();
      }
    });
  }

  void _initAnimations() {
    _totalItems = widget.sections.fold<int>(
      0,
      (final int sum, final PopupMenuSection section) =>
          sum + section.actions.length,
    );

    final Duration totalDuration = Duration(
      milliseconds: (180 + _totalItems * 35).clamp(180, 500),
    );

    _entranceController = AnimationController(
      vsync: this,
      duration: totalDuration,
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Widget _wrapItem(final int index, final Widget child) {
    if (index >= _totalItems) return child;
    final double startFraction = (index * 0.07).clamp(0.0, 0.6);
    final double endFraction = (startFraction + 0.5).clamp(0.0, 1.0);
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _entranceController,
        curve: Interval(startFraction, endFraction, curve: kStateCurve),
      ),
      child: child,
    );
  }

  ActionCardStyle _getStyleForSection(
    final BuildContext context,
    final PopupSectionStyle style,
  ) {
    switch (style) {
      case PopupSectionStyle.primary:
        return ActionCardStyle.primaryPopup;
      case PopupSectionStyle.standard:
        return ActionCardStyle.popup;
      case PopupSectionStyle.utility:
        return ActionCardStyle.utilityPopup(context);
    }
  }

  void _handleAction(
    final BuildContext context,
    final ActionButtonData action,
  ) {
    if (!action.enabled) return;
    switch (action.dismissBehavior) {
      case ActionDismissBehavior.none:
        action.handleTapAndShouldCollapse(null);
        break;
      case ActionDismissBehavior.immediate:
        widget.onDismiss?.call();
        action.handleTapAndShouldCollapse(null);
        break;
      case ActionDismissBehavior.afterSheet:
        widget.onDismiss?.call();
        if (action is SheetActionButton) {
          WidgetsBinding.instance.addPostFrameCallback((final _) {
            // ignore: prefer_async_await
            action.openSheet(context).then((final result) {
              action.onResult?.call(result);
            });
          });
        } else if (action is ReactiveActionButton &&
            action.builder(null) is SheetActionButton) {
          final sheetAction = action.builder(null) as SheetActionButton;
          // ignore: prefer_async_await
          WidgetsBinding.instance.addPostFrameCallback((final _) {
            // ignore: prefer_async_await
            sheetAction.openSheet(context).then((final result) {
              sheetAction.onResult?.call(result);
            });
          });
        }
        break;
    }
  }

  Widget _buildAction(
    final BuildContext context,
    final ActionButtonData action,
    final ActionCardStyle style,
    final int itemIndex,
  ) {
    if (action is ReactiveActionButton) {
      return _wrapItem(
        itemIndex,
        Consumer(
          builder: (final _, final WidgetRef ref, final __) {
            final value = action.getValue(ref);
            final inner = action.builder(value);
            final Widget actionWidget = inner is ExpandableActionButton
                ? ExpandableActionCard(
                    action: inner,
                    style: style,
                    onOptionSelected: null,
                  )
                : ActionCard(
                    action: inner,
                    style: style,
                    onTap: inner.enabled
                        ? () => _handleAction(context, inner)
                        : null,
                  );
            return KeyedSubtree(
              key: inner.getStableKey(),
              child: actionWidget,
            );
          },
        ),
      );
    }

    Widget actionWidget;
    if (action is ExpandableActionButton) {
      actionWidget = ExpandableActionCard(
        action: action,
        style: style,
        onOptionSelected: null,
      );
    } else {
      actionWidget = ActionCard(
        action: action,
        style: style,
        onTap: action.enabled ? () => _handleAction(context, action) : null,
      );
    }

    return _wrapItem(
      itemIndex,
      KeyedSubtree(
        key: ValueKey(action.label),
        child: actionWidget,
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppSpacing spacing = context.spacing;
    final double blockSpacing = spacing.sectionSpacing;
    final double itemSpacing = spacing.itemSpacing;
    int itemIndex = 0;
    final List<Widget> columnChildren = <Widget>[];

    for (int sectionIndex = 0;
        sectionIndex < widget.sections.length;
        sectionIndex++) {
      final PopupMenuSection section = widget.sections[sectionIndex];
      final ActionCardStyle style = _getStyleForSection(context, section.style);

      if (sectionIndex > 0) {
        columnChildren.addAll(<Widget>[
          Divider(height: 1, color: colorScheme.outline.tint),
          SizedBox(height: blockSpacing),
        ]);
      }

      switch (section.style) {
        case PopupSectionStyle.primary:
          final List<ActionButtonData> actions = section.actions;
          if (section.headerLabel != null) {
            columnChildren.add(PopupSectionLabel(label: section.headerLabel!));
          }
          if (section.customContent != null) {
            columnChildren.add(section.customContent!);
            columnChildren.add(SizedBox(height: itemSpacing));
          }
          for (int i = 0; i < actions.length; i++) {
            columnChildren.add(
              _buildAction(context, actions[i], style, itemIndex++),
            );
            if (i < actions.length - 1) {
              columnChildren.add(SizedBox(height: itemSpacing));
            }
          }

        case PopupSectionStyle.standard:
          if (section.headerLabel != null) {
            columnChildren.add(PopupSectionLabel(label: section.headerLabel!));
          }
          if (section.customContent != null) {
            columnChildren.add(section.customContent!);
            columnChildren.add(SizedBox(height: itemSpacing));
          }
          for (int i = 0; i < section.actions.length; i++) {
            columnChildren.add(
              _buildAction(
                context,
                section.actions[i],
                style,
                itemIndex++,
              ),
            );
            if (i < section.actions.length - 1) {
              columnChildren.add(SizedBox(height: itemSpacing));
            }
          }

        case PopupSectionStyle.utility:
          if (section.headerLabel != null) {
            columnChildren.add(PopupSectionLabel(label: section.headerLabel!));
          }
          if (section.customContent != null) {
            columnChildren.add(section.customContent!);
            columnChildren.add(SizedBox(height: itemSpacing));
          }
          columnChildren.add(
            ActionIconStrip(
              actions: section.actions,
              onDismiss: widget.onDismiss,
            ),
          );
          itemIndex += section.actions.length;
      }

      if (sectionIndex < widget.sections.length - 1) {
        columnChildren.add(SizedBox(height: blockSpacing));
      }
    }

    return LiquidGlassWrapper(
      size: RadiusSize.large,
      child: Padding(
        padding: EdgeInsets.all(spacing.itemSpacing),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.5,
            ),
            child: KeyedSubtree(
              key: ValueKey(widget.sections.length),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: columnChildren,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
