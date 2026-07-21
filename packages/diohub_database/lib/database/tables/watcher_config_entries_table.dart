import 'package:drift/drift.dart';

import '../mixins/account_scoped_columns.dart';
// Drift resolves custom-constraint table names from imports during codegen.
// ignore: unused_import
import 'accounts_table.dart';

/// Account-scoped watcher config serialization for background tasks.
/// No FK to entity cache; stores free-form watcherId (e.g. inbox_poll:default).
class WatcherConfigEntries extends Table with AccountScopedColumns {
  TextColumn get watcherId => text()();
  TextColumn get watcherType => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {accountKey, watcherId};
}
