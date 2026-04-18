part of '../database.dart';

@DriftAccessor(tables: [
  BookmarkEntries,
  EntityCacheEntries,
  RepoSnapshotEntries,
  IssueSnapshotEntries,
  PRSnapshotEntries,
  DraftEntries,
  DownloadHistoryEntries,
])
class BookmarkDao extends AccountDao with _$BookmarkDaoMixin, BookmarkLookup {
  BookmarkDao(super.attachedDatabase, [super.accountKey = '']);

  @override
  EntityColumns get columns => (
        accountKey: bookmarkEntries.accountKey,
        nodeId: entityCacheEntries.nodeId,
        entityPath: entityCacheEntries.entityPath,
        entityType: entityCacheEntries.entityType,
        parentPath: entityCacheEntries.parentPath,
        parentNodeId: entityCacheEntries.parentNodeId,
      );

  JoinedSelectStatement<HasResultSet, dynamic> _baseJoin({
    String? entityTypeFilter,
  }) {
    final type = EntityTypeFilter.tryParse(entityTypeFilter);
    final joins = <Join<HasResultSet, dynamic>>[
      innerJoin(
        entityCacheEntries,
        entityCacheEntries.nodeId.equalsExp(bookmarkEntries.nodeId),
      ),
      if (type == EntityTypeFilter.repo)
        leftOuterJoin(
          repoSnapshotEntries,
          repoSnapshotEntries.nodeId.equalsExp(bookmarkEntries.nodeId),
        ),
      if (type == EntityTypeFilter.issue)
        leftOuterJoin(
          issueSnapshotEntries,
          issueSnapshotEntries.nodeId.equalsExp(bookmarkEntries.nodeId),
        ),
      if (type == EntityTypeFilter.pr)
        leftOuterJoin(
          pRSnapshotEntries,
          pRSnapshotEntries.nodeId.equalsExp(bookmarkEntries.nodeId),
        ),
    ];
    return select(bookmarkEntries).join(joins);
  }

  BookmarkWithEntity _readRow(TypedResult row, {String? entityTypeFilter}) {
    final bookmark = row.readTable(bookmarkEntries);
    final entity = row.readTable(entityCacheEntries);
    final type =
        EntityTypeFilter.tryParse(entityTypeFilter ?? entity.entityType);
    EntityTypeSnapshot? snapshot;
    switch (type) {
      case EntityTypeFilter.repo:
        final s = row.readTableOrNull(repoSnapshotEntries);
        if (s != null) {
          snapshot = RepoSnapshot(
            stars: s.stars,
            language: s.language,
            languageColor: s.languageColor,
            isFork: s.isFork,
            isArchived: s.isArchived,
          );
        }
        break;
      case EntityTypeFilter.issue:
        final s = row.readTableOrNull(issueSnapshotEntries);
        if (s != null) {
          snapshot = IssueSnapshot(
            labelsJson: s.labelsJson,
            milestone: s.milestone,
          );
        }
        break;
      case EntityTypeFilter.pr:
        final s = row.readTableOrNull(pRSnapshotEntries);
        if (s != null) {
          snapshot = PRSnapshot(
            isDraft: s.isDraft,
            reviewDecision: s.reviewDecision,
            labelsJson: s.labelsJson,
            milestone: s.milestone,
          );
        }
        break;
      case null:
      default:
        break;
    }
    return (bookmark: bookmark, entity: entity, snapshot: snapshot);
  }

  OrderingTerm _orderTerm(BookmarkOrder order, bool descending) {
    final mode = descending ? OrderingMode.desc : OrderingMode.asc;
    return switch (order) {
      BookmarkOrder.newest => OrderingTerm(
          expression: bookmarkEntries.createdAt,
          mode: mode,
        ),
      BookmarkOrder.stars => OrderingTerm(
          expression: repoSnapshotEntries.stars,
          mode: mode,
        ),
      BookmarkOrder.updated => OrderingTerm(
          expression: entityCacheEntries.snapshotUpdatedAt,
          mode: mode,
        ),
      BookmarkOrder.alpha => OrderingTerm(
          expression: entityCacheEntries.snapshotTitle,
          mode: mode,
        ),
    };
  }

  /// When sorting by stars we need the repo extension join.
  String? _entityTypeFilterForJoin(
      EntityTypeFilter? entityType, BookmarkOrder order) {
    if (entityType != null) return entityType.dbValue;
    if (order == BookmarkOrder.stars) return 'repo';
    return null;
  }

  Stream<List<BookmarkWithEntity>> watchAll({
    int limit = 500,
    int offset = 0,
  }) {
    final query = _baseJoin()
      ..where(bookmarkEntries.accountKey.equals(accountKey))
      ..orderBy([OrderingTerm.desc(bookmarkEntries.createdAt)])
      ..limit(limit, offset: offset);
    return query.watch().map((rows) => rows.map((r) => _readRow(r)).toList());
  }

