import 'package:diohub/app/settings/settings_descriptor.dart';

/// Pre-loaded in-memory cache of all settings rows.
/// Populated once at app startup before any provider is created.
/// Enables synchronous reads in Notifier.build().
class SettingsCache {
  SettingsCache(this._raw);

  final Map<String, String> _raw;

  /// Check if a setting key exists in the cache (user has explicitly set it).
  bool containsKey(String key) => _raw.containsKey(key);

  /// Read a setting synchronously from the pre-loaded cache.
  T read<T>(final SettingsDescriptor<T> descriptor) {
    final String? raw = _raw[descriptor.key];
    if (raw == null) {
      return descriptor.defaultValue;
    }
    return descriptor.deserialize(raw);
  }
}
