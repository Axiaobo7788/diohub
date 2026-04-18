import 'package:drift/drift.dart';

import '../mixins/account_scoped_columns.dart';
import 'entity_cache_entries_table.dart';

/// A download record — file-level metadata + state. Uses nodeId FK to EntityCache.
@TableIndex(name: 'idx_download_account_node', columns: {#accountKey, #nodeId})
@TableIndex(name: 'idx_download_account_state', columns: {#accountKey, #state})
class DownloadHistoryEntries extends Table with AccountScopedColumns {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nodeId => text().references(
        EntityCacheEntries,
        #nodeId,
        onDelete: KeyAction.restrict,
      )();
  TextColumn get downloadId => text()();
  TextColumn get displayName => text()();
  TextColumn get fileName => text()();
  TextColumn get downloadUrl => text()();
  TextColumn get filePath => text().nullable()();
  IntColumn get totalBytes => integer().nullable()();
  TextColumn get state => text()();
  TextColumn get downloadType => text()();
  TextColumn get contentType => text().nullable()();
  TextColumn get metadataJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {accountKey, downloadId}
      ];
}
