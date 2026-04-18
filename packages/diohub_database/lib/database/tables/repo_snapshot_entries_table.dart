import 'package:drift/drift.dart';

import 'entity_cache_entries_table.dart';

/// Repo-specific sort/filter data. Exists only for entities with entityType = 'repo'.
/// JOINed to EntityCacheEntries for bookmark/history list display.
///
/// All columns are sort-worthy or filter-worthy. Forge-agnostic: all forges'
/// repo columns live here as nullable. Adding a forge = ALTER TABLE ADD COLUMN.
@TableIndex(name: 'idx_repo_snap_node', columns: {#nodeId})
class RepoSnapshotEntries extends Table {
  TextColumn get nodeId => text().references(
        EntityCacheEntries,
        #nodeId,
        onDelete: KeyAction.cascade,
      )();

  IntColumn get stars => integer().nullable()();
  TextColumn get language => text().nullable()();
  TextColumn get languageColor => text().nullable()();
  BoolColumn get isFork => boolean().nullable()();
  BoolColumn get isArchived => boolean().nullable()();

  @override
  Set<Column> get primaryKey => {nodeId};
}
