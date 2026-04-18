import 'package:diohub_database/database/database.dart';
import 'package:diohub_database/database/enums/enums.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/providers/entity_store_providers.dart';
import 'package:diohub/providers/filter_state_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A group of bookmarks for "By Repo" or "By Type" view.
class BookmarkGroup {
  const BookmarkGroup({
    this.parentPath,
    this.groupKey,
    this.label,
    required this.entries,
    this.isTopLevel = false,
  });

  /// For "By Repo" mode: the parent repo's apiPath.
  final String? parentPath;

  /// For "By Type" mode: the entityType string.
  final String? groupKey;

  /// Display label for the group header.
  final String? label;

  final List<BookmarkWithEntity> entries;

  final bool isTopLevel;

  int get count => entries.length;
}

const List<String> _typeOrder = [
  'repo',
  'issue',
  'pr',
  'commit',
  'release',
  'workflowRun',
  'discussion',
  'wiki',
  'codeFile',
  'user',
  'topic',
];

List<BookmarkGroup> _groupByRepo(List<BookmarkWithEntity> list) {
  final grouped = <String?, List<BookmarkWithEntity>>{};
  for (final entry in list) {
    grouped.putIfAbsent(entry.entity.parentPath, () => []).add(entry);
  }
  final groups = grouped.entries.map((e) {
    final isTopLevel = e.key == null;
    List<BookmarkWithEntity> entries = e.value;
    entries = List.from(entries)
      ..sort((a, b) => b.bookmark.createdAt.compareTo(a.bookmark.createdAt));
    final repoInGroup = entries
        .where((x) =>
            x.entity.entityType == 'repo' &&
            x.entity.parentPath == null &&
            e.key != null &&
            x.entity.entityPath == e.key)
        .toList();
    final rest = entries.where((x) => !repoInGroup.contains(x)).toList();
    entries = [...repoInGroup, ...rest];
    return BookmarkGroup(
      parentPath: e.key,
      label: e.key ?? 'Ungrouped',
      entries: entries,
      isTopLevel: isTopLevel,
    );
  }).toList();
  groups.sort((a, b) {
    if (a.isTopLevel != b.isTopLevel) return a.isTopLevel ? 1 : -1;
    final aFirst =
        a.entries.isNotEmpty ? a.entries.first.bookmark.createdAt : DateTime(0);
    final bFirst =
        b.entries.isNotEmpty ? b.entries.first.bookmark.createdAt : DateTime(0);
    return bFirst.compareTo(aFirst);
  });
  return groups;
}

List<BookmarkGroup> _groupByType(List<BookmarkWithEntity> list) {
  final grouped = <String, List<BookmarkWithEntity>>{};
  for (final entry in list) {
    grouped.putIfAbsent(entry.entity.entityType, () => []).add(entry);
  }
  final sortedEntries = grouped.entries.toList()
    ..sort((a, b) {
      final ai = _typeOrder.indexOf(a.key);
      final bi = _typeOrder.indexOf(b.key);
      return (ai < 0 ? 999 : ai).compareTo(bi < 0 ? 999 : bi);
    });
  return sortedEntries
      .map((e) => BookmarkGroup(
            groupKey: e.key,
            label: EntityTypeFilter.displayLabelFor(e.key),
            entries: List.from(e.value)
              ..sort((a, b) =>
                  b.bookmark.createdAt.compareTo(a.bookmark.createdAt)),
          ))
      .toList();
}

/// Bookmarks grouped by parentPath (for "By Repo" mode).
final bookmarksByRepoProvider = StreamProvider<List<BookmarkGroup>>((ref) {
  final dao = ref.watch(bookmarkDaoProvider);
  final filter = ref.watch(bookmarkFilterProvider);
  return dao
      .watchFiltered(
        entityType: filter.entityType,
        state: filter.state,
        order: filter.order,
        descending: filter.descending,
        searchQuery: filter.searchQuery,
        parentPath: filter.parentPath,
        hasDrafts: filter.hasDrafts,
        hasDownloads: filter.hasDownloads,
      )
      .map(_groupByRepo);
});

/// Bookmarks grouped by entityType (for "By Type" mode).
final bookmarksByTypeProvider = StreamProvider<List<BookmarkGroup>>((ref) {
  final dao = ref.watch(bookmarkDaoProvider);
  final filter = ref.watch(bookmarkFilterProvider);
  return dao
      .watchFiltered(
        entityType: filter.entityType,
        state: filter.state,
        order: filter.order,
        descending: filter.descending,
        searchQuery: filter.searchQuery,
        parentPath: filter.parentPath,
        hasDrafts: filter.hasDrafts,
        hasDownloads: filter.hasDownloads,
      )
      .map(_groupByType);
});
