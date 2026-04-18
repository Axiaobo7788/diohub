part of '../database.dart';

@DriftAccessor(tables: [
  RepoSnapshotEntries,
  IssueSnapshotEntries,
  PRSnapshotEntries,
])
class SnapshotDao extends DatabaseAccessor<AppDatabase>
    with _$SnapshotDaoMixin {
  SnapshotDao(super.attachedDatabase);

  Future<void> upsertRepoSnapshot(RepoSnapshotEntriesCompanion entry) =>
      into(repoSnapshotEntries).insertOnConflictUpdate(entry);

  Future<void> upsertIssueSnapshot(IssueSnapshotEntriesCompanion entry) =>
      into(issueSnapshotEntries).insertOnConflictUpdate(entry);

  Future<void> upsertPRSnapshot(PRSnapshotEntriesCompanion entry) =>
      into(pRSnapshotEntries).insertOnConflictUpdate(entry);

  Future<void> upsertForEntity({
    required String nodeId,
    required String entityType,
    int? stars,
    String? language,
    String? languageColor,
    bool? isFork,
    bool? isArchived,
    bool? isDraft,
    String? reviewDecision,
    String? labelsJson,
    String? milestone,
  }) async {
    final type = EntityTypeFilter.tryParse(entityType);
    switch (type) {
      case EntityTypeFilter.repo:
        await upsertRepoSnapshot(RepoSnapshotEntriesCompanion(
          nodeId: Value(nodeId),
          stars: Value.ofNullable(stars),
          language: Value.ofNullable(language),
          languageColor: Value.ofNullable(languageColor),
          isFork: Value.ofNullable(isFork),
          isArchived: Value.ofNullable(isArchived),
        ));
        break;
      case EntityTypeFilter.issue:
        await upsertIssueSnapshot(IssueSnapshotEntriesCompanion(
          nodeId: Value(nodeId),
          labelsJson: Value.ofNullable(labelsJson),
          milestone: Value.ofNullable(milestone),
        ));
        break;
      case EntityTypeFilter.pr:
        await upsertPRSnapshot(PRSnapshotEntriesCompanion(
          nodeId: Value(nodeId),
          isDraft: Value.ofNullable(isDraft),
          reviewDecision: Value.ofNullable(reviewDecision),
          labelsJson: Value.ofNullable(labelsJson),
          milestone: Value.ofNullable(milestone),
        ));
        break;
      case null:
      default:
        break;
    }
  }
}
