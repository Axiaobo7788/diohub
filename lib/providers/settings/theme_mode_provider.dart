import 'package:diohub/app/settings/theme_mode.dart';
import 'package:diohub/app/settings/settings_descriptor.dart';
import 'package:diohub/common/riverpod/persisted_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod provider for theme mode and Material You settings.
///
/// State is [ThemeSettings].
final NotifierProvider<ThemeModeNotifier, ThemeSettings> themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeSettings>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeSettings>
    with PersistedNotifier<ThemeSettings> {
  @override
  SettingsDescriptor<ThemeSettings> get descriptor => themeModeDescriptor;

  ThemeMode get themeMode => state.themeMode;
  bool get materialYouEnabled => state.materialYouEnabled;
  bool get scopedProfileThemeEnabled => state.scopedProfileThemeEnabled;
  double get scopedThemeIntensity => state.scopedThemeIntensity;

  Future<void> updateScopedTheme({
    final bool? enabled,
    final double? intensity,
  }) async {
    await update((final ThemeSettings s) => s.copyWith(
          scopedProfileThemeEnabled: enabled,
          scopedThemeIntensity: intensity,
        ));
  }
}
