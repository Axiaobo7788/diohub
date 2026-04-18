/// Per-entity-type snapshot data. Pattern-matched in UI widgets.
/// Forge-agnostic — each subclass represents an entity type, not a forge.
sealed class EntityTypeSnapshot {
  const EntityTypeSnapshot();
}

class RepoSnapshot extends EntityTypeSnapshot {
  const RepoSnapshot({
    this.stars,
    this.language,
    this.languageColor,
    this.isFork,
    this.isArchived,
  });
  final int? stars;
  final String? language;
  final String? languageColor;
  final bool? isFork;
  final bool? isArchived;
}

class IssueSnapshot extends EntityTypeSnapshot {
  const IssueSnapshot({this.labelsJson, this.milestone});
  final String? labelsJson;
  final String? milestone;
}

class PRSnapshot extends EntityTypeSnapshot {
  const PRSnapshot({
    this.isDraft,
    this.reviewDecision,
    this.labelsJson,
    this.milestone,
  });
  final bool? isDraft;
  final String? reviewDecision;
  final String? labelsJson;
  final String? milestone;
}