  Stream<List<BookmarkWithEntity>> watchScoped(
    String? collectionId, {
    int limit = 500,
    int offset = 0,
  }) {
    final query = _baseJoin()
      ..where(bookmarkEntries.accountKey.equals(accountKey) &
          (collectionId == null
              ? bookmarkEntries.collectionId.isNull()
              : bookmarkEntries.collectionId.equals(collectionId)))
      ..orderBy([
        OrderingTerm.asc(bookmarkEntries.sortOrder),
        OrderingTerm.desc(bookmarkEntries.createdAt),
      ])
      ..limit(limit, offset: offset);
    return query.watch().map((rows) => rows.map((r) => _readRow(r)).toList());
  }

  Stream<bool> watchIsBookmarked(String nodeId) => (select(bookmarkEntries)
        ..where((e) => forEntity(nodeId))
        ..limit(1))
      .watch()
      .map((rows) => rows.isNotEmpty);

  Stream<List<BookmarkWithEntity>> watchFiltered({
    EntityTypeFilter? entityType,
    EntityState? state,
    BookmarkOrder order = BookmarkOrder.newest,
    bool descending = true,
    String? searchQuery,
    String? parentPath,
    String? collectionId,
    bool hasDrafts = false,
    bool hasDownloads = false,
    int limit = 500,
    int offset = 0,
  }) {
    final etFilter = _entityTypeFilterForJoin(entityType, order);
    var where = bookmarkEntries.accountKey.equals(accountKey);
    
    final joins = <Join<HasResultSet, dynamic>>[
      innerJoin(
        entityCacheEntries,
        entityCacheEntries.nodeId.equalsExp(bookmarkEntries.nodeId),
      ),
      if (etFilter == 'repo')
        leftOuterJoin(
          repoSnapshotEntries,
          repoSnapshotEntries.nodeId.equalsExp(bookmarkEntries.nodeId),
        ),
      if (etFilter == 'issue')
        leftOuterJoin(
          issueSnapshotEntries,
          issueSnapshotEntries.nodeId.equalsExp(bookmarkEntries.nodeId),
        ),
      if (etFilter == 'pr')
        leftOuterJoin(
          pRSnapshotEntries,
          pRSnapshotEntries.nodeId.equalsExp(bookmarkEntries.nodeId),
        ),
      if (hasDrafts)
        innerJoin(
          draftEntries,
          draftEntries.nodeId.equalsExp(bookmarkEntries.nodeId) &
              draftEntries.accountKey.equalsExp(bookmarkEntries.accountKey),
        ),
      if (hasDownloads)
        innerJoin(
          downloadHistoryEntries,
          downloadHistoryEntries.nodeId.equalsExp(bookmarkEntries.nodeId) &
              downloadHistoryEntries.accountKey
                  .equalsExp(bookmarkEntries.accountKey),
        ),
    ];
    
    where = withEntityFilters(
      where,
      entityType: entityType,
      parentPath: parentPath,
    );
    if (state != null) {
      where = where & entityCacheEntries.snapshotState.equals(state.dbValue);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      where = where &
          (entityCacheEntries.snapshotTitle.likeEscaped(searchQuery) |
              bookmarkEntries.label.likeEscaped(searchQuery));
    }
    if (collectionId != null) {
      where = where & bookmarkEntries.collectionId.equals(collectionId);
    }
    
    final query = select(bookmarkEntries).join(joins);
    query
      ..where(where)
      ..orderBy([_orderTerm(order, descending)])
      ..limit(limit, offset: offset);
    return query.watch().map((rows) =>
        rows.map((r) => _readRow(r, entityTypeFilter: etFilter)).toList());
  }

  Future<void> add({
    required String nodeId,
    String? label,
    String? collectionId,
  }) =>
      into(bookmarkEntries).insertOnConflictUpdate(BookmarkEntriesCompanion(
        accountKey: Value(accountKey),
        nodeId: Value(nodeId),
        label: Value.ofNullable(label),
        collectionId: Value.ofNullable(collectionId),
        sortOrder: const Value(0),
        createdAt: Value(DateTime.now()),
      ));

  Future<int> remove(String nodeId) =>
      (delete(bookmarkEntries)..where((e) => forEntity(nodeId))).go();

  Future<void> moveToCollection(String nodeId, String? collectionId) =>
      (update(bookmarkEntries)..where((e) => forEntity(nodeId)))
          .write(BookmarkEntriesCompanion(collectionId: Value(collectionId)));

  Future<int> count() async {
    final c = bookmarkEntries.nodeId.count();
    final q = selectOnly(bookmarkEntries)
      ..addColumns([c])
      ..where(accountScopeExpr());
    return await q.map((r) => r.read(c)!).getSingle();
  }

  /// Returns raw bookmark rows for the current account. For cloud sync export.
  Future<List<BookmarkEntry>> getAllRaw() =>
      (select(bookmarkEntries)..where((b) => accountScope(b.accountKey))).get();

  /// Replaces all bookmarks with the given entries (transactional). For cloud sync import.
  Future<void> replaceAll(List<BookmarkEntriesCompanion> entries) =>
      transaction(() async {
        await (delete(bookmarkEntries)
              ..where((b) => accountScope(b.accountKey)))
            .go();
        if (entries.isNotEmpty) {
          await batch((b) => b.insertAll(bookmarkEntries, entries));
        }
      });
}
