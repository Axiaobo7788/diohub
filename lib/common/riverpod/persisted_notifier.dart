import 'package:diohub/app/settings/settings_descriptor.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mixin that gives any `Notifier<T>` automatic DB persistence.
/// Subclasses declare [descriptor] and get [build], [update], [reset] for free.
mixin PersistedNotifier<T> on Notifier<T> {
  SettingsDescriptor<T> get descriptor;

  @override
  T build() {
    return ref.read(settingsCacheProvider).read(descriptor);
  }

  /// Generic update — callers pass a copyWith lambda. Optimistic UI update.
  Future<void> update(final T Function(T current) mutate) async {
    final T next = mutate(state);
    state = next;
    await ref.read(settingsDaoProvider).setValue(
          descriptor.key,
          descriptor.serialize(next),
        );
  }

  /// Reset to default and delete from DB.
  Future<void> reset() async {
    state = descriptor.defaultValue;
    await ref.read(settingsDaoProvider).deleteKey(descriptor.key);
  }
}

/// Generic notifier that delegates to a SettingsDescriptor for persistence.
class GenericPersistedNotifier<T> extends Notifier<T>
    with PersistedNotifier<T> {
  GenericPersistedNotifier(this._descriptor);

  final SettingsDescriptor<T> _descriptor;

  @override
  SettingsDescriptor<T> get descriptor => _descriptor;
}

/// Creates a NotifierProvider for a persisted settings type.
///
/// Eliminates boilerplate for simple settings that only need descriptor override.
///
/// Example:
/// ```dart
/// final appearanceProvider = createPersistedProvider(appearanceDescriptor);
/// ```
NotifierProvider<GenericPersistedNotifier<T>, T> createPersistedProvider<T>(
  SettingsDescriptor<T> descriptor,
) =>
    NotifierProvider<GenericPersistedNotifier<T>, T>(
      () => GenericPersistedNotifier<T>(descriptor),
    );
