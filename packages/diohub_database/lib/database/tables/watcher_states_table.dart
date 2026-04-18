import 'package:drift/drift.dart';

import '../mixins/account_scoped_columns.dart';
import 'entity_cache_entries_table.dart';

/// Watcher KV state — background polling state for an entity.
/// Thin: only watcher type + key-value pair. Entity info from EntityCache JOIN.
@TableIndex(name: 'idx_watcher_account_node', columns: {#accountKey, #nodeId})
@TableIndex(
    name: 'idx_watcher_account_watcher', columns: {#accountKey, #watcherType})
class WatcherStateEntries extends Table with AccountScopedColumns {
  TextColumn get nodeId => text().references(
        EntityCacheEntries,
        #nodeId,
        onDelete: KeyAction.restrict,
      )();
  TextColumn get watcherType => text()();
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {accountKey, nodeId, watcherType, key};
}
