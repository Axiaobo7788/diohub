import 'package:drift/drift.dart';

import 'entity_cache_entries_table.dart';

/// PR/MR-specific sort/filter data. Forge-agnostic: all forges' PR/MR columns live here.
@TableIndex(name: 'idx_pr_snap_node', columns: {#nodeId})
class PRSnapshotEntries extends Table {
  TextColumn get nodeId => text().references(
        EntityCacheEntries,
        #nodeId,
        onDelete: KeyAction.cascade,
      )();

  BoolColumn get isDraft => boolean().nullable()();
  TextColumn get reviewDecision => text().nullable()();
  TextColumn get labelsJson => text().nullable()();
  TextColumn get milestone => text().nullable()();

  @override
  Set<Column> get primaryKey => {nodeId};
}
