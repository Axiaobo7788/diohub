import 'package:drift/drift.dart';

/// Shared columns for any table that references a GitHub entity.
/// Provides nodeId (immutable identity), entityPath (cached, refreshable),
/// entityType (filter discriminator), and parent references.
///
/// NOTE: All columns are NOT NULL. Do NOT use this mixin for tables where
/// entity references are optional (e.g., LogEntries). Declare those
/// columns directly as nullable.
mixin EntityRefColumns on Table {
  TextColumn get nodeId => text()();
  TextColumn get entityPath => text()();
  TextColumn get entityType => text()();
  TextColumn get parentPath => text().nullable()();
  TextColumn get parentNodeId => text().nullable()();
}
