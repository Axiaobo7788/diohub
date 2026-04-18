import 'package:drift/drift.dart';

import '../mixins/common_snapshot_columns.dart';
import '../mixins/entity_ref_columns.dart';

/// Central cache of entity data fetched from the API.
///
/// One row per "known" entity; entity data is global (not per-account).
/// Relationship tables (bookmark, history, draft, download, watcher) FK here
/// via [nodeId] only. This is the single source of truth for entity display
/// data; when the API returns fresh data, this table is updated once and
/// all views reactively pick up the change via .watch() JOINs.
@TableIndex(name: 'idx_cache_node', columns: {#nodeId})
class EntityCacheEntries extends Table
    with EntityRefColumns, CommonSnapshotColumns {
  // From EntityRefColumns: nodeId, entityPath, entityType, parentPath, parentNodeId
  // From CommonSnapshotColumns: snapshotTitle, snapshotState, snapshotStateReason,
  //   snapshotAuthorLogin, snapshotAuthorAvatarUrl, snapshotIsPrivate,
  //   snapshotCommentCount, snapshotUpdatedAt

  /// Full EntityRef JSON — used to reconstruct the typed EntityRef (RepoRef,
  /// IssueRef, etc.) for navigation without an API call.
  TextColumn get subjectJson => text()();

  @override
  Set<Column> get primaryKey => {nodeId};
}
