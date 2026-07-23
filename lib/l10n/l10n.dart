import 'package:diohub/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Locales exposed by DioHub.
///
/// `gen_l10n` also generates the required base `zh` fallback. The application
/// deliberately registers only `zh_Hans`, so a Traditional Chinese system
/// locale does not silently select Simplified Chinese.
const List<Locale> supportedApplicationLocales = <Locale>[
  Locale('en'),
  Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
];

Locale resolveApplicationLocale(
  final List<Locale>? preferredLocales,
  final Iterable<Locale> supportedLocales,
) {
  const Locale english = Locale('en');
  const Locale simplifiedChinese = Locale.fromSubtags(
    languageCode: 'zh',
    scriptCode: 'Hans',
  );

  for (final Locale locale in preferredLocales ?? const <Locale>[]) {
    if (locale.languageCode == 'zh') {
      final bool explicitlyTraditional =
          locale.scriptCode == 'Hant' ||
          locale.countryCode == 'TW' ||
          locale.countryCode == 'HK' ||
          locale.countryCode == 'MO';
      if (!explicitlyTraditional) return simplifiedChinese;
    }
    if (locale.languageCode == 'en') return english;
  }
  return supportedLocales.firstWhere(
    (final Locale locale) => locale == english,
    orElse: () => english,
  );
}

/// Typed access to the generated application strings.
///
/// Keep user-facing text in ARB files and use `context.l10n` from widgets.
extension AppLocalizationsBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
