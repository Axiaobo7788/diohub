import 'dart:async';

import 'package:diohub/app/settings/accessibility.dart';
import 'package:diohub/app/settings/appearance.dart';
import 'package:diohub/app/settings/events.dart';
import 'package:diohub/app/settings/layout.dart';
import 'package:diohub/app/settings/locale_settings.dart';
import 'package:diohub/app/settings/theme_mode.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/l10n/language_picker.dart';
import 'package:diohub/providers/settings/accessibility_provider.dart';
import 'package:diohub/providers/settings/appearance_provider.dart';
import 'package:diohub/providers/settings/events_provider.dart';
import 'package:diohub/providers/settings/layout_provider.dart';
import 'package:diohub/providers/settings/locale_provider.dart';
import 'package:diohub/providers/settings/theme_mode_provider.dart';
import 'package:diohub/view/settings/md3/settings_md3_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsGeneralPage extends ConsumerWidget {
  const SettingsGeneralPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final LocaleSettings locale = ref.watch(localeProvider);
    final LayoutSettings layout = ref.watch(layoutProvider);
    final EventsSettings events = ref.watch(eventsProvider);
    final AppearanceSettings appearance = ref.watch(appearanceProvider);

    return Column(
      key: const ValueKey<String>('settings-general-page'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SettingsPageHeading(
          title: context.l10n.settingsGeneral,
          description: context.l10n.settingsGeneralDescription,
        ),
        Md3SettingsSection(
          title: context.l10n.languageAndRegion,
          children: <Widget>[
            SettingsChoiceRow<AppLanguage>(
              title: context.l10n.settingsAppLanguage,
              subtitle: context.l10n.settingsAppLanguageDescription,
              value: locale.language,
              values: AppLanguage.values,
              labelBuilder: (final AppLanguage value) =>
                  appLanguageLabel(context, value),
              onSelected: (final AppLanguage value) => unawaited(
                runSettingsUpdate(
                  context,
                  ref.read(localeProvider.notifier).setLanguage(value),
                ),
              ),
            ),
          ],
        ),
        Md3SettingsSection(
          title: context.l10n.settingsLayout,
          description: context.l10n.settingsLayoutDescription,
          children: <Widget>[
            SettingsChoiceRow<LayoutDensity>(
              title: context.l10n.settingsDensity,
              subtitle: context.l10n.settingsDensityDescription,
              value: layout.density,
              values: LayoutDensity.values,
              labelBuilder: (final LayoutDensity value) =>
                  _densityLabel(context, value),
              onSelected: (final LayoutDensity value) => unawaited(
                runSettingsUpdate(
                  context,
                  ref.read(layoutProvider.notifier).updateDensity(value),
                ),
              ),
            ),
            SettingsSwitchRow(
              title: context.l10n.settingsStickyHeaders,
              subtitle: context.l10n.settingsStickyHeadersDescription,
              value: layout.stickyHeaders,
              onChanged: (final bool value) => unawaited(
                runSettingsUpdate(
                  context,
                  ref.read(layoutProvider.notifier).updateStickyHeaders(value),
                ),
              ),
            ),
          ],
        ),
        Md3SettingsSection(
          title: context.l10n.settingsFeedAndSearch,
          children: <Widget>[
            SettingsSwitchRow(
              title: context.l10n.settingsGroupRelatedActivity,
              subtitle: context.l10n.settingsGroupRelatedActivityDescription,
              value: events.compoundActions,
              onChanged: (final bool value) => unawaited(
                runSettingsUpdate(
                  context,
                  ref
                      .read(eventsProvider.notifier)
                      .update(
                        (final EventsSettings current) =>
                            current.copyWith(compoundActions: value),
                      ),
                ),
              ),
            ),
            SettingsSwitchRow(
              title: context.l10n.settingsTimelineFeed,
              subtitle: context.l10n.settingsTimelineFeedDescription,
              value: events.useTimelineView,
              onChanged: (final bool value) => unawaited(
                runSettingsUpdate(
                  context,
                  ref
                      .read(eventsProvider.notifier)
                      .update(
                        (final EventsSettings current) =>
                            current.copyWith(useTimelineView: value),
                      ),
                ),
              ),
            ),
            SettingsSwitchRow(
              title: context.l10n.settingsFuzzySearch,
              subtitle: context.l10n.settingsFuzzySearchDescription,
              value: appearance.fuzzyFiltering,
              onChanged: (final bool value) => unawaited(
                runSettingsUpdate(
                  context,
                  ref
                      .read(appearanceProvider.notifier)
                      .update(
                        (final AppearanceSettings current) =>
                            current.copyWith(fuzzyFiltering: value),
                      ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _densityLabel(
    final BuildContext context,
    final LayoutDensity density,
  ) => switch (density) {
    LayoutDensity.compact => context.l10n.settingsDensityCompact,
    LayoutDensity.default_ => context.l10n.settingsDensityDefault,
    LayoutDensity.spacious => context.l10n.settingsDensitySpacious,
  };
}

class SettingsAppearancePage extends ConsumerWidget {
  const SettingsAppearancePage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeSettings theme = ref.watch(themeModeProvider);

    return Column(
      key: const ValueKey<String>('settings-appearance-page'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SettingsPageHeading(
          title: context.l10n.settingsAppearance,
          description: context.l10n.settingsAppearanceDescription,
        ),
        Md3SettingsSection(
          title: context.l10n.settingsTheme,
          description: context.l10n.settingsThemeDescription,
          children: <Widget>[
            SettingsChoiceRow<ThemeMode>(
              title: context.l10n.settingsThemeMode,
              subtitle: context.l10n.settingsThemeModeDescription,
              value: theme.themeMode,
              values: ThemeMode.values,
              labelBuilder: (final ThemeMode value) =>
                  _themeModeLabel(context, value),
              onSelected: (final ThemeMode value) => unawaited(
                runSettingsUpdate(
                  context,
                  ref
                      .read(themeModeProvider.notifier)
                      .update(
                        (final ThemeSettings current) =>
                            current.copyWith(themeMode: value),
                      ),
                ),
              ),
            ),
            SettingsSwitchRow(
              title: context.l10n.settingsMaterialYou,
              subtitle: context.l10n.settingsMaterialYouDescription,
              value: theme.materialYouEnabled,
              onChanged: (final bool value) => unawaited(
                runSettingsUpdate(
                  context,
                  ref
                      .read(themeModeProvider.notifier)
                      .update(
                        (final ThemeSettings current) =>
                            current.copyWith(materialYouEnabled: value),
                      ),
                ),
              ),
            ),
          ],
        ),
        Md3SettingsSection(
          title: context.l10n.settingsProfileColors,
          description: context.l10n.settingsProfileColorsDescription,
          children: <Widget>[
            SettingsSwitchRow(
              title: context.l10n.settingsProfileTheme,
              subtitle: context.l10n.settingsProfileThemeDescription,
              value: theme.scopedProfileThemeEnabled,
              onChanged: (final bool value) => unawaited(
                runSettingsUpdate(
                  context,
                  ref
                      .read(themeModeProvider.notifier)
                      .updateScopedTheme(enabled: value),
                ),
              ),
            ),
            if (theme.scopedProfileThemeEnabled)
              SettingsSliderRow(
                title: context.l10n.settingsProfileThemeIntensity,
                subtitle: context.l10n.settingsProfileThemeIntensityDescription,
                value: theme.scopedThemeIntensity,
                min: 0,
                max: 1,
                divisions: 10,
                valueLabelBuilder: (final double value) =>
                    '${(value * 100).round()}%',
                onChanged: (final double value) => unawaited(
                  runSettingsUpdate(
                    context,
                    ref
                        .read(themeModeProvider.notifier)
                        .updateScopedTheme(intensity: value),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _themeModeLabel(
    final BuildContext context,
    final ThemeMode themeMode,
  ) => switch (themeMode) {
    ThemeMode.system => context.l10n.settingsThemeSystem,
    ThemeMode.light => context.l10n.settingsThemeLight,
    ThemeMode.dark => context.l10n.settingsThemeDark,
  };
}

class SettingsAccessibilityPage extends ConsumerWidget {
  const SettingsAccessibilityPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AppearanceSettings appearance = ref.watch(appearanceProvider);
    final AccessibilitySettings accessibility = ref.watch(
      accessibilityProvider,
    );

    return Column(
      key: const ValueKey<String>('settings-accessibility-page'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SettingsPageHeading(
          title: context.l10n.settingsAccessibility,
          description: context.l10n.settingsAccessibilityDescription,
        ),
        Md3SettingsSection(
          title: context.l10n.settingsMotion,
          description: context.l10n.settingsMotionDescription,
          children: <Widget>[
            SettingsChoiceRow<AnimationPreset>(
              title: context.l10n.settingsAnimationLevel,
              subtitle: context.l10n.settingsAnimationLevelDescription,
              value: appearance.animationPreset,
              values: AnimationPreset.values,
              labelBuilder: (final AnimationPreset value) =>
                  _animationLabel(context, value),
              onSelected: (final AnimationPreset value) => unawaited(
                runSettingsUpdate(
                  context,
                  ref
                      .read(appearanceProvider.notifier)
                      .update(
                        (final AppearanceSettings current) =>
                            current.copyWith(animationPreset: value),
                      ),
                ),
              ),
            ),
          ],
        ),
        Md3SettingsSection(
          title: context.l10n.settingsFeedback,
          children: <Widget>[
            SettingsChoiceRow<HapticFeedbackLevel>(
              title: context.l10n.settingsHaptics,
              subtitle: context.l10n.settingsHapticsDescription,
              value: accessibility.hapticFeedback,
              values: HapticFeedbackLevel.values,
              labelBuilder: (final HapticFeedbackLevel value) =>
                  _hapticsLabel(context, value),
              onSelected: (final HapticFeedbackLevel value) => unawaited(
                runSettingsUpdate(
                  context,
                  ref
                      .read(accessibilityProvider.notifier)
                      .update(
                        (final AccessibilitySettings current) =>
                            current.copyWith(hapticFeedback: value),
                      ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _animationLabel(
    final BuildContext context,
    final AnimationPreset preset,
  ) => switch (preset) {
    AnimationPreset.none => context.l10n.settingsAnimationNone,
    AnimationPreset.reduced => context.l10n.settingsAnimationReduced,
    AnimationPreset.normal => context.l10n.settingsAnimationNormal,
    AnimationPreset.enhanced => context.l10n.settingsAnimationEnhanced,
  };

  String _hapticsLabel(
    final BuildContext context,
    final HapticFeedbackLevel level,
  ) => switch (level) {
    HapticFeedbackLevel.on => context.l10n.settingsHapticsOn,
    HapticFeedbackLevel.reduced => context.l10n.settingsHapticsReduced,
    HapticFeedbackLevel.off => context.l10n.settingsHapticsOff,
  };
}
