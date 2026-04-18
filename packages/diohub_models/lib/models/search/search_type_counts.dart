/// Which global search type a count refers to (for parsing GQL responses).
enum SearchCountKind { repositories, issues, users, discussions }

/// Counts per search type for global search (repos, issues, users, discussions).
/// Parsed from GQL search response; updated incrementally as each type's search completes.
class SearchTypeCounts {
  const SearchTypeCounts({
    this.repositories,
    this.issues,
    this.users,
    this.discussions,
  });

  final int? repositories;
  final int? issues;
  final int? users;
  final int? discussions;

  /// Parse from a single search response and merge into [current].
  /// [rawData] is the full GQL data map (e.g. { "search": { "repositoryCount": 123, ... } }).
  /// [whichCount] identifies which type this response is for.
  static SearchTypeCounts mergeFromResponse(
    SearchTypeCounts? current,
    Map<String, dynamic>? rawData,
    SearchCountKind whichCount,
  ) {
    if (rawData == null) return current ?? const SearchTypeCounts();
    final search = rawData['search'];
    if (search is! Map<String, dynamic>) return current ?? const SearchTypeCounts();
    final int? value = _readCount(search, whichCount);
    if (value == null) return current ?? const SearchTypeCounts();
    return SearchTypeCounts(
      repositories: whichCount == SearchCountKind.repositories ? value : current?.repositories,
      issues: whichCount == SearchCountKind.issues ? value : current?.issues,
      users: whichCount == SearchCountKind.users ? value : current?.users,
      discussions: whichCount == SearchCountKind.discussions ? value : current?.discussions,
    );
  }

  static int? _readCount(Map<String, dynamic> search, SearchCountKind kind) {
    final v = switch (kind) {
      SearchCountKind.repositories => search['repositoryCount'],
      SearchCountKind.issues => search['issueCount'],
      SearchCountKind.users => search['userCount'],
      SearchCountKind.discussions => search['discussionCount'],
    };
    if (v is int) return v;
    return null;
  }
}
