import 'package:diohub/app/settings/appearance.dart';
import 'package:diohub/app/settings/glass_pill.dart';
import 'package:diohub/app/settings/theme_mode.dart';
import 'package:diohub/common/bottom_sheet/confirm_action_sheet.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/common/misc/contextual_preview.dart';
import 'package:diohub/common/misc/expandable_settings_section.dart';
import 'package:diohub/common/misc/settings_dropdown.dart';
import 'package:diohub/common/misc/settings_group.dart';
import 'package:diohub/common/misc/settings_nest.dart';
import 'package:diohub/common/misc/settings_slider.dart';
import 'package:diohub/common/misc/settings_toggle.dart';
import 'package:diohub/common/widgets/section_toc_button.dart';
import 'package:diohub/common/wrappers/sticky_glass_header.dart';
import 'package:diohub/providers/settings/appearance_provider.dart';
import 'package:diohub/providers/settings/glass_pill_provider.dart';
import 'package:diohub/app/theme_config/models/flex_theme_settings_model.dart';
import 'package:diohub/providers/settings/flex_theme_provider.dart';
import 'package:diohub/providers/settings/diff_settings_provider.dart';
import 'package:diohub/providers/settings/theme_mode_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/material_you_support.dart';
import 'package:diohub/view/settings/settings_section_config.dart';
import 'package:diohub/view/settings/widgets/previews/app_bar_preview.dart';
import 'package:diohub/view/settings/widgets/previews/color_mode_preview.dart';
import 'package:diohub/view/settings/widgets/previews/surface_glass_preview.dart';
import 'package:diohub/view/settings/widgets/previews/typography_preview.dart';
import 'package:diohub/view/settings/widgets/scheme_carousel.dart';
import 'package:diohub/view/settings/widgets/surface_slider_group.dart';
import 'package:diohub/view/settings/widgets/theme_config/enum_setting_widget.dart';
import 'package:diohub/view/settings/widgets/theme_config/section_header_widget.dart';
import 'package:diohub/view/settings/widgets/theme_config/theme_advanced_section.dart';
import 'package:diohub/view/settings/widgets/font_family_setting_card.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// Sliver form of themes sections for use inside the shell's scroll view.
/// Use [ThemesTab] for a full-screen scroll view (e.g. standalone route).
class ThemesTabSlivers extends ConsumerStatefulWidget {
  const ThemesTabSlivers({super.key});

  @override
  ConsumerState<ThemesTabSlivers> createState() => _ThemesTabSliversState();
}

class _ThemesTabSliversState extends ConsumerState<ThemesTabSlivers> {
  late final Map<ThemesSectionId, GlobalKey<State<StatefulWidget>>>
      _sectionKeys;

  @override
  void initState() {
    super.initState();
    _sectionKeys = <ThemesSectionId, GlobalKey<State<StatefulWidget>>>{
      for (final ThemesSectionId id in ThemesSectionId.values) id: GlobalKey(),
    };
  }

  void _scrollToSection(final ThemesSectionId id) {
    final BuildContext? ctx = _sectionKeys[id]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  static Widget _buildSectionContent(final ThemesSectionId id) {
    switch (id) {
      case ThemesSectionId.colorMode:
        return _ColorModeSectionContent();
      case ThemesSectionId.surfaceGlass:
        return _SurfaceGlassSectionContent();
      case ThemesSectionId.appBar:
        return _AppBarSectionContent();
      case ThemesSectionId.motion:
        return _MotionSectionContent();
      case ThemesSectionId.typography:
        return _TypographySectionContent();
      case ThemesSectionId.advancedTheme:
        return _AdvancedThemeSectionContent();
      case ThemesSectionId.resetTheme:
        return _ResetThemeSectionContent();
    }
  }

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;

    final List<SectionTocEntry> tocEntries = themesSectionToc
        .map(
          (final SettingsSectionEntry<ThemesSectionId> e) => SectionTocEntry(
            id: e.id.name,
            title: e.title,
            icon: e.icon,
          ),
        )
        .toList();
    final SectionTocButton? tocButton = tocEntries.isNotEmpty
        ? SectionTocButton(
            entries: tocEntries,
            onSelect: (final String sectionId) {
              final ThemesSectionId sid =
                  ThemesSectionId.values.byName(sectionId);
              _scrollToSection(sid);
            },
          )
        : null;

    final List<Widget> sectionSlivers = <Widget>[];

    for (final SettingsSectionEntry<ThemesSectionId> entry in themesSectionToc) {
      final GlobalKey<State<StatefulWidget>>? key = _sectionKeys[entry.id];
      final Widget sectionContent = KeyedSubtree(
        key: key,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            spacing.screenPadding.left,
            0,
            spacing.screenPadding.right,
            spacing.sectionSpacing,
          ),
          child: _buildSectionContent(entry.id),
        ),
      );

