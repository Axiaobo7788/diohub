import 'package:diohub/app/app_logger.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage for access tokens. Read/write/delete by key.
///
/// On iOS, uses `KeychainAccessibility.first_unlock` to allow background access
/// after the device has been unlocked once since boot. On Android, uses encrypted
/// shared preferences for the same purpose.
class TokenStore {
  TokenStore()
      : _storage = FlutterSecureStorage(
          iOptions: _iosOptions,
          aOptions: _androidOptions,
        );

  /// iOS options: allow access after first unlock (enables background access).
  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  /// Android options: use encrypted shared preferences (enables background access).
  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } on PlatformException catch (e) {
      AppLogger.warning('Secure storage read failed', error: e, tag: 'Auth');
      return null;
    }
  }

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// Delete all keys matching [prefix]. Used for account-scoped
  /// cleanup (e.g. all MCP tokens for a removed account).
  ///
  /// Reads all keys, filters by prefix, deletes each match.
  /// Safe to call with a prefix that matches nothing.
  Future<int> deleteByPrefix(String prefix) async {
    try {
      final all = await _storage.readAll();
      final matching = all.keys.where((k) => k.startsWith(prefix)).toList();
      for (final key in matching) {
        await _storage.delete(key: key);
      }
      return matching.length;
    } on PlatformException catch (e) {
      AppLogger.warning('Secure storage read failed', error: e, tag: 'Auth');
      return 0;
    }
  }
}
