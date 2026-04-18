import 'dart:convert';

import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/riverpod/keep_alive_helper.dart';
import 'package:diohub_database/database/database.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/database_types.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/utils/json_decode_safe.dart';
import 'package:diohub/providers/browsing/history_filter_providers.dart';
import 'package:diohub/providers/filter_state_providers.dart';
import 'package:diohub/providers/notifier_update_extension.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Precomputed bookmark index from a single watchAll() stream.
class BookmarkStore {
  const BookmarkStore({
    required this.all,
    required this.byId,
    required this.byPath,
    required this.byCollection,
  });

  final List<BookmarkWithEntity> all;
  final Map<String, BookmarkWithEntity> byId;
  final Map<String, List<BookmarkWithEntity>> byPath;
  final Map<String?, List<BookmarkWithEntity>> byCollection;
}

/// Single stream for all bookmarks; derived providers read from this.
final bookmarkStoreProvider = StreamProvider<BookmarkStore>((ref) {
  final dao = ref.watch(bookmarkDaoProvider);
  return dao.watchAll().map((list) {
    final byId = <String, BookmarkWithEntity>{};
    final byPath = <String, List<BookmarkWithEntity>>{};
    final byCollection = <String?, List<BookmarkWithEntity>>{};
    for (final b in list) {
      byId[b.entity.nodeId] = b;
      final path = b.entity.parentPath ?? '';
      byPath.putIfAbsent(path, () => []).add(b);
      final cid = b.bookmark.collectionId;
      byCollection.putIfAbsent(cid, () => []).add(b);
    }
    return BookmarkStore(
      all: list,
      byId: byId,
      byPath: byPath,
      byCollection: byCollection,
    );
  });
});

/// All bookmarks (from store).
final allBookmarksProvider = Provider<AsyncValue<List<BookmarkWithEntity>>>(
  (ref) => ref.watch(bookmarkStoreProvider).whenData((s) => s.all),
);

/// Whether a specific entity is bookmarked. Key is [nodeId].
final isBookmarkedProvider = Provider.family<AsyncValue<bool>, String>((
  ref,
  nodeId,
) {
  return ref
      .watch(bookmarkStoreProvider)
      .whenData((s) => s.byId[nodeId] != null);
});

/// Entity cache for a node (for card display: subject, title, path). Key is [nodeId].
final entityCacheForNodeProvider = StreamProvider.autoDispose
    .family<EntityCacheEntry?, String>((ref, nodeId) {
      keepAliveFor(ref);
      final db = ref.watch(databaseProvider);
      return db.entityCacheDao.watch(nodeId);
    });

/// Bookmarks scoped to a parent entity (e.g. within a repo).
final scopedBookmarksProvider =
    Provider.family<AsyncValue<List<BookmarkWithEntity>>, String>(
      (ref, parentPath) => ref
          .watch(bookmarkStoreProvider)
          .whenData((s) => s.byPath[parentPath] ?? []),
    );

/// Bookmarks in a collection. Pass null for uncategorized.
final collectionBookmarksProvider =
    Provider.family<AsyncValue<List<BookmarkWithEntity>>, String?>(
      (ref, collectionId) => ref
          .watch(bookmarkStoreProvider)
          .whenData((s) => s.byCollection[collectionId] ?? []),
    );

/// Precomputed history index from a single watchFiltered() stream (no filter).
class HistoryStore {
  const HistoryStore({
    required this.all,
    required this.byPath,
    required this.byEntityPath,
  });

  final List<HistoryWithEntity> all;
  final Map<String, List<HistoryWithEntity>> byPath;
  final Map<String, List<HistoryWithEntity>> byEntityPath;
}

