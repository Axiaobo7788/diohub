import 'package:drift/drift.dart';

import 'entity_cache_entries_table.dart';

/// Issue-specific sort/filter data. labelsJson stores a JSON array of
/// {name, color} objects. Forge-agnostic: all forges' issue columns live here.
@TableIndex(name: 'idx_issue_snap_node', columns: {#nodeId})
class IssueSnapshotEntries extends Table {
  TextColumn get nodeId => text().references(
        EntityCacheEntries,
        #nodeId,
        onDelete: KeyAction.cascade,
      )();

  TextColumn get labelsJson => text().nullable()();
  TextColumn get milestone => text().nullable()();

  @override
  Set<Column> get primaryKey => {nodeId};
}
