import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:diohub/app/app_logger.dart';
import 'package:diohub_database/database/database.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/entity_snapshot.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mutation-only notifier — reads go through stream providers.
/// Limit checking, snapshot capture, and ref validation live here.
/// Upserts EntityCache + optional snapshot before bookmark/history writes.
class EntityStoreMutator {
  EntityStoreMutator(
    this._db,
    this._bookmarkDao,
    this._historyDao,
    this._savedSearchDao,
  );
  final AppDatabase _db;
  final BookmarkDao _bookmarkDao;
  final HistoryDao _historyDao;
  final SavedSearchDao _savedSearchDao;

  /// Toggle a bookmark. Returns true if now bookmarked.
  /// Requires [subject.nodeId] to be set (e.g. from GraphQL/REST).
  Future<bool> toggleBookmark(
    EntityRef subject, {
    EntityRef? context,
    String? label,
    EntitySnapshot? snapshot,
    String? collectionId,
  }) async {
    final nodeId = subject.nodeId;
    if (nodeId == null || nodeId.isEmpty) {
      AppLogger.scopedInfo(
        'Cannot bookmark: nodeId not set',
        subject,
        tag: 'EntityStore',
      );
      return false;
    }
    final deleted = await _bookmarkDao.remove(nodeId);
    if (deleted > 0) {
      AppLogger.scopedInfo('Bookmark removed', subject, tag: 'EntityStore');
      return false;
    }

    await _db.transaction(() async {
      await _db.entityCacheDao.upsert(_buildCacheEntry(subject, snapshot));
      await _upsertSnapshot(subject, snapshot);
      await _bookmarkDao.add(
        nodeId: nodeId,
        label: label,
        collectionId: collectionId,
      );
    });
    AppLogger.scopedInfo('Bookmarked', subject, tag: 'EntityStore');
    return true;
  }

  /// Record a history visit.
  /// Requires [subject.nodeId] to be set.
  Future<void> recordVisit(
    EntityRef subject, {
    EntitySnapshot? snapshot,
  }) async {
    if (subject.nodeId == null || subject.nodeId!.isEmpty) return;
    await _db.transaction(() async {
      await _db.entityCacheDao.upsert(_buildCacheEntry(subject, snapshot));
      await _upsertSnapshot(subject, snapshot);
      await _historyDao.record(nodeId: subject.nodeId!);
    });
    AppLogger.scopedInfo('Visit recorded', subject, tag: 'EntityStore');
  }

  EntityCacheEntriesCompanion _buildCacheEntry(
    EntityRef subject,
    EntitySnapshot? snapshot,
  ) {
    var c = EntityCacheEntriesCompanion(
      nodeId: Value(subject.nodeId!),
      entityPath: Value(subject.apiPath),
      entityType: Value(subject.dbType),
      parentPath: Value.absentIfNull(subject.parentPath),
      parentNodeId: Value.absentIfNull(subject.parentNodeId),
      subjectJson: Value(jsonEncode(subject.toJson())),
    );
    if (snapshot != null) {
      c = c.copyWith(
        snapshotTitle: Value(snapshot.title),
        snapshotState: Value(snapshot.state),
        snapshotStateReason: Value(snapshot.stateReason),
        snapshotAuthorLogin: Value(snapshot.authorLogin),
        snapshotAuthorAvatarUrl: Value(snapshot.authorAvatarUrl),
        snapshotIsPrivate: Value(snapshot.isPrivate),
        snapshotCommentCount: Value(snapshot.commentCount),
        snapshotUpdatedAt: Value(snapshot.updatedAt),
      );
    }
    return c;
  }

  Future<void> _upsertSnapshot(
    EntityRef subject,
    EntitySnapshot? snapshot,
  ) async {
    final nodeId = subject.nodeId!;
    if (snapshot == null) return;
    await _db.snapshotDao.upsertForEntity(
      nodeId: nodeId,
      entityType: subject.dbType,
      stars: snapshot.stars,
      language: snapshot.language,
      languageColor: snapshot.languageColor,
      isFork: snapshot.isFork,
      isArchived: snapshot.isArchived,
      isDraft: snapshot.isDraft,
      reviewDecision: snapshot.reviewDecision,
      labelsJson: snapshot.labels != null
          ? jsonEncode(snapshot.labels!.map((l) => l.toJson()).toList())
          : null,
      milestone: snapshot.milestone,
    );
  }

  /// Save a search. Query is normalized (trim+lowercase) to avoid duplicates.
  Future<void> saveSearch({
    required String query,
    String? label,
    String? searchType,
  }) async {
    await _savedSearchDao.save(
      query: query,
      label: label ?? query,
      searchType: searchType,
    );
  }

  /// Remove a saved search by its query string.
  Future<int> deleteSavedSearch(String query) => _savedSearchDao.remove(query);
}

/// Provider for the mutator. Injects database and DAOs.
final entityStoreMutatorProvider = Provider<EntityStoreMutator>(
  (ref) => EntityStoreMutator(
    ref.watch(databaseProvider),
    ref.watch(bookmarkDaoProvider),
    ref.watch(historyDaoProvider),
    ref.watch(savedSearchDaoProvider),
  ),
);
