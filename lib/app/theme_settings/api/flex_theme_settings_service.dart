import 'package:diohub/app/theme_settings/api/theme_settings_api.dart';
import 'package:diohub/app/theme_settings/models/flex_theme_settings_model.dart';

/// Service for managing FlexColorScheme theme settings
class FlexThemeSettingsService extends ThemeSettingsApi<FlexThemeSettingsModel> {
  FlexThemeSettingsService()
      : super(
          storageKey: 'flex_theme_settings',
          defaultValue: FlexThemeSettingsModel.defaults,
          version: 1,
        );

  /// Get light theme settings
  FlexThemeSettingsModel get lightSettings => value;

  /// Get dark theme settings (can be different from light)
  FlexThemeSettingsModel get darkSettings => value; // For now, same as light

  @override
  Map<String, dynamic> toJson(FlexThemeSettingsModel value) => value.toJson();

  @override
  FlexThemeSettingsModel fromJson(Map<String, dynamic> json) =>
      FlexThemeSettingsModel.fromJson(json);
}




