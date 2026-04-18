import 'package:diohub/common/search/match_strategy.dart';

/// Reusable engine for matching items against a text query.
///
/// [fields] extract searchable text from each item.
/// [strategy] controls how matching works (substring vs fuzzy).
///
/// Usage:
/// ```dart
/// final matcher = ClientTextMatcher<User>(
///   fields: [(u) => u.login, (u) => u.name],
///   strategy: const SubstringMatch(),
/// );
/// final matches = matcher.matches(user, 'alice'); // true if any field matches
/// final filtered = matcher.filter(users, 'alice'); // list of matching users
/// ```
class ClientTextMatcher<T> {
  const ClientTextMatcher({
    required this.fields,
    this.strategy = const SubstringMatch(),
  });

  /// Functions that extract searchable text from an item.
  /// Return null for a field that should be skipped (e.g., optional name).
  final List<String? Function(T item)> fields;

  /// Matching strategy (substring or fuzzy).
  final MatchStrategy strategy;

  /// Returns true if any [fields] value of [item] matches [query].
  bool matches(T item, String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    for (final extractor in fields) {
      final String? value = extractor(item);
      if (value == null || value.isEmpty) continue;
      if (strategy.matches(value.toLowerCase(), q)) return true;
    }
    return false;
  }

  /// Returns items from [source] where any field matches [query].
  List<T> filter(List<T> source, String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source.where((T item) => matches(item, q)).toList();
  }

  /// Creates a `clientFilter`-compatible callback for [SliverListBody].
  bool Function(T item, String query) toClientFilter() =>
      (T item, String query) => matches(item, query);
}