final historyStoreProvider = StreamProvider<HistoryStore>((ref) {
  final dao = ref.watch(historyDaoProvider);
  return dao.watchFiltered().map((list) {
    final byPath = <String, List<HistoryWithEntity>>{};
    final byEntityPath = <String, List<HistoryWithEntity>>{};
    for (final h in list) {
      final path = h.entity.parentPath ?? '';
      byPath.putIfAbsent(path, () => []).add(h);
      final ep = h.entity.entityPath;
      byEntityPath.putIfAbsent(ep, () => []).add(h);
    }
    return HistoryStore(all: list, byPath: byPath, byEntityPath: byEntityPath);
  });
});

/// All history (from store).
final allHistoryProvider = Provider<AsyncValue<List<HistoryWithEntity>>>(
  (ref) => ref.watch(historyStoreProvider).whenData((s) => s.all),
);

/// All saved searches, reactive stream.
final allSavedSearchesProvider = StreamProvider<List<SavedSearchEntry>>(
  (ref) => ref.watch(savedSearchDaoProvider).watchAll(),
);

/// View-safe saved searches for views/common. Maps from [SavedSearchEntry] in one place.
final allSavedSearchesViewSafeProvider =
    StreamProvider<List<ViewSafeSavedSearch>>((ref) {
      return ref
          .watch(allSavedSearchesProvider)
          .when(
            data: (list) => Stream.value(_savedSearchToViewSafe(list)),
            loading: () => const Stream.empty(),
            error: (e, st) => Stream.error(e, st),
          );
    });

List<ViewSafeSavedSearch> _savedSearchToViewSafe(List<SavedSearchEntry> list) {
  return list
      .map((e) => (query: e.query, label: e.label, savedAt: e.savedAt))
      .toList();
}

/// View-safe history list for views/common. Maps from [HistoryWithEntity] in one place.
final allHistoryViewSafeProvider =
    Provider<AsyncValue<List<ViewSafeHistoryEntry>>>((ref) {
      return ref.watch(allHistoryProvider).whenData((list) {
        return list.map(_historyToViewSafe).toList();
      });
    });

ViewSafeHistoryEntry _historyToViewSafe(HistoryWithEntity h) {
  final entity = h.entity;
  final displayTitle = entity.snapshotTitle ?? entity.entityPath;
  EntityRef? entityRef;
  try {
    final json =
        tryDecodeMap(
          entity.subjectJson,
          tag: 'EntityStoreProviders.entitySubjectProvider',
        ) ??
        {};
    entityRef = EntityRef.fromJson(json);
  } on FormatException catch (e) {
    AppLogger.warning(
      'Failed to parse entity JSON for ${entity.entityPath}: $e',
    );
    entityRef = null;
  } on TypeError catch (e) {
    AppLogger.warning(
      'Type error parsing entity JSON for ${entity.entityPath}: $e',
    );
    entityRef = null;
  }
  return (
    nodeId: entity.nodeId,
    displayTitle: displayTitle,
    entityRef: entityRef,
  );
}

/// History scoped to a parent entity.
final scopedHistoryProvider =
    Provider.family<AsyncValue<List<HistoryWithEntity>>, String>(
      (ref, parentPath) => ref
          .watch(historyStoreProvider)
          .whenData((s) => s.byPath[parentPath] ?? []),
    );

/// Saved searches (no parent scope; same as watchAll).
final scopedSavedSearchesProvider =
    Provider.family<AsyncValue<List<SavedSearchEntry>>, String>(
      (ref, _) => ref.watch(allSavedSearchesProvider),
    );

/// History entries for a given entity path.
final storeByEntityPathProvider =
    Provider.family<AsyncValue<List<HistoryWithEntity>>, String>(
      (ref, entityPath) => ref
          .watch(historyStoreProvider)
          .whenData((s) => s.byEntityPath[entityPath] ?? []),
    );

/// Filtered bookmarks. Reads filter state, passes directly to DAO.
final filteredBookmarksProvider = StreamProvider<List<BookmarkWithEntity>>((
  ref,
) {
  final filter = ref.watch(bookmarkFilterProvider);
  return ref
      .watch(bookmarkDaoProvider)
      .watchFiltered(
        entityType: filter.entityType,
        state: filter.state,
        order: filter.order,
        descending: filter.descending,
        searchQuery: filter.searchQuery,
        parentPath: filter.parentPath,
        hasDrafts: filter.hasDrafts,
        hasDownloads: filter.hasDownloads,
      );
});

