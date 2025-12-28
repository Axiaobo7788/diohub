import 'package:diohub/app/theme_settings/api/flex_theme_settings_service.dart';
import 'package:diohub/app/theme_settings/models/flex_theme_settings_model.dart';
import 'package:diohub/view/settings/widgets/theme_settings/color_setting_widget.dart';
import 'package:diohub/view/settings/widgets/theme_settings/enum_setting_widget.dart';
import 'package:diohub/view/settings/widgets/theme_settings/section_header_widget.dart';
import 'package:diohub/view/settings/widgets/theme_settings/slider_setting_widget.dart';
import 'package:diohub/view/settings/widgets/theme_settings/switch_setting_widget.dart';
import 'package:diohub/view/settings/widgets/theme_settings/text_setting_widget.dart';
import 'package:diohub/view/settings/widgets/theme_settings/theme_preview_widget.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Main widget for configuring FlexColorScheme theme settings
class ThemeSettingsWidget extends StatefulWidget {
  const ThemeSettingsWidget({super.key});

  @override
  State<ThemeSettingsWidget> createState() => _ThemeSettingsWidgetState();
}

class _ThemeSettingsWidgetState extends State<ThemeSettingsWidget> {
  late FlexThemeSettingsService _settingsService;

  @override
  void initState() {
    super.initState();
    _settingsService = FlexThemeSettingsService();
  }

  @override
  void dispose() {
    _settingsService.dispose();
    super.dispose();
  }

  Future<void> _updateSettings(
    FlexThemeSettingsModel Function(FlexThemeSettingsModel) updater,
  ) async {
    await _settingsService.update(updater(_settingsService.value));
  }

