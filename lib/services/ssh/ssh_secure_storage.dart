import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _prefixPassword = 'ssh_conn_password_';
const String _prefixPrivateKey = 'ssh_private_key_';

/// Stores and retrieves SSH secrets in secure storage.
/// - Passwords: keyed by connection id (for "remember password").
/// - Private keys: keyed by [privateKeyId] (content stored when user adds/imports a key).
class SSHSecureStorage {
  SSHSecureStorage() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> setConnectionPassword(
      String connectionId, String password) async {
    await _storage.write(key: '$_prefixPassword$connectionId', value: password);
  }

  Future<String?> getConnectionPassword(String connectionId) async {
    return _storage.read(key: '$_prefixPassword$connectionId');
  }

  Future<void> deleteConnectionPassword(String connectionId) async {
    await _storage.delete(key: '$_prefixPassword$connectionId');
  }

  Future<void> setPrivateKey(String keyId, String pemContent) async {
    await _storage.write(key: '$_prefixPrivateKey$keyId', value: pemContent);
  }

  Future<String?> getPrivateKey(String keyId) async {
    return _storage.read(key: '$_prefixPrivateKey$keyId');
  }

  Future<void> deletePrivateKey(String keyId) async {
    await _storage.delete(key: '$_prefixPrivateKey$keyId');
  }
}
