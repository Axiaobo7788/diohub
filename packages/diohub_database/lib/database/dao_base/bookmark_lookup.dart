part of '../database.dart';

/// Mixin providing a reusable "is this entity bookmarked?" EXISTS subquery.
///
/// Mix into any DAO that needs to filter results by bookmark status.
/// Currently used by: HistoryDao, DownloadHistoryDao, LogDao.
///
/// Example:
/// ```dart
/// final exists = whereBookmarked(
///   accountKey: accountKey,
///   matching: (bookmark) =>
///       bookmark.nodeId.equalsExp(historyEntries.nodeId),
/// );
/// ```
mixin BookmarkLookup on DatabaseAccessor<AppDatabase> {
  /// Builds: EXISTS (SELECT nodeId FROM bookmark_entries AS bkmk
  ///   WHERE accountKey = ? AND [matching])
  ///
  /// [matching] receives the bookmark table reference and returns the
  /// column correlation — how the outer query's rows relate to bookmarks.
  ///
  /// Always aliases the bookmark table to 'bkmk' — harmless for cross-table
  /// queries, and avoids surprises if the mixin is ever used in a context
  /// where the outer query also touches bookmark_entries.
  Expression<bool> whereBookmarked({
    required String accountKey,
    required Expression<bool> Function($BookmarkEntriesTable bookmark) matching,
  }) {
    final bookmark = alias(attachedDatabase.bookmarkEntries, 'bkmk');
    return existsQuery(
      selectOnly(bookmark)
        ..addColumns([bookmark.nodeId])
        ..where(
          bookmark.accountKey.equals(accountKey) & matching(bookmark),
        ),
    );
  }
}