      sectionSlivers.add(
        StickyGlassSection.withTitle(
          title: entry.title,
          icon: entry.icon,
          trailing: entry.id == ThemesSectionId.colorMode ? tocButton : null,
          sliver: SliverToBoxAdapter(child: sectionContent),
        ),
      );
    }

    return SliverPadding(
      padding: context.spacing.listInset,
      sliver: MultiSliver(children: sectionSlivers),
    );
  }
}

/// Themes tab: Color & Mode, Surface & Glass, App Bar, Motion, Typography,
/// Advanced, Reset. Uses sticky section headers when enabled.
/// For use inside NavCenter use [ThemesTabSlivers] via [SliverBuilderBody].
class ThemesTab extends ConsumerStatefulWidget {
  const ThemesTab({super.key});

  @override
  ConsumerState<ThemesTab> createState() => _ThemesTabState();
}

class _ThemesTabState extends ConsumerState<ThemesTab> {
  @override
  Widget build(final BuildContext context) => MultiSliver(
        children: const <Widget>[ThemesTabSlivers()],
      );
}

// --- Section content widgets ---

class _ColorModeSectionContent extends ConsumerWidget {
  const _ColorModeSectionContent();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeSettings themeSettings = ref.watch(themeModeProvider);
    final FlexThemeSettingsModel flex = ref.watch(flexThemeProvider);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final AppSpacing spacing = context.spacing;
    final int blendLevel = flex.blendLevel ?? 10;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              'Theme mode',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            context.spacing.contentGap,
            Expanded(
              child: SegmentedButton<ThemeMode>(
                segments: const <ButtonSegment<ThemeMode>>[
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode, size: 18),
                    label: Text('Light'),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode, size: 18),
                    label: Text('Dark'),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto, size: 18),
                    label: Text('Auto'),
                  ),
                ],
                selected: <ThemeMode>{themeSettings.themeMode},
                onSelectionChanged: (final Set<ThemeMode> selected) {
                  ref.read(themeModeProvider.notifier).update(
                      (final s) => s.copyWith(themeMode: selected.first));
                },
              ),
            ),
          ],
        ),
        DynamicColorBuilder(
          builder: (final ColorScheme? lightDynamic,
              final ColorScheme? darkDynamic) {
            final bool supportsMaterialYou =
                MaterialYouSupport.isSupported(lightDynamic, darkDynamic);
            return BorderedContainer(
              elevation: 0,
              size: RadiusSize.medium,
              borderColor: colorScheme.outline.tint,
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                title: Text(
                  'Material You',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  !supportsMaterialYou
                      ? 'Not supported on this device'
                      : themeSettings.materialYouEnabled
                          ? 'Using system theme'
                          : 'Using custom theme presets',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                value: themeSettings.materialYouEnabled,
                onChanged: supportsMaterialYou
                    ? (final bool value) {
                        ref.read(themeModeProvider.notifier).update(
                            (final s) => s.copyWith(materialYouEnabled: value));
                      }
                    : null,
              ),
            );
          },
        ),
        SizedBox(height: spacing.itemSpacing),
        SettingsToggle(
          title: 'Profile Theming',
          value: themeSettings.scopedProfileThemeEnabled,
          onChanged: (final bool value) {
            ref.read(themeModeProvider.notifier).update(
                (final s) => s.copyWith(scopedProfileThemeEnabled: value));
          },
          icon: Icons.person,
          subtitle: 'Tint UI with profile accent colors',
        ),
        if (themeSettings.scopedProfileThemeEnabled) ...<Widget>[
          SizedBox(height: spacing.itemSpacing),
          SettingsSlider(
            title: 'Intensity',
            value: themeSettings.scopedThemeIntensity,
            min: 0.05,
            max: 1.0,
            divisions: 19,
            onChanged: (final double v) {
              ref
                  .read(themeModeProvider.notifier)
                  .update((final s) => s.copyWith(scopedThemeIntensity: v));
            },
            labelBuilder: (final double v) => v <= 0.2
                ? 'Subtle'
                : (v >= 0.8 ? 'Vivid' : v.toStringAsFixed(2)),
          ),
        ],
        SizedBox(height: spacing.itemSpacing),
        SwitchListTile(
          title: const Text('True black (dark theme)'),
          subtitle: const Text(
            'Use pure black in dark theme. Can save power on OLED.',
          ),
          value: flex.darkIsTrueBlack ?? false,
          onChanged: (final bool value) async {
            await ref.read(flexThemeProvider.notifier).update(
                  (final FlexThemeSettingsModel m) =>
                      m.copyWith(darkIsTrueBlack: value),
                );
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'Blend level',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.itemSpacing, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$blendLevel',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: blendLevel.toDouble(),
            max: 40,
            divisions: 40,
            onChanged: (final double value) {
              ref.read(flexThemeProvider.notifier).update(
                    (final FlexThemeSettingsModel current) =>
                        current.copyWith(blendLevel: value.toInt()),
                  );
            },
          ),
        ),
        const SchemeCarousel(),
        SizedBox(height: spacing.itemSpacing),
        ContextualPreview(child: const ColorModePreview()),
      ],
    );
  }
}

