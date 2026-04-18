import 'package:drift/drift.dart';

/// Universal entity preview fields — SQL-filterable across all entity types
/// and all forges. Mixed into EntityCacheEntries.
///
/// These 8 columns cover the filtering/sorting that every forge needs:
/// sort by title, filter by state, filter by author, sort by updatedAt,
/// filter private/public. Forge-specific sort fields (stars, reviewDecision)
/// live on per-entity-type extension tables.
mixin CommonSnapshotColumns on Table {
  TextColumn get snapshotTitle => text().nullable()();
  TextColumn get snapshotState => text().nullable()();
  TextColumn get snapshotStateReason => text().nullable()();
  TextColumn get snapshotAuthorLogin => text().nullable()();
  TextColumn get snapshotAuthorAvatarUrl => text().nullable()();
  BoolColumn get snapshotIsPrivate => boolean().nullable()();
  IntColumn get snapshotCommentCount => integer().nullable()();
  DateTimeColumn get snapshotUpdatedAt => dateTime().nullable()();
}
