part of '../database.dart';

@DriftAccessor(tables: [DraftEntries])
class DraftsDao extends AccountScopedDao with _$DraftsDaoMixin {
  DraftsDao(super.attachedDatabase, [super.accountKey = '']);

  Stream<String?> watchDraft(String nodeId, DraftScope scope) =>
      (select(draftEntries)
            ..where((d) =>
                accountScope(d.accountKey) &
                d.nodeId.equals(nodeId) &
                d.scope.equals(scope.dbValue)))
          .watchSingleOrNull()
          .map((row) => row?.body);

  Future<String?> getDraft(String nodeId, DraftScope scope) =>
      (select(draftEntries)
            ..where((d) =>
                accountScope(d.accountKey) &
                d.nodeId.equals(nodeId) &
                d.scope.equals(scope.dbValue)))
          .getSingleOrNull()
          .then((row) => row?.body);

  Stream<bool> watchHasDraft(String nodeId) => (select(draftEntries)
        ..where((d) => accountScope(d.accountKey) & d.nodeId.equals(nodeId))
        ..limit(1))
      .watch()
      .map((rows) => rows.isNotEmpty);

  Future<void> saveDraft({
    required String nodeId,
    required DraftScope scope,
    required String body,
  }) =>
      into(draftEntries).insertOnConflictUpdate(DraftEntriesCompanion(
        accountKey: Value(accountKey),
        nodeId: Value(nodeId),
        scope: Value(scope.dbValue),
        body: Value(body),
        updatedAt: Value(DateTime.now()),
      ));

  Future<void> deleteDraft(
          String nodeId, DraftScope scope) =>
      (delete(draftEntries)
            ..where((d) =>
                accountScope(d.accountKey) &
                d.nodeId.equals(nodeId) &
                d.scope.equals(scope.dbValue)))
          .go();

  Future<int> countForEntity(String nodeId) async {
    final c = draftEntries.nodeId.count();
    final q = selectOnly(draftEntries)
      ..addColumns([c])
      ..where(accountScope(draftEntries.accountKey) &
          draftEntries.nodeId.equals(nodeId));
    return q.map((r) => r.read(c)!).getSingle();
  }

  Stream<int> watchCountForEntity(String nodeId) {
    final c = draftEntries.nodeId.count();
    final q = selectOnly(draftEntries)
      ..addColumns([c])
      ..where(accountScope(draftEntries.accountKey) &
          draftEntries.nodeId.equals(nodeId));
    return q.watch().map((rows) => rows.isEmpty ? 0 : (rows.first.read(c) ?? 0));
  }

  /// Returns all drafts for the current account. For cloud sync export.
  Future<List<DraftEntry>> getAll() =>
      (select(draftEntries)..where((d) => accountScope(d.accountKey))).get();

  /// Replaces all drafts with the given entries (transactional). For cloud sync import.
  Future<void> replaceAll(List<DraftEntriesCompanion> entries) =>
      transaction(() async {
        await (delete(draftEntries)..where((d) => accountScope(d.accountKey)))
            .go();
        if (entries.isNotEmpty) {
          await batch((b) => b.insertAll(draftEntries, entries));
        }
      });
}
