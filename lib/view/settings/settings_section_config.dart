import 'package:flutter/material.dart';

/// Generic section entry for any settings tab.
class SettingsSectionEntry<T extends Enum> {
  const SettingsSectionEntry(this.id, this.title, {this.icon});

  final T id;
  final String title;
  final IconData? icon;
}

/// Stable section identifiers for the Themes tab.
enum ThemesSectionId {
  colorMode,
  surfaceGlass,
  appBar,
  motion,
  typography,
  advancedTheme,
  resetTheme,
}

/// Ordered list of navigable sections for the Themes tab TOC.
const List<SettingsSectionEntry<ThemesSectionId>> themesSectionToc = [
  SettingsSectionEntry(
    ThemesSectionId.colorMode,
    'Color & Mode',
    icon: Icons.palette,
  ),
  SettingsSectionEntry(
    ThemesSectionId.surfaceGlass,
    'Surface & Glass',
    icon: Icons.blur_on,
  ),
  SettingsSectionEntry(
    ThemesSectionId.appBar,
    'App Bar',
    icon: Icons.web_asset,
  ),
  SettingsSectionEntry(ThemesSectionId.motion, 'Motion', icon: Icons.animation),
  SettingsSectionEntry(
    ThemesSectionId.typography,
    'Typography',
    icon: Icons.text_fields,
  ),
  SettingsSectionEntry(
    ThemesSectionId.advancedTheme,
    'Advanced',
    icon: Icons.tune,
  ),
  SettingsSectionEntry(
    ThemesSectionId.resetTheme,
    'Reset',
    icon: Icons.restore,
  ),
];

/// Stable section identifiers for the Preferences tab.
enum PreferencesSectionId {
  layoutDensity,
  cardDisplay,
  defaults,
  resetPreferences,
}

/// Ordered list of navigable sections for the Preferences tab TOC.
const List<SettingsSectionEntry<PreferencesSectionId>> preferencesSectionToc = [
  SettingsSectionEntry(
    PreferencesSectionId.layoutDensity,
    'Layout & Density',
    icon: Icons.dashboard,
  ),
  SettingsSectionEntry(
    PreferencesSectionId.cardDisplay,
    'Card Display',
    icon: Icons.note,
  ),
  SettingsSectionEntry(
    PreferencesSectionId.defaults,
    'Defaults',
    icon: Icons.tune,
  ),
  SettingsSectionEntry(
    PreferencesSectionId.resetPreferences,
    'Reset Preferences',
    icon: Icons.restore,
  ),
];

/// Stable section identifiers for the Code & Diffs tab.
enum CodeSectionId { diffCode, codeBrowser }

/// Ordered list of navigable sections for the Code & Diffs tab TOC.
const List<SettingsSectionEntry<CodeSectionId>> codeSectionToc = [
  SettingsSectionEntry(CodeSectionId.diffCode, 'Diff & Code', icon: Icons.code),
  SettingsSectionEntry(
    CodeSectionId.codeBrowser,
    'Code Browser',
    icon: Icons.folder_open,
  ),
];

/// Stable section identifiers for the Behavior tab.
enum BehaviorSectionId {
  notifications,
  navigationLinks,
  events,
  integrations,
  privacyDiagnostics,
  about,
}

/// Ordered list of navigable sections for the Behavior tab TOC.
const List<SettingsSectionEntry<BehaviorSectionId>> behaviorSectionToc = [
  SettingsSectionEntry(
    BehaviorSectionId.notifications,
    'Notifications',
    icon: Icons.notifications_outlined,
  ),
  SettingsSectionEntry(
    BehaviorSectionId.navigationLinks,
    'Navigation & Links',
    icon: Icons.touch_app,
  ),
  SettingsSectionEntry(
    BehaviorSectionId.events,
    'Events',
    icon: Icons.timeline,
  ),
  SettingsSectionEntry(
    BehaviorSectionId.integrations,
    'Integrations',
    icon: Icons.extension,
  ),
  SettingsSectionEntry(
    BehaviorSectionId.privacyDiagnostics,
    'Privacy & Diagnostics',
    icon: Icons.privacy_tip_outlined,
  ),
  SettingsSectionEntry(
    BehaviorSectionId.about,
    'About',
    icon: Icons.info_outline,
  ),
];

/// Stable section identifiers for the DioLens & AI tab.
enum AiSectionId {
  aiModels,
  customEndpoints,
  conversation,
  contextManagement,
  mcpServers,
}

/// Ordered list of navigable sections for the DioLens & AI tab TOC.
const List<SettingsSectionEntry<AiSectionId>> aiSectionToc = [
  SettingsSectionEntry(
    AiSectionId.aiModels,
    'AI Models',
    icon: Icons.smart_toy_outlined,
  ),
  SettingsSectionEntry(
    AiSectionId.customEndpoints,
    'Custom Endpoints',
    icon: Icons.api,
  ),
  SettingsSectionEntry(
    AiSectionId.conversation,
    'Conversation',
    icon: Icons.chat_outlined,
  ),
  SettingsSectionEntry(
    AiSectionId.contextManagement,
    'Context Management',
    icon: Icons.inventory_2_outlined,
  ),
  SettingsSectionEntry(
    AiSectionId.mcpServers,
    'MCP Servers',
    icon: Icons.extension,
  ),
];
