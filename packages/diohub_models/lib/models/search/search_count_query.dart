import 'package:diohub_models/models/search/qualifier.dart';
import 'package:diohub_models/models/search/search_expression.dart';

/// Mixin for objects that can produce a GitHub search count query string.
///
/// The composed query combines [baseQualifiers] (from the SearchScope —
/// e.g. `type:issue repo:flutter/flutter`) with the filter-specific
/// [filterQualifiers] (e.g. `assignee:naman`) to produce a complete
/// query string suitable for:
///
/// ```graphql
/// search(query: $q, type: ISSUE, first: 0) { issueCount }
/// ```
///
/// No string concatenation at call sites — each filter/qualifier knows
/// how to serialize itself via the existing [Qualifier] model.
mixin SearchCountQueryMixin {
  /// The scope's hidden qualifiers.
  /// Set when this object is bound to a scope via [boundTo].
  List<Qualifier> get baseQualifiers;

  /// This filter's own qualifiers.
  List<QualifierExpression> get filterQualifiers;

  /// Produces the full query string for a zero-cost count search.
  ///
  /// Combines base + filter qualifiers into a single query string.
  String toCountQuery() {
    final parts = <String>[
      ...baseQualifiers.map((q) => q.toQueryString()),
      ...filterQualifiers.map((q) => q.toQueryFragment()),
    ];
    return parts.join(' ').trim();
  }
}
