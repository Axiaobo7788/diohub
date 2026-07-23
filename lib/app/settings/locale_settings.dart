import 'package:diohub/app/settings/settings_descriptor.dart';
import 'package:flutter/widgets.dart';

/// Languages that can be selected independently from the operating system.
///
/// [storageValue] is deliberately stable and uses a BCP-47 language tag where
/// applicable. Do not persist enum names: they may change as the UI evolves.
enum AppLanguage {
  system('system'),
  english('en'),
  simplifiedChinese('zh-Hans');

  const AppLanguage(this.storageValue);

  final String storageValue;

  /// Null means that Flutter should resolve the locale from the platform.
  Locale? get locale => switch (this) {
    AppLanguage.system => null,
    AppLanguage.english => const Locale('en'),
    AppLanguage.simplifiedChinese => const Locale.fromSubtags(
      languageCode: 'zh',
      scriptCode: 'Hans',
    ),
  };

  /// Stable BCP-47 tag for non-widget consumers.
  String? get languageCode => locale?.toLanguageTag();

  static AppLanguage fromStorageValue(final Object? value) {
    if (value is! String) return AppLanguage.system;
    // `zh` was used by the first i18n prototype. Keep reading it so existing
    // device-local settings migrate without a reset.
    if (value == 'zh') return AppLanguage.simplifiedChinese;
    return AppLanguage.values.firstWhere(
      (final AppLanguage language) => language.storageValue == value,
      orElse: () => AppLanguage.system,
    );
  }
}

/// Global, device-local language preference.
///
/// It is intentionally not attached to a GitHub account: changing accounts
/// must not change the client language.
class LocaleSettings {
  const LocaleSettings({this.language = AppLanguage.system});

  factory LocaleSettings.fromJson(final Map<String, dynamic> json) =>
      LocaleSettings(language: AppLanguage.fromStorageValue(json['language']));

  final AppLanguage language;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'language': language.storageValue,
  };

  LocaleSettings copyWith({final AppLanguage? language}) =>
      LocaleSettings(language: language ?? this.language);

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is LocaleSettings && other.language == language;

  @override
  int get hashCode => language.hashCode;
}

Map<String, dynamic> _localeSettingsToJson(final LocaleSettings value) =>
    value.toJson();

const SettingsDescriptor<LocaleSettings> localeSettingsDescriptor =
    SettingsDescriptor<LocaleSettings>(
      key: 'app_locale',
      defaultValue: LocaleSettings(),
      fromJson: LocaleSettings.fromJson,
      toJson: _localeSettingsToJson,
    );
