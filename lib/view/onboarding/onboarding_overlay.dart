import 'package:diohub/app/settings/appearance.dart';
import 'package:diohub/app/settings/diff_settings.dart';
import 'package:diohub/app/settings/theme_mode.dart';
import 'package:diohub/app/theme_config/models/flex_theme_settings_model.dart';
import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/common/const/app_info.dart';
import 'package:diohub/common/misc/contextual_preview.dart';
import 'package:diohub/common/misc/liquid_glass_wrapper.dart';
import 'package:diohub/common/misc/settings_dropdown.dart';
import 'package:diohub/common/misc/settings_group.dart';
import 'package:diohub/common/misc/settings_toggle.dart';
import 'package:diohub/common/overlay/modal_barrier_style.dart';
import 'package:diohub/providers/settings/appearance_provider.dart';
import 'package:diohub/providers/settings/diff_settings_provider.dart';
import 'package:diohub/providers/settings/flex_theme_provider.dart';
import 'package:diohub/providers/settings/onboarding_provider.dart';
import 'package:diohub/providers/settings/theme_mode_provider.dart';
import 'package:diohub/providers/haptic_service_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/view/onboarding/widgets/appearance_context_preview.dart';
import 'package:diohub/view/onboarding/widgets/onboarding_home_preview.dart';
import 'package:diohub/view/onboarding/widgets/onboarding_section.dart';
import 'package:diohub/view/onboarding/widgets/onboarding_toolbar_preview.dart';
import 'package:diohub/view/onboarding/widgets/theme_context_preview.dart';
import 'package:diohub/view/settings/widgets/font_family_setting_card.dart';
import 'package:diohub/view/settings/widgets/theme_config/scheme_chip.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows the onboarding flow as a liquid-glass overlay. 3 steps: look, surface & motion, summary.
Future<void> showOnboardingOverlay(final BuildContext context) async {
  if (!context.mounted) return;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: modalBarrierColor(context),
    transitionDuration: kStateDuration,
    transitionBuilder: (final BuildContext context,
            final Animation<double> animation,
            final Animation<double> secondaryAnimation,
            final Widget child) =>
        FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: kStateCurve),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.95, end: 1).animate(
          CurvedAnimation(parent: animation, curve: kStateCurve),
        ),
        child: child,
      ),
    ),
    pageBuilder: (final BuildContext context, final Animation<double> animation,
            final Animation<double> secondaryAnimation) =>
        const _OnboardingOverlayContent(),
  );
}

const List<FlexScheme> _onboardingSchemes = <FlexScheme>[
  FlexScheme.blueM3,
  FlexScheme.greenM3,
  FlexScheme.purpleM3,
  FlexScheme.redM3,
  FlexScheme.tealM3,
];

List<FlexScheme> _schemesForChips(final FlexScheme currentScheme) {
  if (_onboardingSchemes.contains(currentScheme)) return _onboardingSchemes;
  return <FlexScheme>[currentScheme, ..._onboardingSchemes];
}

Future<void> _updateScheme(
  final WidgetRef ref,
  final BuildContext context,
  final FlexScheme scheme,
) async {
  await ref.read(flexThemeProvider.notifier).update(
        (final FlexThemeSettingsModel current) => current.copyWith(
          scheme: scheme,
          lightScheme: scheme,
          darkScheme: scheme,
        ),
      );
}

class _OnboardingOverlayContent extends ConsumerStatefulWidget {
  const _OnboardingOverlayContent();

  @override
  ConsumerState<_OnboardingOverlayContent> createState() =>
      _OnboardingOverlayContentState();
}

