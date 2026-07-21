import 'package:drift/drift.dart';

/// Shared column for any table scoped to a user account.
/// Mixed into tables that isolate data per account.
/// References the account key so that ON DELETE CASCADE applies when an account is removed.
mixin AccountScopedColumns on Table {
  TextColumn get accountKey => text().customConstraint(
    'NOT NULL REFERENCES account_entries ("key") ON DELETE CASCADE',
  )();
}
