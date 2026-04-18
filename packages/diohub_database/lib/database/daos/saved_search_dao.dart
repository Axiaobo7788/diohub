part of '../database.dart';

@DriftAccessor(tables: [SavedSearchEntries])
class SavedSearchDao extends AccountScopedDao
    with _$SavedSearchDaoMixin {
  SavedSearchDao(super.attachedDatabase, [super.accountKey = '']);

  Stream<List<SavedSearchEntry>> watchAll({
    int limit = 500,
    int offset = 0,
  }) =>
      (select(savedSearchEntries)
            ..where((e) => accountScope(e.accountKey))
            ..orderBy([(e) => OrderingTerm.desc(e.savedAt)])
            ..limit(limit, offset: offset))
          .watch();

  /// Saves a search. Normalizes query (trim+lowercase) before insert
  /// to prevent duplicates from whitespace/case differences.
  Future<int> save({
    required String query,
    String? label,
    String? searchType,
  }) {
    final normalized = query.trim().toLowerCase();
    return into(savedSearchEntries).insertOnConflictUpdate(
      SavedSearchEntriesCompanion(
        accountKey: Value(accountKey),
        query: Value(normalized),
        label: Value.ofNullable(label),
        searchType: Value.ofNullable(searchType),
        savedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> remove(String query) => (delete(savedSearchEntries)
        ..where((e) =>
            accountScope(e.accountKey) &
            e.query.equals(query.trim().toLowerCase())))
      .go();

  Future<int> count() async {
    final c = savedSearchEntries.query.count();
    final q = selectOnly(savedSearchEntries)
      ..addColumns([c])
      ..where(accountScope(savedSearchEntries.accountKey));
    return await q.map((r) => r.read(c)!).getSingle();
  }

  /// Returns all saved searches for the current account. For cloud sync export.
  Future<List<SavedSearchEntry>> getAll() => (select(savedSearchEntries)
        ..where((e) => accountScope(e.accountKey))
        ..orderBy([(e) => OrderingTerm.desc(e.savedAt)]))
      .get();

  /// Replaces all saved searches with the given entries (transactional). For cloud sync import.
  Future<void> replaceAll(List<SavedSearchEntriesCompanion> entries) =>
      transaction(() async {
        await (delete(savedSearchEntries)
              ..where((e) => accountScope(e.accountKey)))
            .go();
        if (entries.isNotEmpty) {
          await batch((b) => b.insertAll(savedSearchEntries, entries));
        }
      });
}
