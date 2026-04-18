/// Sort order direction.
enum SortDirection {
  asc,
  desc;

  factory SortDirection.fromString(String value) {
    final v = value.toLowerCase();
    if (v == 'asc' || v == 'ascending') return SortDirection.asc;
    if (v == 'desc' || v == 'descending') return SortDirection.desc;
    return SortDirection.desc;
  }

  String get displayName => switch (this) {
    SortDirection.asc => 'Ascending',
    SortDirection.desc => 'Descending',
  };
}
