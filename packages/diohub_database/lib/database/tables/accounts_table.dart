import 'package:drift/drift.dart';

/// Account metadata (non-sensitive).
/// Replaces: SharedPreferences 'accountList' JSON array.
/// [key] is unique and used as FK target by account-scoped tables (format: serverId/nodeId).
@TableIndex(name: 'idx_accounts_node_server', columns: {#nodeId, #serverId})
class AccountEntries extends Table {
  /// Unique key for FK from account-scoped tables. Format: serverId/nodeId.
  TextColumn get key => text().unique()();
  TextColumn get nodeId => text()();
  TextColumn get username => text()();
  TextColumn get displayName => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get serverConfigJson => text()();
  TextColumn get serverId => text()();
  TextColumn get authMethod => text().withDefault(const Constant('oauth'))();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {nodeId, serverId};
}
