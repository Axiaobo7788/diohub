import 'package:drift/drift.dart';

/// Per-tab search state (sort, filter, query, qualifiers).
class SearchStateEntries extends Table {
  TextColumn get tabKey => text()();
  TextColumn get sort => text().nullable()();
  TextColumn get filterStringsJson => text().nullable()();
  TextColumn get qualifierStringsJson => text().nullable()();
  TextColumn get query => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {tabKey};
}
