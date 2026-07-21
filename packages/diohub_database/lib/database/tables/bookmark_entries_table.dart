import 'package:drift/drift.dart';

import '../mixins/account_scoped_columns.dart';
// Drift resolves custom-constraint table names from imports during codegen.
// ignore: unused_import
import 'accounts_table.dart';
import 'entity_cache_entries_table.dart';

/// A bookmark — the user's intent to remember an entity.
/// Thin relationship table: only bookmark-specific data. Entity data from EntityCache JOIN.
@TableIndex(name: 'idx_bookmark_account_node', columns: {#accountKey, #nodeId})
class BookmarkEntries extends Table with AccountScopedColumns {
  TextColumn get nodeId => text().references(
    EntityCacheEntries,
    #nodeId,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get label => text().nullable()();
  TextColumn get collectionId => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {accountKey, nodeId};
}
