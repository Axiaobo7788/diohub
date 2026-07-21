import 'package:drift/drift.dart';

import '../mixins/account_scoped_columns.dart';
// Drift resolves custom-constraint table names from imports during codegen.
// ignore: unused_import
import 'accounts_table.dart';
import 'entity_cache_entries_table.dart';

/// A visit record — the user navigated to this entity's screen.
/// Thin relationship table. Entity display data from EntityCache JOIN.
@TableIndex(
  name: 'idx_history_account_visited',
  columns: {#accountKey, #visitedAt},
)
@TableIndex(name: 'idx_history_account_node', columns: {#accountKey, #nodeId})
class HistoryEntries extends Table with AccountScopedColumns {
  TextColumn get nodeId => text().references(
    EntityCacheEntries,
    #nodeId,
    onDelete: KeyAction.restrict,
  )();
  DateTimeColumn get visitedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {accountKey, nodeId};
}
