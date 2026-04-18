import 'package:diohub/app/settings/settings_descriptor.dart';
import 'package:diohub/common/riverpod/persisted_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool _developerModeFromJson(final Map<String, dynamic> json) =>
    json['v'] == true;

Map<String, dynamic> _developerModeToJson(final bool value) => <String, dynamic>{
      'v': value,
    };

const SettingsDescriptor<bool> developerModeDescriptor =
    SettingsDescriptor<bool>(
  key: 'developer_mode',
  defaultValue: false,
  fromJson: _developerModeFromJson,
  toJson: _developerModeToJson,
);

final NotifierProvider<DeveloperModeNotifier, bool> developerModeProvider =
    NotifierProvider<DeveloperModeNotifier, bool>(
  DeveloperModeNotifier.new,
);

class DeveloperModeNotifier extends Notifier<bool>
    with PersistedNotifier<bool> {
  @override
  SettingsDescriptor<bool> get descriptor => developerModeDescriptor;

  /// Toggle developer mode on/off. Persists to database.
  Future<void> toggle() async {
    await update((final bool _) => !state);
  }

  /// Explicitly set developer mode state.
  Future<void> setEnabled(final bool enabled) async {
    await update((final bool _) => enabled);
  }
}

/// Check if developer mode is currently enabled.
bool isDeveloperMode(WidgetRef ref) => ref.watch(developerModeProvider);
