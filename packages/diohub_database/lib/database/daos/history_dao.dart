part of '../database.dart';

@DriftAccessor(tables: [HistoryEntries, EntityCacheEntries])
class HistoryDao extends AccountDao with BookmarkLookup, _$HistoryDaoMixin {
  HistoryDao(super.attachedDatabase, [super.accountKey = '']);

  @override
  EntityColumns get columns => (
        accountKey: historyEntries.accountKey,
        nodeId: entityCacheEntries.nodeId,
        entityPath: entityCacheEntries.entityPath,
        entityType: entityCacheEntries.entityType,
        parentPath: entityCacheEntries.parentPath,
        parentNodeId: entityCacheEntries.parentNodeId,
      );

  HistoryWithEntity _readRow(TypedResult row) => (
        visit: row.readTable(historyEntries),
        entity: row.readTable(entityCacheEntries),
      );

  Stream<List<HistoryWithEntity>> watchFiltered({
    EntityTypeFilter? entityType,
    HistoryTimeRange? timeRange,
    bool bookmarkedOnly = false,
    String? searchQuery,
    String? parentPath,
    int limit = 500,
    int offset = 0,
  }) {
    final joinQuery = select(historyEntries).join([
      innerJoin(
        entityCacheEntries,
        entityCacheEntries.nodeId.equalsExp(historyEntries.nodeId),
      ),
    ]);
    var where = historyEntries.accountKey.equals(accountKey);
    where = withEntityFilters(where,
        entityType: entityType, parentPath: parentPath);
    if (timeRange != null) {
      where = where &
          historyEntries.visitedAt.isBiggerOrEqualValue(timeRange.since);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      where = where & entityCacheEntries.snapshotTitle.likeEscaped(searchQuery);
    }
    if (bookmarkedOnly) {
      where = where &
          whereBookmarked(
            accountKey: accountKey,
            matching: (bookmark) =>
                bookmark.nodeId.equalsExp(historyEntries.nodeId),
          );
    }
    joinQuery
      ..where(where)
      ..orderBy([OrderingTerm.desc(historyEntries.visitedAt)])
      ..limit(limit, offset: offset);
    return joinQuery.watch().map((rows) => rows.map(_readRow).toList());
  }

  Stream<bool> watchWasVisited(String nodeId) => (select(historyEntries)
        ..where((e) => forEntity(nodeId))
        ..limit(1))
      .watch()
      .map((rows) => rows.isNotEmpty);

  static const int _watchForNodeIdLimit = 100;

  Stream<List<HistoryEntry>> watchForNodeId(String nodeId) =>
      (select(historyEntries)
            ..where((e) => forEntity(nodeId))
            ..orderBy([(e) => OrderingTerm.desc(e.visitedAt)])
            ..limit(_watchForNodeIdLimit))
          .watch();

  /// History for entities with the given path (join entity cache).
  Stream<List<HistoryWithEntity>> watchForEntityPath(
    String entityPath, {
    int limit = 500,
    int offset = 0,
  }) {
    final joinQuery = select(historyEntries).join([
      innerJoin(
        entityCacheEntries,
        entityCacheEntries.nodeId.equalsExp(historyEntries.nodeId),
      ),
    ]);
    joinQuery
      ..where(historyEntries.accountKey.equals(accountKey) &
          entityCacheEntries.entityPath.equals(entityPath))
      ..orderBy([OrderingTerm.desc(historyEntries.visitedAt)])
      ..limit(limit, offset: offset);
    return joinQuery.watch().map((rows) => rows.map(_readRow).toList());
  }

  Future<int> record({required String nodeId}) => into(historyEntries)
      .insertOnConflictUpdate(HistoryEntriesCompanion(
        accountKey: Value(accountKey),
        nodeId: Value(nodeId),
        visitedAt: Value(DateTime.now()),
      ));

  Future<int> count() async {
    final c = historyEntries.nodeId.count();
    final q = selectOnly(historyEntries)
      ..addColumns([c])
      ..where(accountScopeExpr());
    return await q.map((r) => r.read(c)!).getSingle();
  }

  /// Returns all history entries for the current account. For cloud sync export.
  Future<List<HistoryEntry>> getAllRaw() => (select(historyEntries)
        ..where((e) => accountScope(e.accountKey))
        ..orderBy([(e) => OrderingTerm.desc(e.visitedAt)]))
      .get();

  /// Replaces all history entries with the given entries (transactional). For cloud sync import.
  Future<void> replaceAll(List<HistoryEntriesCompanion> entries) =>
      transaction(() async {
        await (delete(historyEntries)..where((e) => accountScope(e.accountKey)))
            .go();
        if (entries.isNotEmpty) {
          await batch((b) => b.insertAll(historyEntries, entries));
        }
      });
}
