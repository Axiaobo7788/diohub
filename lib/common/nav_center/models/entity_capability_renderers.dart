import 'package:flutter/material.dart';

import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/nav_center/models/entity_capability.dart';
import 'package:diohub/common/nav_center/settings/settings_section.dart';
import 'package:diohub/common/popup/entity_popup_menu.dart';

/// Builds popup menu sections from a list of capabilities.
/// Groups by [CapabilityGroup] → one [PopupMenuSection] per group.
/// Utility group uses [PopupSectionStyle.utility]; others use [PopupSectionStyle.primary].
List<PopupMenuSection> buildPopupFromCapabilities(
  List<EntityCapability> caps,
) {
  final sections = <PopupMenuSection>[];
  final grouped = <CapabilityGroup, List<ActionButtonData>>{};

  for (final cap in caps) {
    if (!cap.isVisible) continue;
    final actions = cap.popupActions;
    if (actions.isEmpty) continue;
    grouped.putIfAbsent(cap.group, () => []).addAll(actions);
  }

  for (final entry in grouped.entries) {
    sections.add(
      PopupMenuSection(
        style: entry.key == CapabilityGroup.utility
            ? PopupSectionStyle.utility
            : PopupSectionStyle.primary,
        actions: entry.value,
      ),
    );
  }
  return sections;
}

/// Builds settings tab content from a list of capabilities.
/// Groups by [CapabilityGroup] → one [SettingsSection] per group.
/// Skips groups that produce no visible widgets. Danger zone gets special styling.
List<Widget> buildSettingsFromCapabilities(
  List<EntityCapability> caps,
  BuildContext context,
) {
  final grouped = <CapabilityGroup, List<Widget>>{};

  for (final cap in caps) {
    if (!cap.isVisible) continue;
    final widgets = cap.settingsWidgets(context);
    if (widgets.isEmpty) continue;
    grouped.putIfAbsent(cap.group, () => []).addAll(widgets);
  }

  // Remove utility (no settings representation) and state (popup-only for close/follow).
  grouped.remove(CapabilityGroup.utility);
  grouped.remove(CapabilityGroup.state);

  return [
    for (final entry in grouped.entries)
      SettingsSection(
        title: entry.key.displayName,
        icon: entry.key.icon,
        isDangerZone: entry.key == CapabilityGroup.danger,
        children: entry.value,
      ),
  ];
}

/// Builds batch action list from capabilities for [SelectionDockPill].
List<ActionButtonData> buildBatchFromCapabilities(
  List<EntityCapability> caps,
) {
  return [
    for (final cap in caps)
      if (cap.isVisible && cap.batchActions != null) ...cap.batchActions!,
  ];
}
