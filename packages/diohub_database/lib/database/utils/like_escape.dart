import 'package:drift/drift.dart';

/// Escapes SQL LIKE wildcards so the string is treated as a literal match.
/// Used by all DAO text search predicates.
extension LikeEscape on String {
  String escapeLike() =>
      replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');
}

/// Builds a LIKE predicate with proper wildcard escaping.
/// `column.likeEscaped(query)` generates `column LIKE '%query%' ESCAPE '\'`.
extension ColumnLikeX on Expression<String> {
  Expression<bool> likeEscaped(String query) =>
      like('%${query.escapeLike()}%', escapeChar: r'\');
}
