import 'package:diohub/app/theme_config/models/flex_theme_settings_model.dart';
import 'package:diohub/providers/settings/flex_theme_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/view/settings/widgets/theme_config/enum_setting_widget.dart';
import 'package:diohub/view/settings/widgets/theme_config/section_header_widget.dart';
import 'package:diohub/view/settings/widgets/theme_config/slider_setting_widget.dart';
import 'package:diohub/view/settings/widgets/theme_config/switch_setting_widget.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Advanced theme options: variant, used colors, swap, surface mode, reset.
/// Shown inside the Theme section's expandable Advanced block.
class ThemeAdvancedSection extends ConsumerWidget {
  const ThemeAdvancedSection({super.key});

  static String _variantLabel(final FlexSchemeVariant v) => v.name
      .replaceAllMapped(
        RegExp(r'([A-Z])'),
        (final Match match) => ' ${match.group(1)}',
      )
      .trim();

  static String _surfaceModeLabel(final FlexSurfaceMode m) => m.name
      .replaceAllMapped(
        RegExp(r'([A-Z])'),
        (final Match match) => ' ${match.group(1)}',
      )
      .trim();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final FlexThemeSettingsModel model = ref.watch(flexThemeProvider);
    final AppSpacing spacing = context.spacing;

    void update(
      final FlexThemeSettingsModel Function(FlexThemeSettingsModel) updater,
    ) {
      ref.read(flexThemeProvider.notifier).update(updater);
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        spacing.screenPadding.left,
        8,
        spacing.screenPadding.right,
        spacing.sectionSpacing,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SectionHeaderWidget(
            title: 'Variant',
            subtitle: 'Color scheme variant style',
            icon: Icons.auto_awesome,
          ),
          EnumSettingWidget<FlexSchemeVariant>(
            title: 'Variant',
            description: 'Color scheme variant',
            value: model.variant ?? FlexSchemeVariant.values.first,
            options: FlexSchemeVariant.values,
            labelBuilder: _variantLabel,
            icon: Icons.auto_awesome,
            onChanged: (final FlexSchemeVariant v) => update(
                (final FlexThemeSettingsModel m) => m.copyWith(variant: v)),
          ),
          context.spacing.contentGap,
          SliderSettingWidget(
            title: 'Used colors',
            description: 'Number of colors to use (1-7)',
            value: (model.usedColors ?? 3).toDouble(),
            min: 1,
            max: 7,
            divisions: 6,
            labelBuilder: (final double v) => v.toInt().toString(),
            icon: Icons.format_color_fill,
            onChanged: (final double v) => update(
                (final FlexThemeSettingsModel m) =>
                    m.copyWith(usedColors: v.toInt())),
          ),
          context.spacing.contentGap,
          const SectionHeaderWidget(
            title: 'Color swapping',
            subtitle: 'Swap primary and secondary',
            icon: Icons.swap_horiz,
          ),
          SwitchSettingWidget(
            title: 'Swap colors',
            description: 'Swap primary and secondary colors',
            value: model.swapColors ?? false,
            icon: Icons.swap_horiz,
            onChanged: (final bool v) => update(
                (final FlexThemeSettingsModel m) => m.copyWith(swapColors: v)),
          ),
          SwitchSettingWidget(
            title: 'Swap legacy colors',
            description: 'Swap legacy primary and secondary',
            value: model.swapLegacyColors ?? false,
            icon: Icons.swap_vert,
            onChanged: (final bool v) => update(
                (final FlexThemeSettingsModel m) =>
                    m.copyWith(swapLegacyColors: v)),
          ),
          context.spacing.contentGap,
          const SectionHeaderWidget(
            title: 'Surface mode',
            subtitle: 'Surface color generation',
            icon: Icons.layers,
          ),
          EnumSettingWidget<FlexSurfaceMode>(
            title: 'Surface mode',
            description: 'How surface colors are generated',
            value: model.surfaceMode ?? FlexSurfaceMode.level,
            options: FlexSurfaceMode.values,
            labelBuilder: _surfaceModeLabel,
            icon: Icons.view_in_ar,
            onChanged: (final FlexSurfaceMode v) => update(
                (final FlexThemeSettingsModel m) => m.copyWith(surfaceMode: v)),
          ),
        ],
      ),
    );
  }
}
