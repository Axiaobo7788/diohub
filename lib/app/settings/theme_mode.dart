import 'dart:io';

import 'package:diohub/app/settings/serialization_helpers.dart';
import 'package:diohub/app/settings/settings_descriptor.dart';
import 'package:flutter/material.dart';

/// Combined theme settings that includes both theme mode and Material You preference
class ThemeSettings {
  const ThemeSettings({
    required this.themeMode,
    required this.materialYouEnabled,
    this.scopedProfileThemeEnabled = true,
    this.scopedThemeIntensity = 0.35,
  });

  factory ThemeSettings.fromJson(final Map<String, dynamic> json) =>
      ThemeSettings(
        themeMode: ThemeMode.values.firstWhere(
          (final ThemeMode mode) => mode.name == json['themeMode'],
          orElse: () => ThemeMode.system,
        ),
        materialYouEnabled:
            boolFromJsonOr(json, 'materialYouEnabled', Platform.isAndroid),
        scopedProfileThemeEnabled:
            boolFromJsonOr(json, 'scopedProfileThemeEnabled', true),
        scopedThemeIntensity:
            doubleFromJsonOr(json, 'scopedThemeIntensity', 0.35),
      );

  final ThemeMode themeMode;
  final bool materialYouEnabled;

  /// Whether profile-based scoped theming is enabled.
  final bool scopedProfileThemeEnabled;

  /// Intensity of the scoped theme blend (0.0 = no effect, 1.0 = full image color).
  final double scopedThemeIntensity;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'themeMode': themeMode.name,
        'materialYouEnabled': materialYouEnabled,
        'scopedProfileThemeEnabled': scopedProfileThemeEnabled,
        'scopedThemeIntensity': scopedThemeIntensity,
      };

  ThemeSettings copyWith({
    final ThemeMode? themeMode,
    final bool? materialYouEnabled,
    final bool? scopedProfileThemeEnabled,
    final double? scopedThemeIntensity,
  }) =>
      ThemeSettings(
        themeMode: themeMode ?? this.themeMode,
        materialYouEnabled: materialYouEnabled ?? this.materialYouEnabled,
        scopedProfileThemeEnabled:
            scopedProfileThemeEnabled ?? this.scopedProfileThemeEnabled,
        scopedThemeIntensity: scopedThemeIntensity ?? this.scopedThemeIntensity,
      );
}

Map<String, dynamic> _themeSettingsToJson(final ThemeSettings v) =>
    v.toJson();

const SettingsDescriptor<ThemeSettings> themeModeDescriptor =
    SettingsDescriptor<ThemeSettings>(
  key: 'app_theme_mode',
  defaultValue: ThemeSettings(
    themeMode: ThemeMode.system,
    materialYouEnabled: true,
  ),
  fromJson: ThemeSettings.fromJson,
  toJson: _themeSettingsToJson,
);
