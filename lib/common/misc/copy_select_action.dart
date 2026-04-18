import 'package:diohub/common/misc/action_card.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

/// Creates a reusable Copy action with expandable options
///
/// Returns an ExpandableActionButton that shows:
/// - Copy All (quick action)
/// - Select (opens dialog for selective copy)
ExpandableActionButton createCopySelectAction({
  required final String text,
  required final Future<void> Function(String text) copy,
  required final Widget Function(BuildContext) selectDialogBuilder,
}) =>
    ExpandableActionButton(
      label: 'Copy',
      icon: MdiIcons.contentCopy,
      expandableWidgetBuilder: (final onCollapse) => Builder(
        builder: (final BuildContext context) {
          final MinorActionButton copyAllAction = MinorActionButton(
            label: 'Copy All',
            icon: MdiIcons.contentCopy,
            onTap: () async {
              await copy(text);
              onCollapse();
            },
          );

          final MinorActionButton selectAction = MinorActionButton(
            label: 'Select',
            icon: MdiIcons.cursorText,
            onTap: () async {
              await showDialog(
                context: context,
                builder: selectDialogBuilder,
              );
              onCollapse();
            },
          );

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ActionCard(
                action: copyAllAction,
                onTap: copyAllAction.onTap,
              ),
              context.spacing.tightGap,
              ActionCard(
                action: selectAction,
                onTap: selectAction.onTap,
              ),
            ],
          );
        },
      ),
    );