class _SurfaceGlassSectionContent extends ConsumerWidget {
  const _SurfaceGlassSectionContent();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AppearanceSettings appearance = ref.watch(appearanceProvider);
    final GlassPillSettings glassPillSettings = ref.watch(glassPillProvider);
    final AppSpacing spacing = context.spacing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SettingsDropdown<SurfaceRendering>(
          title: 'Surface style',
          value: appearance.surfaceRendering,
          options: SurfaceRendering.values
              .map(
                (final SurfaceRendering v) =>
                    SettingsDropdownOption<SurfaceRendering>(
                  value: v,
                  label: v.name[0].toUpperCase() + v.name.substring(1),
                ),
              )
              .toList(),
          onChanged: (final SurfaceRendering v) => ref
              .read(appearanceProvider.notifier)
              .update((final s) => s.copyWith(surfaceRendering: v)),
        ),
        ContextualPreview(child: const SurfaceGlassPreview()),
        SizedBox(height: spacing.itemSpacing),
        SurfaceSliderGroup(
          scope: SurfaceScope.global,
          surfaceRendering: appearance.surfaceRendering,
        ),
        SizedBox(height: spacing.sectionSpacing),
        const SectionHeaderWidget(
          title: 'Glass Pills',
          subtitle: 'Spacing and corner rounding for glass pill surfaces',
          icon: Icons.rounded_corner,
        ),
        EnumSettingWidget<PillDensity>(
          title: 'Pill density',
          description: 'Controls spacing inside glass pill surfaces',
          value: glassPillSettings.density,
          options: PillDensity.values,
          labelBuilder: (final PillDensity d) => switch (d) {
            PillDensity.compact => 'Compact',
            PillDensity.default_ => 'Default',
            PillDensity.spacious => 'Spacious',
          },
          onChanged: (final PillDensity d) => ref
              .read(glassPillProvider.notifier)
              .update((final s) => s.copyWith(density: d)),
        ),
        SizedBox(height: spacing.itemSpacing),
        EnumSettingWidget<RadiusScale>(
          title: 'Corner rounding',
          description: 'Controls how rounded glass pill corners are',
          value: glassPillSettings.radiusScale,
          options: RadiusScale.values,
          labelBuilder: (final RadiusScale s) => switch (s) {
            RadiusScale.tight => 'Tight',
            RadiusScale.default_ => 'Default',
            RadiusScale.roomy => 'Roomy',
          },
          onChanged: (final RadiusScale s) => ref
              .read(glassPillProvider.notifier)
              .update((final g) => g.copyWith(radiusScale: s)),
        ),
      ],
    );
  }
}

class _AppBarSectionContent extends ConsumerWidget {
  const _AppBarSectionContent();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AppearanceSettings appearance = ref.watch(appearanceProvider);
    final AppSpacing spacing = context.spacing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SettingsDropdown<AppBarStyle>(
          title: 'App bar style',
          value: appearance.appBarStyle,
          options: AppBarStyle.values
              .map(
                (final AppBarStyle v) => SettingsDropdownOption<AppBarStyle>(
                  value: v,
                  label: v.name[0].toUpperCase() + v.name.substring(1),
                ),
              )
              .toList(),
          onChanged: (final AppBarStyle v) => ref
              .read(appearanceProvider.notifier)
              .update((final s) => s.copyWith(appBarStyle: v)),
        ),
        ContextualPreview(child: const AppBarPreview()),
        SizedBox(height: spacing.itemSpacing),
        SettingsNest<SurfaceRendering>(
          title: 'App bar surface',
          value: appearance.appBarSurfaceRendering,
          options: SurfaceRendering.values
              .map(
                (final SurfaceRendering v) =>
                    SettingsDropdownOption<SurfaceRendering>(
                  value: v,
                  label: v.name[0].toUpperCase() + v.name.substring(1),
                ),
              )
              .toList(),
          onChanged: (final SurfaceRendering v) => ref
              .read(appearanceProvider.notifier)
              .update((final s) => s.copyWith(appBarSurfaceRendering: v)),
          children: <SurfaceRendering, Widget>{
            SurfaceRendering.glass: SurfaceSliderGroup(
              scope: SurfaceScope.appBar,
              surfaceRendering: SurfaceRendering.glass,
            ),
            SurfaceRendering.blur: SurfaceSliderGroup(
              scope: SurfaceScope.appBar,
              surfaceRendering: SurfaceRendering.blur,
            ),
            SurfaceRendering.solid: SurfaceSliderGroup(
              scope: SurfaceScope.appBar,
              surfaceRendering: SurfaceRendering.solid,
            ),
          },
        ),
        SettingsGroup(
          children: <Widget>[
            SettingsToggle(
              title: 'Toolbar minimize on scroll',
              value: appearance.toolbarMinimizeOnScroll,
              onChanged: (final bool v) => ref
                  .read(appearanceProvider.notifier)
                  .update((final s) => s.copyWith(toolbarMinimizeOnScroll: v)),
            ),
          ],
        ),
      ],
    );
  }
}

