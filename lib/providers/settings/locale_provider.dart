import 'package:diohub/app/settings/locale_settings.dart';
import 'package:diohub/app/settings/settings_descriptor.dart';
import 'package:diohub/common/riverpod/persisted_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final NotifierProvider<LocaleNotifier, LocaleSettings> localeProvider =
    NotifierProvider<LocaleNotifier, LocaleSettings>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<LocaleSettings>
    with PersistedNotifier<LocaleSettings> {
  @override
  SettingsDescriptor<LocaleSettings> get descriptor => localeSettingsDescriptor;

  Future<void> setLanguage(final AppLanguage language) => update(
    (final LocaleSettings settings) => settings.copyWith(language: language),
  );
}
