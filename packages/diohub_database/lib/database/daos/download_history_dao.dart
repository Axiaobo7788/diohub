part of '../database.dart';

@DriftAccessor(tables: [DownloadHistoryEntries, EntityCacheEntries])
class DownloadHistoryDao extends AccountScopedDao
    with _$DownloadHistoryDaoMixin, BookmarkLookup {
  DownloadHistoryDao(super.attachedDatabase, [super.accountKey = '']);

  Expression<bool> _base() => accountScope(downloadHistoryEntries.accountKey);

  OrderingTerm _orderTerm(DownloadOrder order) => switch (order) {
        DownloadOrder.newest =>
          OrderingTerm.desc(downloadHistoryEntries.createdAt),
        DownloadOrder.oldest =>
          OrderingTerm.asc(downloadHistoryEntries.createdAt),
        DownloadOrder.largest =>
          OrderingTerm.desc(downloadHistoryEntries.totalBytes),
      };

  DownloadWithEntity _readRow(TypedResult row) => (
        download: row.readTable(downloadHistoryEntries),
        entity: row.readTable(entityCacheEntries),
      );

  Stream<List<DownloadWithEntity>> watchFiltered({
    DownloadState? state,
    DownloadType? downloadType,
    String? parentPath,
    DownloadOrder order = DownloadOrder.newest,
    bool bookmarkedReposOnly = false,
    String? searchQuery,
    int limit = 500,
    int offset = 0,
  }) {
    if (bookmarkedReposOnly) {
      return _watchBookmarkedRepoDownloads(
        state: state,
        downloadType: downloadType,
        order: order,
        searchQuery: searchQuery,
        limit: limit,
        offset: offset,
      );
    }

    var where = _base();
    if (state != null) {
      where = where & downloadHistoryEntries.state.equals(state.dbValue);
    }
    if (downloadType != null) {
      where =
          where & downloadHistoryEntries.downloadType.equals(downloadType.name);
    }
    if (parentPath != null) {
      where = where & entityCacheEntries.parentPath.equals(parentPath);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      where = where &
          (downloadHistoryEntries.displayName.likeEscaped(searchQuery) |
              downloadHistoryEntries.fileName.likeEscaped(searchQuery) |
              entityCacheEntries.snapshotTitle.likeEscaped(searchQuery));
    }
    
    final joinQuery = select(downloadHistoryEntries).join([
      innerJoin(
        entityCacheEntries,
        entityCacheEntries.nodeId.equalsExp(downloadHistoryEntries.nodeId),
      ),
    ]);
    joinQuery
      ..where(where)
      ..orderBy([_orderTerm(order)])
      ..limit(limit, offset: offset);
    return joinQuery.watch().map((rows) => rows.map(_readRow).toList());
  }

  Stream<List<DownloadWithEntity>> _watchBookmarkedRepoDownloads({
    DownloadState? state,
    DownloadType? downloadType,
    DownloadOrder order = DownloadOrder.newest,
    String? searchQuery,
    int limit = 500,
    int offset = 0,
  }) {
    var where = _base();
    if (state != null) {
      where = where & downloadHistoryEntries.state.equals(state.dbValue);
    }
    if (downloadType != null) {
      where =
          where & downloadHistoryEntries.downloadType.equals(downloadType.name);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      where = where &
          (downloadHistoryEntries.displayName.likeEscaped(searchQuery) |
              downloadHistoryEntries.fileName.likeEscaped(searchQuery));
    }

    final existsBookmark = whereBookmarked(
      accountKey: accountKey,
      matching: (bookmark) =>
          bookmark.nodeId.equalsExp(downloadHistoryEntries.nodeId) |
          bookmark.nodeId.equalsExp(entityCacheEntries.parentNodeId),
    );

    final joinQuery = select(downloadHistoryEntries).join([
      innerJoin(
        entityCacheEntries,
        entityCacheEntries.nodeId.equalsExp(downloadHistoryEntries.nodeId),
      ),
    ]);
    joinQuery
      ..where(where & existsBookmark)
      ..orderBy([_orderTerm(order)])
      ..limit(limit, offset: offset);
    return joinQuery.watch().map((rows) => rows.map(_readRow).toList());
  }

  static const int _watchForNodeIdLimit = 100;

  Stream<List<DownloadHistoryEntry>> watchForNodeId(String nodeId) =>
      (select(downloadHistoryEntries)
            ..where((d) => _base() & d.nodeId.equals(nodeId))
            ..orderBy([(d) => OrderingTerm.desc(d.createdAt)])
            ..limit(_watchForNodeIdLimit))
          .watch();

  Future<void> upsert(DownloadHistoryEntriesCompanion entry) =>
      into(downloadHistoryEntries).insert(
        entry,
        onConflict: DoUpdate(
          (old) => entry,
          target: [
            downloadHistoryEntries.accountKey,
            downloadHistoryEntries.downloadId,
          ],
        ),
      );

  Future<int> countForEntity(String nodeId) async {
    final c = downloadHistoryEntries.id.count();
    final q = selectOnly(downloadHistoryEntries)
      ..addColumns([c])
      ..where(_base() & downloadHistoryEntries.nodeId.equals(nodeId));
    return q.map((r) => r.read(c)!).getSingle();
  }

  Stream<int> watchCountForEntity(String nodeId) {
    final c = downloadHistoryEntries.id.count();
    final q = selectOnly(downloadHistoryEntries)
      ..addColumns([c])
      ..where(_base() & downloadHistoryEntries.nodeId.equals(nodeId));
    return q.watch().map((rows) => rows.isEmpty ? 0 : (rows.first.read(c) ?? 0));
  }

  Future<void> deleteCompleted() => (delete(downloadHistoryEntries)
        ..where(
            (d) => _base() & d.state.equals(DownloadState.completed.dbValue)))
      .go();

  Future<void> deleteByDownloadId(String downloadId) =>
      (delete(downloadHistoryEntries)
            ..where((d) => _base() & d.downloadId.equals(downloadId)))
          .go();
}
