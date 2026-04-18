/// Configuration for how a search context (e.g. list + toolbar) is presented.
///
/// Passed to [SearchScrollWrapper] instead of separate hero tag, quick filters,
/// and quick options. The wrapper generates the Hero tag internally.
class SearchContextConfig {
  const SearchContextConfig({
    this.quickFilterLabels = const <String, String>{},
    this.quickOptionLabels,
  });

  /// Map from filter key to display label for quick filter dropdown.
  final Map<String, String> quickFilterLabels;

  /// Optional map from option key to display label for quick option checkboxes.
  final Map<String, String>? quickOptionLabels;
}