  String _getFlexSchemeLabel(FlexScheme scheme) {
    return scheme.name.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)}',
    ).trim();
  }

  String _getFlexSchemeVariantLabel(FlexSchemeVariant variant) {
    return variant.name.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)}',
    ).trim();
  }

  String _getFlexSurfaceModeLabel(FlexSurfaceMode mode) {
    return mode.name.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)}',
    ).trim();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FlexThemeSettingsService>.value(
      value: _settingsService,
      child: Consumer<FlexThemeSettingsService>(
        builder: (context, settings, child) {
          final FlexThemeSettingsModel model = settings.value;
          
          // Get current brightness from context
          final Brightness currentBrightness = MediaQuery.of(context).platformBrightness;

          return ListView(
            padding: const EdgeInsets.all(8),
            children: <Widget>[
              // Theme Preview Section
              const SectionHeaderWidget(
                title: 'Live Preview',
                subtitle: 'See how your theme looks',
                icon: Icons.preview,
              ),
              ThemePreviewWidget(
                settings: model,
                brightness: currentBrightness,
              ),
              const SizedBox(height: 16),

              // Color Scheme Selection
              const SectionHeaderWidget(
                title: 'Color Scheme',
                subtitle: 'Choose a predefined color scheme',
                icon: Icons.palette,
              ),
              EnumSettingWidget<FlexScheme>(
                title: 'Scheme',
                description: 'Predefined color scheme',
                value: model.scheme ?? FlexScheme.blueM3,
                options: FlexScheme.values,
                labelBuilder: _getFlexSchemeLabel,
                icon: Icons.color_lens,
                onChanged: (FlexScheme value) {
                  _updateSettings((m) => m.copyWith(scheme: value));
                },
              ),
              EnumSettingWidget<FlexSchemeVariant>(
                title: 'Variant',
                description: 'Color scheme variant style',
                value: model.variant ?? FlexSchemeVariant.values.first,
                options: FlexSchemeVariant.values,
                labelBuilder: _getFlexSchemeVariantLabel,
                icon: Icons.auto_awesome,
                onChanged: (FlexSchemeVariant value) {
                  _updateSettings((m) => m.copyWith(variant: value));
                },
              ),

              const Divider(),

              // Color Blending
              const SectionHeaderWidget(
                title: 'Color Blending',
                subtitle: 'Control how colors blend together',
                icon: Icons.blur_on,
              ),
              SliderSettingWidget(
                title: 'Blend Level',
                description: 'Amount of color blending (0-40)',
                value: (model.blendLevel ?? 0).toDouble(),
                min: 0,
                max: 40,
                divisions: 40,
                labelBuilder: (double value) => value.toInt().toString(),
                icon: Icons.tune,
                onChanged: (double value) {
                  _updateSettings((m) => m.copyWith(blendLevel: value.toInt()));
                },
              ),
              SliderSettingWidget(
                title: 'Used Colors',
                description: 'Number of colors to use (1-7)',
                value: (model.usedColors ?? 3).toDouble(),
                min: 1,
                max: 7,
                divisions: 6,
                labelBuilder: (double value) => value.toInt().toString(),
                icon: Icons.format_color_fill,
                onChanged: (double value) {
                  _updateSettings((m) => m.copyWith(usedColors: value.toInt()));
                },
              ),

              const Divider(),

              // Dark Theme Settings
              const SectionHeaderWidget(
                title: 'Dark Theme',
                subtitle: 'Dark theme specific options',
                icon: Icons.dark_mode,
              ),
              SwitchSettingWidget(
                title: 'True Black',
                description: 'Use true black instead of dark gray for dark theme',
                value: model.darkIsTrueBlack ?? false,
                icon: Icons.contrast,
                onChanged: (bool value) {
                  _updateSettings((m) => m.copyWith(darkIsTrueBlack: value));
                },
              ),

              const Divider(),

              // Color Swapping
              const SectionHeaderWidget(
                title: 'Color Swapping',
                subtitle: 'Swap primary and secondary colors',
                icon: Icons.swap_horiz,
              ),
              SwitchSettingWidget(
                title: 'Swap Colors',
                description: 'Swap primary and secondary colors',
                value: model.swapColors ?? false,
                icon: Icons.swap_horiz,
                onChanged: (bool value) {
                  _updateSettings((m) => m.copyWith(swapColors: value));
                },
              ),
              SwitchSettingWidget(
                title: 'Swap Legacy Colors',
                description: 'Swap legacy primary and secondary colors',
                value: model.swapLegacyColors ?? false,
                icon: Icons.swap_vert,
                onChanged: (bool value) {
                  _updateSettings((m) => m.copyWith(swapLegacyColors: value));
                },
              ),

              const Divider(),

              // Surface Mode
              const SectionHeaderWidget(
                title: 'Surface Mode',
                subtitle: 'Control surface color generation',
                icon: Icons.layers,
              ),
              EnumSettingWidget<FlexSurfaceMode>(
                title: 'Surface Mode',
                description: 'How surface colors are generated',
                value: model.surfaceMode ?? FlexSurfaceMode.level,
                options: FlexSurfaceMode.values,
                labelBuilder: _getFlexSurfaceModeLabel,
                icon: Icons.view_in_ar,
                onChanged: (FlexSurfaceMode value) {
                  _updateSettings((m) => m.copyWith(surfaceMode: value));
                },
              ),

              const Divider(),

              // Typography
              const SectionHeaderWidget(
                title: 'Typography',
                subtitle: 'Font family settings',
                icon: Icons.text_fields,
              ),
              TextSettingWidget(
                title: 'Font Family',
                description: 'Font family name (e.g., Roboto, Manrope)',
                value: model.fontFamily ?? '',
                hintText: 'Enter font family name',
                icon: Icons.font_download,
                onChanged: (String value) {
                  _updateSettings((m) => m.copyWith(
                        fontFamily: value.isEmpty ? null : value,
                      ));
                },
              ),

              const Divider(),

              // Custom Colors - Primary
              const SectionHeaderWidget(
                title: 'Primary Colors',
                subtitle: 'Customize primary color scheme',
                icon: Icons.colorize,
              ),
              ColorSettingWidget(
                title: 'Primary',
                description: 'Primary color',
                color: model.primary ?? Colors.blue,
                icon: Icons.circle,
                onChanged: (Color color) {
                  _updateSettings((m) => m.copyWith(primary: color));
                },
              ),
              ColorSettingWidget(
                title: 'On Primary',
                description: 'Color on primary background',
                color: model.onPrimary ?? Colors.white,
                icon: Icons.circle_outlined,
                onChanged: (Color color) {
                  _updateSettings((m) => m.copyWith(onPrimary: color));
                },
              ),
              ColorSettingWidget(
                title: 'Primary Container',
                description: 'Primary container color',
                color: model.primaryContainer ?? Colors.blue.shade100,
                icon: Icons.square,
                onChanged: (Color color) {
                  _updateSettings((m) => m.copyWith(primaryContainer: color));
                },
              ),
              ColorSettingWidget(
                title: 'On Primary Container',
                description: 'Color on primary container',
                color: model.onPrimaryContainer ?? Colors.blue.shade900,
                icon: Icons.square_outlined,
                onChanged: (Color color) {
                  _updateSettings((m) => m.copyWith(onPrimaryContainer: color));
                },
              ),

              const Divider(),

              // Custom Colors - Secondary
              const SectionHeaderWidget(
                title: 'Secondary Colors',
                subtitle: 'Customize secondary color scheme',
                icon: Icons.palette_outlined,
              ),
              ColorSettingWidget(
                title: 'Secondary',
                description: 'Secondary color',
                color: model.secondary ?? Colors.purple,
                icon: Icons.circle,
                onChanged: (Color color) {
                  _updateSettings((m) => m.copyWith(secondary: color));
                },
              ),
              ColorSettingWidget(
                title: 'On Secondary',
                description: 'Color on secondary background',
                color: model.onSecondary ?? Colors.white,
                icon: Icons.circle_outlined,
                onChanged: (Color color) {
                  _updateSettings((m) => m.copyWith(onSecondary: color));
                },
              ),
              ColorSettingWidget(
                title: 'Secondary Container',
                description: 'Secondary container color',
                color: model.secondaryContainer ?? Colors.purple.shade100,
                icon: Icons.square,
                onChanged: (Color color) {
                  _updateSettings((m) => m.copyWith(secondaryContainer: color));
                },
              ),
              ColorSettingWidget(
                title: 'On Secondary Container',
                description: 'Color on secondary container',
                color: model.onSecondaryContainer ?? Colors.purple.shade900,
                icon: Icons.square_outlined,
                onChanged: (Color color) {
                  _updateSettings((m) => m.copyWith(onSecondaryContainer: color));
                },
              ),

              const Divider(),

              // Custom Colors - Tertiary
              const SectionHeaderWidget(
                title: 'Tertiary Colors',
                subtitle: 'Customize tertiary color scheme',
                icon: Icons.brush,
              ),
              ColorSettingWidget(
                title: 'Tertiary',
                description: 'Tertiary color',
                color: model.tertiary ?? Colors.teal,
                icon: Icons.circle,
                onChanged: (Color color) {
                  _updateSettings((m) => m.copyWith(tertiary: color));
                },
              ),
              ColorSettingWidget(
                title: 'On Tertiary',
                description: 'Color on tertiary background',
                color: model.onTertiary ?? Colors.white,
                icon: Icons.circle_outlined,
                onChanged: (Color color) {
                  _updateSettings((m) => m.copyWith(onTertiary: color));
                },
              ),
              ColorSettingWidget(
                title: 'Tertiary Container',
                description: 'Tertiary container color',
                color: model.tertiaryContainer ?? Colors.teal.shade100,
                icon: Icons.square,
                onChanged: (Color color) {
                  _updateSettings((m) => m.copyWith(tertiaryContainer: color));
                },
              ),
              ColorSettingWidget(
                title: 'On Tertiary Container',
                description: 'Color on tertiary container',
                color: model.onTertiaryContainer ?? Colors.teal.shade900,
                icon: Icons.square_outlined,
                onChanged: (Color color) {
                  _updateSettings((m) => m.copyWith(onTertiaryContainer: color));
                },
              ),

              const Divider(),

              // Custom Colors - Error
              const SectionHeaderWidget(
                title: 'Error Colors',
                subtitle: 'Customize error color scheme',
                icon: Icons.error_outline,
              ),
              ColorSettingWidget(
                title: 'Error',
                description: 'Error color',
                color: model.error ?? Colors.red,
                icon: Icons.circle,
                onChanged: (Color color) {
                  _updateSettings((m) => m.copyWith(error: color));
                },
              ),
              ColorSettingWidget(
                title: 'On Error',
                description: 'Color on error background',
                color: model.onError ?? Colors.white,
                icon: Icons.circle_outlined,
                onChanged: (Color color) {
                  _updateSettings((m) => m.copyWith(onError: color));
                },
              ),
              ColorSettingWidget(
                title: 'Error Container',
                description: 'Error container color',
                color: model.errorContainer ?? Colors.red.shade100,
                icon: Icons.square,
                onChanged: (Color color) {
                  _updateSettings((m) => m.copyWith(errorContainer: color));
                },
              ),
              ColorSettingWidget(
                title: 'On Error Container',
                description: 'Color on error container',
                color: model.onErrorContainer ?? Colors.red.shade900,
                icon: Icons.square_outlined,
                onChanged: (Color color) {
                  _updateSettings((m) => m.copyWith(onErrorContainer: color));
                },
              ),

              const Divider(),

              // Custom Colors - Surface
              const SectionHeaderWidget(
                title: 'Surface Colors',
                subtitle: 'Customize surface colors',
                icon: Icons.layers_outlined,
              ),
              ColorSettingWidget(
                title: 'Surface',
                description: 'Surface color',
                color: model.surface ?? Colors.white,
                icon: Icons.circle,
                onChanged: (Color color) {
                  _updateSettings((m) => m.copyWith(surface: color));
                },
              ),
              ColorSettingWidget(
                title: 'On Surface',
                description: 'Color on surface',
                color: model.onSurface ?? Colors.black,
                icon: Icons.circle_outlined,
                onChanged: (Color color) {
                  _updateSettings((m) => m.copyWith(onSurface: color));
                },
              ),
              ColorSettingWidget(
                title: 'Surface Container Highest',
                description: 'Highest surface container color',
                color: model.surfaceContainerHighest ?? Colors.grey.shade100,
                icon: Icons.square,
                onChanged: (Color color) {
                  _updateSettings((m) => m.copyWith(surfaceContainerHighest: color));
                },
              ),
              ColorSettingWidget(
                title: 'On Surface Variant',
                description: 'Variant color on surface',
                color: model.onSurfaceVariant ?? Colors.grey.shade700,
                icon: Icons.circle_outlined,
                onChanged: (Color color) {
                  _updateSettings((m) => m.copyWith(onSurfaceVariant: color));
                },
              ),

              const Divider(),

              // Custom Colors - Outline
              const SectionHeaderWidget(
                title: 'Outline Colors',
                subtitle: 'Customize outline colors',
                icon: Icons.border_color,
              ),
              ColorSettingWidget(
                title: 'Outline',
                description: 'Outline color',
                color: model.outline ?? Colors.grey,
                icon: Icons.circle,
                onChanged: (Color color) {
                  _updateSettings((m) => m.copyWith(outline: color));
                },
              ),
              ColorSettingWidget(
                title: 'Outline Variant',
                description: 'Outline variant color',
                color: model.outlineVariant ?? Colors.grey.shade300,
                icon: Icons.circle_outlined,
                onChanged: (Color color) {
                  _updateSettings((m) => m.copyWith(outlineVariant: color));
                },
              ),

              const Divider(),

              // Reset button
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _settingsService.reset();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Theme settings reset to defaults'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.restore),
                  label: const Text('Reset to Defaults'),
                ),
              ),

              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}

