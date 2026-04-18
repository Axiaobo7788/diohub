/// Entity store entry type.
enum EntityType {
  repo,
  issue,
  pull,
  user,
  discussion;

  factory EntityType.fromString(String value) {
    final v = value.toLowerCase();
    if (v == 'repo' || v == 'repository') return EntityType.repo;
    if (v == 'issue') return EntityType.issue;
    if (v == 'pull' || v == 'pullrequest') return EntityType.pull;
    if (v == 'user') return EntityType.user;
    if (v == 'discussion') return EntityType.discussion;
    return EntityType.repo;
  }

  String get displayName => switch (this) {
    EntityType.repo => 'Repository',
    EntityType.issue => 'Issue',
    EntityType.pull => 'Pull Request',
    EntityType.user => 'User',
    EntityType.discussion => 'Discussion',
  };
}
