part of '../database.dart';

/// Base for DAOs that are scoped to a single account (accountKey only).
/// No entity-column requirement — use for DraftsDao, WatcherDao, DownloadHistoryDao.
abstract class AccountScopedDao extends DatabaseAccessor<AppDatabase> {
  AccountScopedDao(AppDatabase attachedDatabase, [this.accountKey = ''])
      : super(attachedDatabase);

  /// The account key this DAO is scoped to.
  /// Format: "serverId/nodeId" — matches ActiveAccountKeyProvider.
  final String accountKey;

  /// WHERE [col] = accountKey. Pass the table's accountKey column.
  Expression<bool> accountScope(GeneratedColumn<String> col) =>
      col.equals(accountKey);
}

/// Extends [AccountScopedDao] with entity-level filtering for DAOs that JOIN
/// EntityCacheEntries. Requires [columns] (entityPath, entityType, parentPath, etc.).
/// Use for BookmarkDao, HistoryDao.
abstract class AccountDao extends AccountScopedDao {
  AccountDao(AppDatabase attachedDatabase, [String accountKey = ''])
      : super(attachedDatabase, accountKey);

  /// Column references for entity columns (from EntityCacheEntries via JOIN).
  /// Subclasses override to point to their JOIN's entity cache columns.
  EntityColumns get columns;

  /// WHERE accountKey = ? (convenience using [columns]). Use in queries.
  Expression<bool> accountScopeExpr() => super.accountScope(columns.accountKey);

  /// WHERE accountKey = ? AND nodeId = ?
  Expression<bool> forEntity(String nodeId) =>
      super.accountScope(columns.accountKey) & columns.nodeId.equals(nodeId);

  /// Applies optional entity-level filters shared across all entity-referencing
  /// DAOs. Subclasses call this in their watchFiltered(), then AND on
  /// domain-specific predicates (state, timeRange, etc.).
  Expression<bool> withEntityFilters(
    Expression<bool> where, {
    EntityTypeFilter? entityType,
    String? parentPath,
  }) {
    var w = where;
    if (entityType != null) {
      w = w & columns.entityType.equals(entityType.dbValue);
    }
    if (parentPath != null) {
      w = w & columns.parentPath.equals(parentPath);
    }
    return w;
  }
}
