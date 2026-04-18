/// State for issues/PRs in entity_store_entries.snapshot_state.
/// Replaces 8 magic string sites.
enum EntityState {
  open('open'),
  closed('closed'),
  merged('merged');

  const EntityState(this.dbValue);
  final String dbValue;

  String get displayLabel => switch (this) {
        EntityState.open => 'Open',
        EntityState.closed => 'Closed',
        EntityState.merged => 'Merged',
      };

  /// Parse from DB string; returns null if [v] is null or unknown.
  static EntityState? fromDb(String? v) {
    if (v == null) return null;
    for (final e in EntityState.values) {
      if (e.dbValue == v) return e;
    }
    return null;
  }
}
