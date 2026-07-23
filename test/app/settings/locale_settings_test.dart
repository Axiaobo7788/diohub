import 'package:diohub/app/settings/locale_settings.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to the system language', () {
    expect(const LocaleSettings().language, AppLanguage.system);
    expect(localeSettingsDescriptor.defaultValue.language, AppLanguage.system);
  });

  test('round-trips every supported language through persistence', () {
    for (final AppLanguage language in AppLanguage.values) {
      final LocaleSettings original = LocaleSettings(language: language);
      final String encoded = localeSettingsDescriptor.serialize(original);
      final LocaleSettings decoded = localeSettingsDescriptor.deserialize(
        encoded,
      );

      expect(decoded, original);
      expect(decoded.language.storageValue, language.storageValue);
    }
  });

  test('unknown or malformed values safely fall back to system', () {
    expect(
      LocaleSettings.fromJson(<String, dynamic>{
        'language': 'unsupported-locale',
      }).language,
      AppLanguage.system,
    );
    expect(
      LocaleSettings.fromJson(<String, dynamic>{'language': 42}).language,
      AppLanguage.system,
    );
    expect(
      localeSettingsDescriptor.deserialize('not json').language,
      AppLanguage.system,
    );
  });

  test('locales map system, English, and Simplified Chinese', () {
    expect(AppLanguage.system.locale, isNull);
    expect(AppLanguage.english.locale, const Locale('en'));
    expect(
      AppLanguage.simplifiedChinese.locale,
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    );
    expect(AppLanguage.simplifiedChinese.languageCode, 'zh-Hans');
  });

  test('migrates the prototype zh persistence value to Simplified Chinese', () {
    expect(
      LocaleSettings.fromJson(<String, dynamic>{'language': 'zh'}).language,
      AppLanguage.simplifiedChinese,
    );
  });
}
