import 'package:fuzzywuzzy/fuzzywuzzy.dart' as fw;

/// Strategy for matching a query against a text value.
sealed class MatchStrategy {
  const MatchStrategy();

  /// Returns true if [text] matches [query].
  /// Both [text] and [query] are already lowercased.
  bool matches(String text, String query);
}

/// Exact substring matching (current behavior).
/// "flut" matches "flutter", "fltr" does not.
class SubstringMatch extends MatchStrategy {
  const SubstringMatch();

  @override
  bool matches(String text, String query) => text.contains(query);
}

/// Fuzzy matching using Levenshtein-based partial ratio.
/// "fltr" can match "flutter" if score >= [threshold].
class FuzzyMatch extends MatchStrategy {
  const FuzzyMatch({this.threshold = 70});

  /// Minimum fuzzywuzzy partialRatio score (0–100) to consider a match.
  final int threshold;

  @override
  bool matches(String text, String query) {
    // Short-circuit: exact substring is always a match.
    if (text.contains(query)) return true;
    // Only fuzzy-match when the query is long enough to be meaningful.
    if (query.length < 2) return false;
    return fw.partialRatio(query, text) >= threshold;
  }
}