class _MotionSectionContent extends ConsumerWidget {
  const _MotionSectionContent();

  static String _label(final AnimationPreset p) => switch (p) {
        AnimationPreset.none => 'None',
        AnimationPreset.reduced => 'Reduced',
        AnimationPreset.normal => 'Normal',
        AnimationPreset.enhanced => 'Enhanced',
      };

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AppearanceSettings appearance = ref.watch(appearanceProvider);

    return SettingsGroup(
      children: <Widget>[
        SettingsDropdown<AnimationPreset>(
          title: 'Animation',
          value: appearance.animationPreset,
          options: AnimationPreset.values
              .map(
                (final AnimationPreset v) =>
                    SettingsDropdownOption<AnimationPreset>(
                  value: v,
                  label: _label(v),
                ),
              )
              .toList(),
          onChanged: (final AnimationPreset v) => ref
              .read(appearanceProvider.notifier)
              .update((final s) => s.copyWith(animationPreset: v)),
        ),
        SettingsToggle(
          title: 'Fuzzy filtering',
          subtitle:
              'Match list filters with typos (e.g. "fltr" matches "flutter")',
          value: appearance.fuzzyFiltering,
          onChanged: (final bool v) => ref
              .read(appearanceProvider.notifier)
              .update((final s) => s.copyWith(fuzzyFiltering: v)),
        ),
      ],
    );
  }
}

class _TypographySectionContent extends ConsumerWidget {
  const _TypographySectionContent();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final double codeFontScale = ref.watch(diffSettingsProvider).codeFontScale;
    final AppSpacing spacing = context.spacing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ContextualPreview(child: const TypographyPreview()),
        SizedBox(height: spacing.itemSpacing),
        const FontFamilySettingCard(),
        SizedBox(height: spacing.itemSpacing),
        SettingsGroup(
          children: <Widget>[
            SettingsSlider(
              title: 'Code font scale',
              value: codeFontScale,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              labelBuilder: (final double v) => v.toStringAsFixed(1),
              onChanged: (final double v) => ref
                  .read(diffSettingsProvider.notifier)
                  .update((final s) => s.copyWith(
                        codeFontScale: v.clamp(0.5, 2.0),
                      )),
            ),
          ],
        ),
      ],
    );
  }
}

class _AdvancedThemeSectionContent extends StatelessWidget {
  const _AdvancedThemeSectionContent();

  @override
  Widget build(final BuildContext context) => ExpandableSettingsSection(
        title: 'Advanced theme options',
        child: const ThemeAdvancedSection(),
      );
}

class _ResetThemeSectionContent extends ConsumerWidget {
  const _ResetThemeSectionContent();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AppSpacing spacing = context.spacing;

    return Padding(
      padding: spacing.sectionTitlePaddingLarge,
      child: OutlinedButton.icon(
        onPressed: () async {
          final bool? confirm = await showConfirmAction(
            context,
            title: 'Reset theme & appearance?',
            explanation: 'This will reset all color, surface, glass, app bar, '
                'animation, and font settings to defaults.',
            confirmLabel: 'Reset',
            isDestructive: true,
          );
          if (confirm == true && context.mounted) {
            await ref.read(flexThemeProvider.notifier).reset();
            await ref.read(themeModeProvider.notifier).reset();
            await ref.read(appearanceProvider.notifier).reset();
            if (context.mounted) {
              ref.read(notificationServiceProvider).success(
                    'Theme & appearance reset to defaults',
                  );
            }
          }
        },
        icon: const Icon(Icons.restore),
        label: const Text('Reset theme & appearance'),
      ),
    );
  }
}
