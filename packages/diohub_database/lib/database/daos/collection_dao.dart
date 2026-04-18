part of '../database.dart';

@DriftAccessor(tables: [CollectionEntries, BookmarkEntries])
class CollectionDao extends AccountScopedDao
    with _$CollectionDaoMixin {
  CollectionDao(super.attachedDatabase, [super.accountKey = '']);

  Stream<List<CollectionEntry>> watchAll({
    int limit = 500,
    int offset = 0,
  }) =>
      (select(collectionEntries)
            ..where((c) => accountScope(c.accountKey))
            ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)])
            ..limit(limit, offset: offset))
          .watch();

  Stream<List<CollectionEntry>> watchChildren(
    String? parentId, {
    int limit = 500,
    int offset = 0,
  }) =>
      (select(collectionEntries)
            ..where((c) =>
                accountScope(c.accountKey) &
                (parentId == null
                    ? c.parentId.isNull()
                    : c.parentId.equals(parentId)))
            ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)])
            ..limit(limit, offset: offset))
          .watch();

  Stream<List<CollectionEntry>> watchRoots({
    int limit = 500,
    int offset = 0,
  }) =>
      (select(collectionEntries)
            ..where(
                (c) => accountScope(c.accountKey) & c.parentId.isNull())
            ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)])
            ..limit(limit, offset: offset))
          .watch();

  Future<void> create(CollectionEntriesCompanion entry) =>
      into(collectionEntries).insert(entry);

  Future<void> rename(String id, String newName) => (update(collectionEntries)
        ..where((c) => accountScope(c.accountKey) & c.id.equals(id)))
      .write(CollectionEntriesCompanion(name: Value(newName)));

  Future<void> move(String id, String? newParentId) =>
      (update(collectionEntries)
            ..where((c) => accountScope(c.accountKey) & c.id.equals(id)))
          .write(CollectionEntriesCompanion(parentId: Value(newParentId)));

  Future<void> remove(String id) => transaction(() async {
        final collection = await (select(collectionEntries)
              ..where((c) => accountScope(c.accountKey) & c.id.equals(id)))
            .getSingleOrNull();
        if (collection == null) return;

        await (update(bookmarkEntries)
              ..where((b) =>
                  accountScope(b.accountKey) & b.collectionId.equals(id)))
            .write(const BookmarkEntriesCompanion(collectionId: Value(null)));

        await (update(collectionEntries)
              ..where((c) =>
                  accountScope(c.accountKey) & c.parentId.equals(id)))
            .write(CollectionEntriesCompanion(
                parentId: Value(collection.parentId)));

        await (delete(collectionEntries)
              ..where((c) => accountScope(c.accountKey) & c.id.equals(id)))
            .go();
      });

  Stream<Map<String?, int>> watchBookmarkCounts() {
    final collId = bookmarkEntries.collectionId;
    final cnt = bookmarkEntries.nodeId.count();
    final q = selectOnly(bookmarkEntries)
      ..addColumns([collId, cnt])
      ..where(accountScope(bookmarkEntries.accountKey))
      ..groupBy([collId]);
    return q.watch().map((rows) {
      final map = <String?, int>{};
      for (final r in rows) {
        map[r.read(collId)] = r.read(cnt)!;
      }
      return map;
    });
  }

  /// Returns all collections for the current account. For cloud sync export.
  Future<List<CollectionEntry>> getAll() => (select(collectionEntries)
        ..where((c) => accountScope(c.accountKey))
        ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
      .get();

  /// Replaces all collections with the given entries (transactional). For cloud sync import.
  /// Clears bookmarks' collectionId for this account before replacing collections.
  Future<void> replaceAll(List<CollectionEntriesCompanion> entries) =>
      transaction(() async {
        await (update(bookmarkEntries)
              ..where((b) => accountScope(b.accountKey)))
            .write(const BookmarkEntriesCompanion(collectionId: Value(null)));
        await (delete(collectionEntries)
              ..where((c) => accountScope(c.accountKey)))
            .go();
        if (entries.isNotEmpty) {
          await batch((b) => b.insertAll(collectionEntries, entries));
        }
      });
}
