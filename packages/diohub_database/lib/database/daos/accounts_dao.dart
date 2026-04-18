part of '../database.dart';

@DriftAccessor(tables: [AccountEntries])
class AccountsDao extends DatabaseAccessor<AppDatabase>
    with _$AccountsDaoMixin {
  AccountsDao(super.db);

  Future<List<AccountEntry>> getAll() => select(accountEntries).get();

  Stream<List<AccountEntry>> watchAll({
    int limit = 500,
    int offset = 0,
  }) =>
      (select(accountEntries)..limit(limit, offset: offset)).watch();

  Future<void> upsert(AccountEntriesCompanion entry) =>
      into(accountEntries).insertOnConflictUpdate(entry);

  Future<int> deleteAccount(String nodeId, String serverId) => (delete(
          accountEntries)
        ..where((a) => a.nodeId.equals(nodeId) & a.serverId.equals(serverId)))
      .go();

  /// Updates mutable profile fields (username, displayName, avatarUrl) for the account identified by [nodeId] and [serverId].
  Future<int> updateProfile(
    String nodeId,
    String serverId, {
    required String username,
    String? displayName,
    String? avatarUrl,
  }) =>
      (update(accountEntries)
            ..where(
                (a) => a.nodeId.equals(nodeId) & a.serverId.equals(serverId)))
          .write(AccountEntriesCompanion(
        username: Value(username),
        displayName: Value(displayName),
        avatarUrl: Value(avatarUrl),
      ));

  Future<void> deleteAll() => delete(accountEntries).go();
}