/// Filtered history. All filtering in SQL.
final filteredHistoryProvider = StreamProvider<List<HistoryWithEntity>>((ref) {
  final filter = ref.watch(historyFilterProvider);
  return ref
      .watch(historyDaoProvider)
      .watchFiltered(
        entityType: filter.entityType,
        timeRange: filter.timeRange,
        bookmarkedOnly: filter.bookmarkedOnly,
        searchQuery: filter.searchQuery,
      );
});

/// Draft count for an entity (reactive). Key is [nodeId].
final draftCountProvider = StreamProvider.autoDispose.family<int, String>((
  ref,
  nodeId,
) {
  keepAliveFor(ref);
  return ref.watch(draftsDaoProvider).watchCountForEntity(nodeId);
});

/// Download count for an entity (reactive). Key is [nodeId].
final downloadCountProvider = StreamProvider.autoDispose.family<int, String>((
  ref,
  nodeId,
) {
  keepAliveFor(ref);
  return ref.watch(downloadHistoryDaoProvider).watchCountForEntity(nodeId);
});

/// Watcher count for an entity (reactive). Key is [nodeId].
final watcherCountProvider = StreamProvider.autoDispose.family<int, String>((
  ref,
  nodeId,
) {
  keepAliveFor(ref);
  return ref.watch(watcherDaoProvider).watchCountForEntity(nodeId);
});

/// Annotation summary for a single entity. Single derivation point for badge UI.
class EntityAnnotationSummary {
  const EntityAnnotationSummary({
    required this.isBookmarked,
    required this.draftCount,
    required this.downloadCount,
    required this.watcherCount,
  });
  final bool isBookmarked;
  final int draftCount;
  final int downloadCount;
  final int watcherCount;
  bool get hasAny =>
      isBookmarked || draftCount > 0 || downloadCount > 0 || watcherCount > 0;
}

/// Single provider for annotation badges; reduces 4 watches per list item to 1.
final entityAnnotationSummaryProvider = Provider.autoDispose
    .family<AsyncValue<EntityAnnotationSummary>, String>((ref, nodeId) {
      keepAliveFor(ref);
      final bookmarked = ref.watch(isBookmarkedProvider(nodeId)).value ?? false;
      final drafts = ref.watch(draftCountProvider(nodeId)).value ?? 0;
      final downloads = ref.watch(downloadCountProvider(nodeId)).value ?? 0;
      final watchers = ref.watch(watcherCountProvider(nodeId)).value ?? 0;
      return AsyncValue.data(
        EntityAnnotationSummary(
          isBookmarked: bookmarked,
          draftCount: drafts,
          downloadCount: downloads,
          watcherCount: watchers,
        ),
      );
    });

/// ValueNotifier for bookmark search pill; updates [bookmarkFilterProvider] when value changes.
final bookmarkSearchQueryNotifierProvider = Provider<ValueNotifier<String>>((
  ref,
) {
  final notifier = ValueNotifier<String>('');
  ref.onDispose(() => notifier.dispose());
  notifier.addListener(() {
    ref
        .read(bookmarkFilterProvider.notifier)
        .update(
          (f) => f.copyWith(
            searchQuery: notifier.value.isEmpty ? null : notifier.value,
          ),
        );
  });
  return notifier;
});

/// ValueNotifier for history search pill; updates [historyFilterProvider] when value changes.
final historySearchQueryNotifierProvider = Provider<ValueNotifier<String>>((
  ref,
) {
  final notifier = ValueNotifier<String>('');
  ref.onDispose(() => notifier.dispose());
  notifier.addListener(() {
    ref
        .read(historyFilterProvider.notifier)
        .update(
          (f) => f.copyWith(
            searchQuery: notifier.value.isEmpty ? null : notifier.value,
          ),
        );
  });
  return notifier;
});
