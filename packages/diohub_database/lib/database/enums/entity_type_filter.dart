/// Entity type discriminator for filter dropdowns.
/// Each value maps to the dbType string stored in DB columns.
/// Adding a new EntityRef subclass without adding it here causes a
/// compile error in any exhaustive switch on this enum.
enum EntityTypeFilter {
  repo('repo', 'Repository'),
  issue('issue', 'Issue'),
  pr('pr', 'Pull Request'),
  commit('commit', 'Commit'),
  release('release', 'Release'),
  workflowRun('workflowRun', 'Workflow Run'),
  discussion('discussion', 'Discussion'),
  wiki('wiki', 'Wiki'),
  codeFile('codeFile', 'Code File'),
  user('user', 'User'),
  topic('topic', 'Topic'),
  package('package', 'Package'),
  issueComment('issueComment', 'Issue Comment'),
  prReviewComment('prReviewComment', 'Review Comment');

  const EntityTypeFilter(this.dbValue, this.displayLabel);

  /// Value stored in DB columns. Matches EntityRef.dbType.
  final String dbValue;

  /// Display label for filter chips.
  final String displayLabel;

  /// Parses a DB value to [EntityTypeFilter], or null if not found.
  static EntityTypeFilter? tryParse(final String? dbValue) {
    if (dbValue == null) return null;
    for (final e in EntityTypeFilter.values) {
      if (e.dbValue == dbValue) return e;
    }
    return null;
  }

  /// Display label for a DB value, or the raw value if not found.
  static String displayLabelFor(final String? dbValue) {
    if (dbValue == null) {
      return 'All';
    }
    for (final e in EntityTypeFilter.values) {
      if (e.dbValue == dbValue) {
        return e.displayLabel;
      }
    }
    return dbValue;
  }
}
