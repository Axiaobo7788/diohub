/// Discriminator for draft_entries.scope column.
/// Replaces 10 magic string sites across 7 view files.
enum DraftScope {
  comment('comment'),
  review('review'),
  issueBody('issueBody'),
  prBody('prBody'),
  pill('pill');

  const DraftScope(this.dbValue);
  final String dbValue;

  /// Parse from DB/string; returns null if [v] is null or unknown.
  static DraftScope? fromDb(String? v) {
    if (v == null) return null;
    for (final e in DraftScope.values) {
      if (e.dbValue == v) return e;
    }
    return null;
  }
}
