part of '../database.dart';

/// DAO for the central entity cache.
///
/// This DAO is called by ALL entity-fetching code paths — screen data loads,
/// bookmark creation, history recording, background refreshes. It is the
/// single writer of entity display data.
@DriftAccessor(tables: [
  EntityCacheEntries,
  BookmarkEntries,
  HistoryEntries,
  DraftEntries,
  DownloadHistoryEntries,
  WatcherStateEntries,
])
class EntityCacheDao extends DatabaseAccessor<AppDatabase>
    with _$EntityCacheDaoMixin {
  EntityCacheDao(super.attachedDatabase);

  /// Upserts an entity's cached data. Called after every successful API fetch.
  /// Uses insertOnConflictUpdate — PK is nodeId, so an existing entity's data
  /// is updated in place.
  Future<void> upsert(EntityCacheEntriesCompanion entry) =>
      into(entityCacheEntries).insertOnConflictUpdate(entry);

  /// Batch upsert — for list views that fetch many entities at once.
  Future<void> upsertAll(List<EntityCacheEntriesCompanion> entries) =>
      batch((b) => b.insertAllOnConflictUpdate(entityCacheEntries, entries));

  /// Resolves entityPath to nodeId. Returns null if not cached (global lookup).
  Future<String?> getNodeIdForPath(String entityPath) async {
    final row = await (select(entityCacheEntries)
          ..where((e) => e.entityPath.equals(entityPath))
          ..limit(1))
        .getSingleOrNull();
    return row?.nodeId;
  }

  /// Watches a single entity's cached data (by nodeId; cache is global).
  Stream<EntityCacheEntry?> watch(String nodeId) =>
      (select(entityCacheEntries)..where((e) => e.nodeId.equals(nodeId)))
          .watchSingleOrNull();

  /// Updates the cached entityPath if it changed (rename/transfer).
  /// Only writes if the path actually changed to avoid unnecessary watch re-fires.
  Future<void> refreshPath(String nodeId, String currentPath) async {
    await (update(entityCacheEntries)
          ..where((e) =>
              e.nodeId.equals(nodeId) & e.entityPath.equals(currentPath).not()))
        .write(EntityCacheEntriesCompanion(entityPath: Value(currentPath)));
  }
}
