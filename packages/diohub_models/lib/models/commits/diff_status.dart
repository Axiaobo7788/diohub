enum DiffStatus {
  added,
  removed,
  modified,
  renamed,
  copied,
  changed,
  unchanged;

  static DiffStatus? fromString(String? value) {
    if (value == null) return null;
    return switch (value.toLowerCase()) {
      'added' => DiffStatus.added,
      'removed' => DiffStatus.removed,
      'modified' => DiffStatus.modified,
      'renamed' => DiffStatus.renamed,
      'copied' => DiffStatus.copied,
      'changed' => DiffStatus.changed,
      'unchanged' => DiffStatus.unchanged,
      _ => null,
    };
  }
}