class _OnboardingOverlayContentState
    extends ConsumerState<_OnboardingOverlayContent> {
  late final PageController _pageController;
  int _currentPage = 0;
  static const int _pageCount = 3;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish({required final bool apply}) async {
    await ref
        .read(onboardingProvider.notifier)
        .update((final s) => s.copyWith(completed: true));
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  void _onNext() {
    ref.read(hapticServiceProvider).lightImpact();
    if (_currentPage < _pageCount - 1) {
      _pageController.nextPage(
        duration: kStateDuration,
        curve: kStateCurve,
      );
    } else {
      ref.read(hapticServiceProvider).mediumImpact();
      _finish(apply: true);
    }
  }

  void _onDone() {
    ref.read(hapticServiceProvider).mediumImpact();
    _finish(apply: true);
  }

  @override
  Widget build(final BuildContext context) {
    final ThemeSettings themeSettings = ref.watch(themeModeProvider);
    final FlexThemeSettingsModel flexModel = ref.watch(flexThemeProvider);
    final Brightness brightness = Theme.of(context).brightness;
    final bool isDark = brightness == Brightness.dark;
    final FlexScheme currentScheme = isDark
        ? (flexModel.darkScheme ?? flexModel.scheme ?? FlexScheme.blueM3)
        : (flexModel.lightScheme ?? flexModel.scheme ?? FlexScheme.blueM3);
    final AppearanceSettings appearance = ref.watch(appearanceProvider);
    final bool darkIsTrueBlack = flexModel.darkIsTrueBlack ?? false;
    final AppSpacing spacing = context.spacing;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.85;
    const double maxWidth = 420;

    return Center(
      child: Padding(
        padding: EdgeInsets.only(
          left: context.spacing.spaciousPadding.left,
          right: context.spacing.spaciousPadding.right,
          top: 0,
          bottom: 0,
        ),
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
            child: LiquidGlassWrapper(
              size: RadiusSize.large,
              surfaceRenderingOverride: SurfaceRendering.blur,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  spacing.screenPadding.left,
                  spacing.sectionSpacing,
                  spacing.screenPadding.right,
                  spacing.sectionSpacing,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const AppLogoWidget(size: 48),
                    SizedBox(height: spacing.itemSpacing),
                    Text(
                      'Welcome to DioHub',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: spacing.tightSpacing),
                    Text(
                      "Let's set things up. You can change everything later in Settings.",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: spacing.sectionSpacing),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pageCount,
                        (final int i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: AnimatedContainer(
                            duration: kMicroDuration,
                            width: _currentPage == i ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: _currentPage == i
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant.withValues(
                                      alpha: 0.4,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: spacing.sectionSpacing),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (final int i) =>
                            setState(() => _currentPage = i),
                        children: <Widget>[
                          _buildStep1(context, ref, themeSettings.themeMode,
                              currentScheme, darkIsTrueBlack),
                          _buildStep2(context, ref, appearance),
                          _buildStep3(context, ref),
                        ],
                      ),
                    ),
                    SizedBox(height: spacing.sectionSpacing),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          onPressed: () => _finish(apply: false),
                          child: const Text('Skip'),
                        ),
                        SizedBox(width: spacing.itemSpacing),
                        if (_currentPage < _pageCount - 1)
                          FilledButton(
                            onPressed: _onNext,
                            child: const Text('Next'),
                          )
                        else
                          FilledButton(
                            onPressed: _onDone,
                            child: const Text('Done'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1(
    final BuildContext context,
    final WidgetRef ref,
    final ThemeMode themeMode,
    final FlexScheme currentScheme,
    final bool darkIsTrueBlack,
  ) {
    return SingleChildScrollView(
      child: OnboardingSection(
        title: 'Choose your look',
        subtitle: 'Theme, scheme, and font',
        icon: Icons.palette_outlined,
        preview: const ThemeContextPreview(),
        children: <Widget>[
          SettingsGroup(
            children: <Widget>[
              SettingsDropdown<ThemeMode>(
                title: 'Theme mode',
                icon: Icons.brightness_auto,
                value: themeMode,
                options: <SettingsDropdownOption<ThemeMode>>[
                  SettingsDropdownOption<ThemeMode>(
                    value: ThemeMode.light,
                    label: 'Light',
                    subtitle: 'Bright interface',
                    icon: Icons.light_mode,
                  ),
                  SettingsDropdownOption<ThemeMode>(
                    value: ThemeMode.dark,
                    label: 'Dark',
                    subtitle: 'Easy on the eyes',
                    icon: Icons.dark_mode,
                  ),
                  SettingsDropdownOption<ThemeMode>(
                    value: ThemeMode.system,
                    label: 'System',
                    subtitle: 'Match your device',
                    icon: Icons.brightness_auto,
                  ),
                ],
                onChanged: (final ThemeMode v) => ref
                    .read(themeModeProvider.notifier)
                    .update((final s) => s.copyWith(themeMode: v)),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.spacing.cardContentPadding.left,
                  12,
                  context.spacing.cardContentPadding.right,
                  8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Color scheme',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    context.spacing.itemGap,
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: _schemesForChips(currentScheme)
                            .map(
                              (final FlexScheme scheme) => Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: SizedBox(
                                  width: 72,
                                  child: SchemeChip(
                                    scheme: scheme,
                                    isSelected: scheme == currentScheme,
                                    onTap: () =>
                                        _updateScheme(ref, context, scheme),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              SettingsToggle(
                title: 'True black',
                subtitle: 'Pure black for OLED screens (dark theme)',
                value: darkIsTrueBlack,
                icon: Icons.brightness_1,
                onChanged: (final bool v) {
                  ref.read(flexThemeProvider.notifier).update(
                        (final FlexThemeSettingsModel m) =>
                            m.copyWith(darkIsTrueBlack: v),
                      );
                },
              ),
              const FontFamilySettingCard(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(
    final BuildContext context,
    final WidgetRef ref,
    final AppearanceSettings appearance,
  ) {
    return SingleChildScrollView(
      child: OnboardingSection(
        title: 'Surface & motion',
        subtitle: 'Surface style and animations',
        icon: Icons.blur_on,
        preview: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const AppearanceContextPreview(),
            SizedBox(height: context.spacing.itemSpacing),
            const OnboardingToolbarPreview(),
          ],
        ),
        children: <Widget>[
          SettingsGroup(
            children: <Widget>[
              SettingsDropdown<SurfaceRendering>(
                title: 'Surface style',
                icon: Icons.blur_on,
                value: appearance.surfaceRendering,
                options: SurfaceRendering.values
                    .map(
                      (final SurfaceRendering v) =>
                          SettingsDropdownOption<SurfaceRendering>(
                        value: v,
                        label: v.name[0].toUpperCase() + v.name.substring(1),
                        subtitle: switch (v) {
                          SurfaceRendering.glass =>
                            'Depth and refraction, premium feel',
                          SurfaceRendering.blur =>
                            'Frosted effect, lighter on GPU',
                          SurfaceRendering.solid =>
                            'Best performance, no transparency',
                        },
                      ),
                    )
                    .toList(),
                onChanged: (final SurfaceRendering v) => ref
                    .read(appearanceProvider.notifier)
                    .update((final s) => s.copyWith(surfaceRendering: v)),
              ),
              SettingsDropdown<AppBarStyle>(
                title: 'App bar style',
                icon: Icons.web_asset_rounded,
                value: appearance.appBarStyle,
                options: AppBarStyle.values
                    .map(
                      (final AppBarStyle v) =>
                          SettingsDropdownOption<AppBarStyle>(
                        value: v,
                        label: v.name[0].toUpperCase() + v.name.substring(1),
                        subtitle: switch (v) {
                          AppBarStyle.floating =>
                            'Rounded pill with margin when collapsed',
                          AppBarStyle.attached =>
                            'Edge-to-edge, minimal radius when collapsed',
                        },
                      ),
                    )
                    .toList(),
                onChanged: (final AppBarStyle v) => ref
                    .read(appearanceProvider.notifier)
                    .update((final s) => s.copyWith(appBarStyle: v)),
              ),
              SettingsDropdown<AnimationPreset>(
                title: 'Animations',
                icon: Icons.animation,
                value: appearance.animationPreset,
                options: AnimationPreset.values
                    .map(
                      (final AnimationPreset v) =>
                          SettingsDropdownOption<AnimationPreset>(
                        value: v,
                        label: v.name[0].toUpperCase() + v.name.substring(1),
                        subtitle: switch (v) {
                          AnimationPreset.none => 'No animations',
                          AnimationPreset.reduced => 'Minimal motion',
                          AnimationPreset.normal => 'Balanced',
                          AnimationPreset.enhanced => 'Extra fluid',
                        },
                      ),
                    )
                    .toList(),
                onChanged: (final AnimationPreset v) => ref
                    .read(appearanceProvider.notifier)
                    .update((final s) => s.copyWith(animationPreset: v)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(final BuildContext context, final WidgetRef ref) {
    final DiffSettings diff = ref.watch(diffSettingsProvider);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final AppSpacing spacing = context.spacing;

    final Widget miniPreview = ContextualPreview(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const OnboardingHomePreview(
            toolbarBuilder: CollapsedPillPreview(),
          ),
          SizedBox(height: spacing.tightSpacing),
          Container(
            padding: spacing.cardContentPadding,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'void main() { print("Hello"); }',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontSize: (theme.textTheme.bodySmall?.fontSize ?? 12) *
                    diff.codeFontScale,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding:
                EdgeInsets.symmetric(horizontal: spacing.screenPadding.left),
            child: miniPreview,
          ),
          SizedBox(height: spacing.sectionSpacing),
          Icon(
            Icons.check_circle_rounded,
            size: 48,
            color: colorScheme.primary,
          ),
          SizedBox(height: spacing.itemSpacing),
          Text(
            "You're ready to go",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacing.tightSpacing),
          Padding(
            padding:
                EdgeInsets.symmetric(horizontal: spacing.screenPadding.left),
            child: Text(
              'You can fine-tune all of these and more in Settings — including diff styling, haptic feedback, and advanced theme options.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
