import 'dart:convert';

import 'package:diohub/app/app_logger.dart';
import 'package:diohub/utils/json_decode_safe.dart';

/// Stateless descriptor for a settings type: key, default, and serialization.
/// One per settings model; replaces XxxPersistence classes.
/// Single-encode for DB storage: no envelope, no double-encoding.
class SettingsDescriptor<T> {
  const SettingsDescriptor({
    required this.key,
    required this.defaultValue,
    required this.fromJson,
    required this.toJson,
  });

  final String key;
  final T defaultValue;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T value) toJson;

  /// Single-encode for DB storage. No envelope, no double-encoding.
  String serialize(final T value) => jsonEncode(toJson(value));

  /// Single-decode from DB. Returns [defaultValue] on parse error.
  T deserialize(final String raw) {
    try {
      return fromJson(tryDecodeMap(raw, tag: 'SettingsDescriptor.get') ?? {});
    } on FormatException catch (e) {
      AppLogger.warning('Settings deserialization failed for $key', error: e, tag: 'Settings');
      return defaultValue;
    } on TypeError catch (e) {
      AppLogger.warning('Settings type mismatch for $key', error: e, tag: 'Settings');
      return defaultValue;
    }
  }
}
