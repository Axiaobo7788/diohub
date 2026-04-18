part of '../database.dart';

const int logViewerLimit = 500;

@DriftAccessor(tables: [LogEntries, EntityCacheEntries])
class LogDao extends DatabaseAccessor<AppDatabase>
    with _$LogDaoMixin, BookmarkLookup {
  LogDao(super.db);

  Future<int> insert(LogEntriesCompanion entry) =>
      into(logEntries).insert(entry);

  Future<void> insertBatch(List<LogEntriesCompanion> entries) =>
      batch((b) => b.insertAll(logEntries, entries));

  Stream<List<LogEntry>> watchFiltered({
    LogLevel? level,
    String? tag,
    String? entityPath,
    EntityTypeFilter? entityType,
    int? httpStatusCode,
    String? searchQuery,
    DateTime? since,
    bool bookmarkedOnly = false,
    String? bookmarkedOnlyAccountKey,
    int limit = logViewerLimit,
    int offset = 0,
  }) {
    Expression<bool>? where;

    if (level != null) {
      where = (where ?? Constant(true)) & logEntries.level.equals(level.dbValue);
    }
    if (tag != null) {
      where = (where ?? Constant(true)) & logEntries.tag.equals(tag);
    }
    if (entityPath != null) {
      where = (where ?? Constant(true)) &
          (logEntries.entityPath.equals(entityPath) |
              logEntries.parentPath.equals(entityPath));
    }
    if (entityType != null) {
      where = (where ?? Constant(true)) & logEntries.entityType.equals(entityType.dbValue);
    }
    if (httpStatusCode != null) {
      where = (where ?? Constant(true)) & logEntries.httpStatusCode.equals(httpStatusCode);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      where = (where ?? Constant(true)) & logEntries.message.likeEscaped(searchQuery);
    }
    if (since != null) {
      where = (where ?? Constant(true)) & logEntries.createdAt.isBiggerOrEqualValue(since);
    }

    if (bookmarkedOnly && bookmarkedOnlyAccountKey != null) {
      return _watchBookmarkedOnly(
        where ?? Constant(true),
        bookmarkedOnlyAccountKey,
        limit,
        offset,
      );
    }

    final query = select(logEntries);
    if (where != null) {
      query.where((e) => where!);
    }
    query
      ..orderBy([(e) => OrderingTerm.desc(logEntries.createdAt)])
      ..limit(limit, offset: offset);
    return query.watch();
  }

  Stream<List<LogEntry>> _watchBookmarkedOnly(
    Expression<bool> where,
    String accountKey,
    int limit,
    int offset,
  ) {
    final ec = attachedDatabase.entityCacheEntries;
    final joinQuery = select(logEntries).join([
      innerJoin(
        ec,
        logEntries.entityPath.equalsExp(ec.entityPath) |
            logEntries.nodeId.equalsExp(ec.nodeId),
      ),
    ]);
    final existsBookmark = whereBookmarked(
      accountKey: accountKey,
      matching: (bookmark) => bookmark.nodeId.equalsExp(ec.nodeId),
    );
    joinQuery
      ..where(where &
          (logEntries.entityPath.isNotNull() | logEntries.nodeId.isNotNull()) &
          existsBookmark)
      ..orderBy([OrderingTerm.desc(logEntries.createdAt)])
      ..limit(limit, offset: offset);
    return joinQuery
        .watch()
        .map((rows) => rows.map((r) => r.readTable(logEntries)).toList());
  }

  Future<int> countRecentErrors(
      {Duration window = const Duration(hours: 24)}) async {
    final since = DateTime.now().subtract(window);
    final c = logEntries.id.count();
    final q = selectOnly(logEntries)
      ..addColumns([c])
      ..where(logEntries.level.equals(LogLevel.error.dbValue) &
          logEntries.createdAt.isBiggerOrEqualValue(since));
    return q.map((r) => r.read(c)!).getSingle();
  }

  Future<int> countAll() async {
    final c = logEntries.id.count();
    final q = selectOnly(logEntries)..addColumns([c]);
    return q.map((r) => r.read(c)!).getSingle();
  }

  Future<int> deleteOlderThan(Duration maxAge) {
    final cutoff = DateTime.now().subtract(maxAge);
    return (delete(logEntries)
          ..where((e) => e.createdAt.isSmallerThanValue(cutoff)))
        .go();
  }

  Future<int> deleteOldest(int n) async {
    if (n <= 0) return 0;
    final subquery = select(logEntries)
      ..orderBy([(e) => OrderingTerm.asc(e.createdAt)])
      ..limit(n);
    final ids = await subquery.map((r) => r.id).get();
    if (ids.isEmpty) return 0;
    return (delete(logEntries)..where((e) => e.id.isIn(ids))).go();
  }

  Future<int> deleteAll() => delete(logEntries).go();
}
