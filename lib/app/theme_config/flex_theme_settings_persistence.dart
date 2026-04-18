import 'package:diohub/app/settings/settings_descriptor.dart';
import 'package:diohub/app/theme_config/models/flex_theme_settings_model.dart';

Map<String, dynamic> _flexThemeToJson(final FlexThemeSettingsModel v) =>
    v.toJson();

final SettingsDescriptor<FlexThemeSettingsModel> flexThemeDescriptor =
    SettingsDescriptor<FlexThemeSettingsModel>(
  key: 'flex_theme_settings',
  defaultValue: FlexThemeSettingsModel.defaults,
  fromJson: FlexThemeSettingsModel.fromJson,
  toJson: _flexThemeToJson,
);
