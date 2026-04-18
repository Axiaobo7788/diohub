import 'package:drift/drift.dart';

import '../tables/accounts_table.dart';

/// Shared column for any table scoped to a user account.
/// Mixed into tables that isolate data per account.
/// References [AccountEntries.key] so that ON DELETE CASCADE applies when an account is removed.
mixin AccountScopedColumns on Table {
  TextColumn get accountKey =>
      text().references(AccountEntries, #key, onDelete: KeyAction.cascade)();
}
