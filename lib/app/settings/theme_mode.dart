import 'dart:convert';

import 'package:diohub/app/settings/base.dart';
import 'package:flutter/material.dart';

/// Combined theme settings that includes both theme mode and Material You preference
class ThemeSettings {
  const ThemeSettings({
    required this.themeMode,
    required this.materialYouEnabled,
  });

  final ThemeMode themeMode;
  final bool materialYouEnabled;

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'materialYouEnabled': materialYouEnabled,
      };

  factory ThemeSettings.fromJson(Map<String, dynamic> json) => ThemeSettings(
        themeMode: ThemeMode.values.firstWhere(
          (mode) => mode.name == json['themeMode'],
          orElse: () => ThemeMode.system,
        ),
        materialYouEnabled: json['materialYouEnabled'] as bool? ?? true,
      );

  ThemeSettings copyWith({
    ThemeMode? themeMode,
    bool? materialYouEnabled,
  }) =>
      ThemeSettings(
        themeMode: themeMode ?? this.themeMode,
        materialYouEnabled: materialYouEnabled ?? this.materialYouEnabled,
      );
}

class ThemeModeSettings extends Settings<ThemeSettings> {
  ThemeModeSettings()
      : super(
          'app_theme_mode',
          defaultSetting: const ThemeSettings(
            themeMode: ThemeMode.system,
            materialYouEnabled: true,
          ),
          formatVer: 1, // Incremented version to handle new format
        );

  /// Get the current theme mode
  ThemeMode get themeMode => currentSetting.themeMode;

  /// Get whether Material You is enabled
  bool get materialYouEnabled => currentSetting.materialYouEnabled;

  /// Update theme mode
  Future<void> updateThemeMode(ThemeMode mode) async {
    await updateData(currentSetting.copyWith(themeMode: mode));
  }

  /// Update Material You setting
  Future<void> updateMaterialYou(bool enabled) async {
    await updateData(currentSetting.copyWith(materialYouEnabled: enabled));
  }

  /// Update both settings at once
  Future<void> updateSettings({
    ThemeMode? themeMode,
    bool? materialYouEnabled,
  }) async {
    await updateData(
      currentSetting.copyWith(
        themeMode: themeMode,
        materialYouEnabled: materialYouEnabled,
      ),
    );
  }

  // Legacy method for backward compatibility - maps to updateThemeMode
  Future<void> updateThemeModeLegacy(ThemeMode data) async {
    await updateThemeMode(data);
  }

  @override
  ThemeSettings toType(final String data) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      return ThemeSettings.fromJson(json);
    } catch (e) {
      // Fallback for old format
      return ThemeSettings(
        themeMode: _parseLegacyThemeMode(data),
        materialYouEnabled: true,
      );
    }
  }

  ThemeMode _parseLegacyThemeMode(String data) {
    switch (data) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  @override
  String toPrefData() {
    return jsonEncode(currentSetting.toJson());
  }
}
