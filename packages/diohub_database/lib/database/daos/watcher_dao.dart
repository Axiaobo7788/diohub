part of '../database.dart';

@DriftAccessor(tables: [WatcherStateEntries, WatcherConfigEntries])
class WatcherDao extends AccountScopedDao with _$WatcherDaoMixin {
  WatcherDao(super.attachedDatabase, [super.accountKey = '']);

  Future<List<({String nodeId, String watcherType})>> activeWatchers() async {
    final rows = await (selectOnly(watcherStateEntries, distinct: true)
          ..addColumns([
            watcherStateEntries.nodeId,
            watcherStateEntries.watcherType,
          ])
          ..where(accountScope(watcherStateEntries.accountKey)))
        .get();
    return rows
        .map((r) => (
              nodeId: r.read(watcherStateEntries.nodeId)!,
              watcherType: r.read(watcherStateEntries.watcherType)!,
            ))
        .toList();
  }

  Future<String?> read(
    String nodeId,
    String watcherType,
    String key,
  ) async {
    final row = await (select(watcherStateEntries)
          ..where((w) =>
              accountScope(w.accountKey) &
              w.nodeId.equals(nodeId) &
              w.watcherType.equals(watcherType) &
              w.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> write({
    required String nodeId,
    required String watcherType,
    required String key,
    required String value,
  }) =>
      into(watcherStateEntries).insertOnConflictUpdate(
        WatcherStateEntriesCompanion(
          accountKey: Value(accountKey),
          nodeId: Value(nodeId),
          watcherType: Value(watcherType),
          key: Value(key),
          value: Value(value),
        ),
      );

  Future<void> deleteKey(
    String nodeId,
    String watcherType,
    String key,
  ) =>
      (delete(watcherStateEntries)
            ..where((w) =>
                accountScope(w.accountKey) &
                w.nodeId.equals(nodeId) &
                w.watcherType.equals(watcherType) &
                w.key.equals(key)))
          .go();

  Future<void> deleteForWatcher(String nodeId, String watcherType) =>
      (delete(watcherStateEntries)
            ..where((w) =>
                accountScope(w.accountKey) &
                w.nodeId.equals(nodeId) &
                w.watcherType.equals(watcherType)))
          .go();

  Future<int> countForEntity(String nodeId) async {
    final count = watcherStateEntries.nodeId.count();
    final query = selectOnly(watcherStateEntries)
      ..addColumns([count])
      ..where(accountScope(watcherStateEntries.accountKey) &
          watcherStateEntries.nodeId.equals(nodeId));
    return query.map((r) => r.read(count)!).getSingle();
  }

  Stream<int> watchCountForEntity(String nodeId) {
    final count = watcherStateEntries.nodeId.count();
    final query = selectOnly(watcherStateEntries)
      ..addColumns([count])
      ..where(accountScope(watcherStateEntries.accountKey) &
          watcherStateEntries.nodeId.equals(nodeId));
    return query.watch().map((rows) => rows.isEmpty ? 0 : (rows.first.read(count) ?? 0));
  }

  /// Persist watcher configs for the background task. Replaces all config rows.
  Future<void> writeSerialised(
    List<({String nodeId, String watcherType, Map<String, dynamic> config})>
        entries,
  ) async {
    await transaction(() async {
      await (delete(watcherConfigEntries)
            ..where((w) => accountScope(w.accountKey)))
          .go();
      await batch((b) {
        for (final e in entries) {
          b.insert(
            watcherConfigEntries,
            WatcherConfigEntriesCompanion(
              accountKey: Value(accountKey),
              watcherId: Value(e.nodeId),
              watcherType: Value(e.watcherType),
              value: Value(jsonEncode(e.config)),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
    });
  }

  /// Load all persisted watcher configs (for background task).
  Future<List<Map<String, dynamic>>> readAllSerialised() async {
    final rows = await (select(watcherConfigEntries)
          ..where((w) => accountScope(w.accountKey)))
        .get();
    return rows
        .map((r) => tryDecodeMap(r.value, tag: 'WatcherDao.readAllSerialised'))
        .whereType<Map<String, dynamic>>()
        .toList();
  }
}
