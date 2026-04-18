part of '../database.dart';

@DriftAccessor(tables: [SearchStateEntries])
class SearchStateDao extends DatabaseAccessor<AppDatabase>
    with _$SearchStateDaoMixin {
  SearchStateDao(super.db);

  Future<SearchStateEntry?> get(String tabKey) =>
      (select(searchStateEntries)..where((s) => s.tabKey.equals(tabKey)))
          .getSingleOrNull();

  Future<List<SearchStateEntry>> getAll() => select(searchStateEntries).get();

  Stream<SearchStateEntry?> watch(String tabKey) =>
      (select(searchStateEntries)..where((s) => s.tabKey.equals(tabKey)))
          .watchSingleOrNull();

  Stream<List<SearchStateEntry>> watchAll({
    int limit = 500,
    int offset = 0,
  }) =>
      (select(searchStateEntries)..limit(limit, offset: offset)).watch();

  Future<void> upsert(SearchStateEntriesCompanion entry) =>
      into(searchStateEntries).insertOnConflictUpdate(entry);

  Future<void> deleteTab(String tabKey) =>
      (delete(searchStateEntries)..where((s) => s.tabKey.equals(tabKey))).go();

  Future<void> deleteAll() => delete(searchStateEntries).go();
}
