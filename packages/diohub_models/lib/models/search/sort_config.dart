/// A single sort option (e.g. "stars-desc", "created-asc", "best").
class SortOption {
  const SortOption({required this.key, required this.displayName});
  final String key;
  final String displayName;
  bool get isBestMatch => key == 'best';
}

/// Sort options for a search type (issues, repos, etc.).
class SortConfig {
  const SortConfig(this.options);
  final List<SortOption> options;
  SortOption get defaultSort => options.first;

  /// Map of sort key to display name for chip options.
  Map<String, String> get asMap =>
      {for (final o in options) o.key: o.displayName};
}
