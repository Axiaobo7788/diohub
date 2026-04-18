import 'dart:convert';

import 'package:diohub_database/database/database.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:diohub_models/models/server_config.dart';
import 'package:diohub/utils/json_decode_safe.dart';
import 'package:diohub/services/authentication/token_store.dart';
import 'package:diohub/services/authentication/token_set_io.dart';
import 'package:drift/drift.dart' show Value;

/// Account CRUD in Drift DB. Deletes tokens via [TokenStore] when removing accounts.
class AccountRepository {
  AccountRepository(this._db, this._tokenStore);

  final AppDatabase _db;
  final TokenStore _tokenStore;

  Future<void> setActiveAccount(String username) async {
    await _db.appMetaDao.setActiveAccount(username);
  }

  Future<String?> getActiveAccount() async {
    return _db.appMetaDao.getActiveAccount();
  }

  Future<List<String>> getAllAccountUsernames() async {
    final accounts = await getAllAccounts();
    return accounts.map((a) => a.username).toList();
  }

  Future<List<AccountModel>> getAllAccounts() async {
    final rows = await _db.accountsDao.getAll();
    return rows.map(_entryToAccountModel).toList();
  }

  static AccountModel _entryToAccountModel(AccountEntry e) {
    final Map<String, dynamic> config = e.serverConfigJson.isNotEmpty
        ? (tryDecodeMap(e.serverConfigJson, tag: 'AccountRepository._entryToAccountModel') ?? <String, dynamic>{})
        : <String, dynamic>{};
    final ServerConfig serverConfig = ServerConfig.fromJson(config);
    return AccountModel(
      nodeId: e.nodeId,
      username: e.username,
      displayName: e.displayName,
      avatarUrl: e.avatarUrl,
      addedAt: e.addedAt,
      scope: config['scope'] as String?,
      serverConfig: serverConfig,
      authMethod:
          AuthMethod.values.asNameMap()[e.authMethod] ?? AuthMethod.oauth,
    );
  }

  static AccountEntriesCompanion _accountToCompanion(AccountModel a) {
    final Map<String, dynamic> configJson = a.serverConfig.toJson();
    if (a.scope != null) {
      configJson['scope'] = a.scope;
    }
    final serverId = a.serverConfig.id;
    return AccountEntriesCompanion(
      key: Value('$serverId/${a.nodeId}'),
      nodeId: Value(a.nodeId),
      serverId: Value(serverId),
      username: Value(a.username),
      displayName: Value(a.displayName),
      avatarUrl: Value(a.avatarUrl),
      serverConfigJson: Value(jsonEncode(configJson)),
      authMethod: Value(a.authMethod.name),
      addedAt: Value(a.addedAt),
    );
  }

  Future<void> addAccount(AccountModel account) async {
    await _db.accountsDao.upsert(_accountToCompanion(account));
  }

  Future<void> updateAccountProfile({
    required String nodeId,
    required String serverId,
    required String username,
    String? displayName,
    String? avatarUrl,
  }) async {
    final accounts = await getAllAccounts();
    AccountModel? account;
    for (final a in accounts) {
      if (a.nodeId == nodeId && a.serverConfig.id == serverId) {
        account = a;
        break;
      }
    }
    if (account == null) return;

    final oldUsername = account.username;
    await _db.accountsDao.updateProfile(
      nodeId,
      serverId,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );

    final activeUsername = await getActiveAccount();
    if (activeUsername == oldUsername) {
      await setActiveAccount(username);
    }
  }

  Future<void> removeAccount(String username, {String? serverId}) async {
    final accounts = await getAllAccounts();
    AccountModel? accountToRemove;
    for (final a in accounts) {
      if (a.username == username &&
          (serverId == null || a.serverConfig.id == serverId)) {
        accountToRemove = a;
        break;
      }
    }

    if (accountToRemove != null) {
      await _tokenStore.deleteTokenSet(accountToRemove.storageKey);

      // Clean up all MCP tokens for this account (OAuth, PAT, refresh,
      // expiry, resources). Must happen BEFORE Drift CASCADE delete,
      // which would destroy the server ID list.
      await _tokenStore.deleteByPrefix(
        'mcp_${accountToRemove.accountKey}_',
      );

      await _db.accountsDao.deleteAccount(
        accountToRemove.nodeId,
        accountToRemove.serverConfig.id,
      );

      final activeUsername = await getActiveAccount();
      if (activeUsername == username) {
        final remaining = await getAllAccounts();
        if (remaining.isNotEmpty) {
          await setActiveAccount(remaining.first.username);
        } else {
          await _db.appMetaDao.clearActiveAccount();
        }
      }
    }
  }

  /// Removes all accounts and clears active account. Used by logOut.
  Future<void> clearAll() async {
    await _db.accountsDao.deleteAll();
    await _db.appMetaDao.clearActiveAccount();
  }

  Future<AccountModel?> getActiveAccountModel() async {
    final activeUsername = await getActiveAccount();
    if (activeUsername == null) return null;

    final accounts = await getAllAccounts();
    for (final a in accounts) {
      if (a.username == activeUsername) return a;
    }
    return null;
  }
}
