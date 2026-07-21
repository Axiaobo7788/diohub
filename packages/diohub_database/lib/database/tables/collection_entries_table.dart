import 'package:drift/drift.dart';

import '../mixins/account_scoped_columns.dart';
// Drift resolves custom-constraint table names from imports during codegen.
// ignore: unused_import
import 'accounts_table.dart';

/// A bookmark collection (folder / GitHub List).
/// Supports flat lists, nested folders (parentId), and GitHub Lists sync (remoteId).
@TableIndex(name: 'idx_collection_account', columns: {#accountKey})
class CollectionEntries extends Table with AccountScopedColumns {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get parentId => text().nullable()();
  TextColumn get remoteId => text().nullable()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {accountKey, id};
}
