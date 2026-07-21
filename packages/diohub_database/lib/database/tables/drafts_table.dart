import 'package:drift/drift.dart';

import '../mixins/account_scoped_columns.dart';
// Drift resolves custom-constraint table names from imports during codegen.
// ignore: unused_import
import 'accounts_table.dart';
import 'entity_cache_entries_table.dart';

/// A draft — the user's unsaved work on an entity.
/// Thin: only body + scope. Entity info from EntityCache JOIN.
@TableIndex(name: 'idx_draft_account_node', columns: {#accountKey, #nodeId})
class DraftEntries extends Table with AccountScopedColumns {
  TextColumn get nodeId => text().references(
    EntityCacheEntries,
    #nodeId,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get scope => text()();
  TextColumn get body => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {accountKey, nodeId, scope};
}
