import 'package:drift/drift.dart';

import '../mixins/account_scoped_columns.dart';
// Drift resolves custom-constraint table names from imports during codegen.
// ignore: unused_import
import 'accounts_table.dart';

/// A saved search query. NOT entity-related (queries, not entities).
@TableIndex(name: 'idx_saved_search_account', columns: {#accountKey})
class SavedSearchEntries extends Table with AccountScopedColumns {
  TextColumn get query => text()();
  TextColumn get label => text().nullable()();
  TextColumn get searchType => text().nullable()();
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {accountKey, query};
}
