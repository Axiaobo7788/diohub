import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:diohub/app/app_logger.dart';
import 'package:diohub_models/models/ssh/ssh_connection.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/services/ssh/ssh_secure_storage.dart';
import 'package:diohub/utils/json_decode_safe.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const String _key = 'ssh_connections';

/// Resolved credentials for an SSH connection (password and/or decoded key pairs).
/// Provided by [sshConnectionCredentialsProvider]; view uses this instead of
/// calling [SSHSecureStorage] directly.
class SSHConnectionCredentials {
  const SSHConnectionCredentials({this.password, this.identities});

  final String? password;
  final List<SSHKeyPair>? identities;
}

/// Persist only metadata; never persist password (use [SSHSecureStorage] for that).
Map<String, dynamic> _toPersistableJson(SSHConnection c) {
  final Map<String, dynamic> map = c.toJson();
  map.remove('password');
  return map;
}

class SSHConnectionsNotifier extends AsyncNotifier<List<SSHConnection>> {
  @override
  Future<List<SSHConnection>> build() async => _load();

  Future<List<SSHConnection>> _load() async {
    final raw = await ref.read(appMetaDaoProvider).getValue(_key);
    final list = tryDecodeList(raw, tag: 'SSHConnectionsNotifier');
    if (list == null) return [];
    try {
      return list
          .whereType<Map<String, dynamic>>()
          .map((e) => SSHConnection.fromJson(e))
          .toList();
    } catch (e, st) {
      AppLogger.warning(
        'Failed to decode persisted SSH connections',
        error: e,
        stackTrace: st,
        tag: 'SSHConnectionsNotifier',
      );
      return [];
    }
  }

  Future<void> _save(List<SSHConnection> list) async {
    final List<Map<String, dynamic>> encoded =
        list.map(_toPersistableJson).toList();
    await ref
        .read(appMetaDaoProvider)
        .setValue(_key, jsonEncode(encoded));
  }

  Future<void> add(SSHConnection connection) async {
    final list = state.requireValue;
    final newList = [...list, connection];
    state = AsyncData(newList);
    await _save(newList);
  }

  Future<void> remove(String id) async {
    final SSHSecureStorage storage = ref.read(sshSecureStorageProvider);
    await storage.deleteConnectionPassword(id);
    await storage.deletePrivateKey(id);
    final list = state.requireValue.where((c) => c.id != id).toList();
    state = AsyncData(list);
    await _save(list);
  }

  Future<void> updateConnection(SSHConnection connection) async {
    final list = state.requireValue;
    state = AsyncData([
      for (final c in list) c.id == connection.id ? connection : c,
    ]);
    await _save(state.requireValue);
  }

  /// Persists SSH connection password (e.g. after user enters it).
  /// Invalidates [sshConnectionCredentialsProvider] for the given connection.
  Future<void> saveConnectionPassword(
      String connectionId, String password) async {
    await ref.read(sshSecureStorageProvider).setConnectionPassword(
          connectionId,
          password,
        );
    ref.invalidate(sshConnectionCredentialsProvider(connectionId));
  }
}

final sshConnectionsProvider =
    AsyncNotifierProvider<SSHConnectionsNotifier, List<SSHConnection>>(
  SSHConnectionsNotifier.new,
);

final sshSecureStorageProvider = Provider<SSHSecureStorage>((ref) {
  return SSHSecureStorage();
});

/// Resolves credentials for an SSH connection from secure storage.
/// View uses this instead of [SSHSecureStorage] directly.
final sshConnectionCredentialsProvider =
    FutureProvider.family<SSHConnectionCredentials?, String>(
  (ref, connectionId) async {
    final connections = (() {
          final c = ref.watch(sshConnectionsProvider);
          return c.hasValue ? c.value : null;
        }()) ??
        <SSHConnection>[];
    final connection = connections.cast<SSHConnection?>().firstWhere(
          (c) => c?.id == connectionId,
          orElse: () => null,
        );
    if (connection == null) return null;

    final storage = ref.read(sshSecureStorageProvider);
    String? password;
    List<SSHKeyPair>? identities;

    if (connection.authMethod == SSHAuthMethod.password) {
      password = connection.password?.isNotEmpty == true
          ? connection.password
          : await storage.getConnectionPassword(connection.id);
    } else if (connection.authMethod == SSHAuthMethod.key &&
        connection.privateKeyId != null &&
        connection.privateKeyId!.isNotEmpty) {
      final pem = await storage.getPrivateKey(connection.privateKeyId!);
      if (pem != null && pem.isNotEmpty) {
        try {
          identities = OpenSSHKeyPairs.decode(Uint8List.fromList(pem.codeUnits))
              .getPrivateKeys();
        } catch (e, st) {
          AppLogger.warning(
            'Invalid or unsupported private key',
            error: e,
            stackTrace: st,
            tag: 'sshConnectionCredentialsProvider',
          );
          return null;
        }
      }
    }

    return SSHConnectionCredentials(password: password, identities: identities);
  },
);
