import 'package:diohub_models/models/search/qualifier.dart';
import 'package:diohub/models/search/quick_filter.dart';
import 'package:diohub_models/models/search/search_expression.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub_models/models/search/sort_config.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_state.freezed.dart';

/// Immutable search state (replaces legacy SearchData).
///
/// Uses a redirecting factory so Freezed can generate [copyWith].
/// The currently selected search type (e.g. Issues vs Pulls) is held per-scope
/// in [selectedSearchTypeProvider], not in this state.
@freezed
abstract class SearchState with _$SearchState {
  const SearchState._();

  factory SearchState({
    required SearchScope scope,
    @Default('') String freeText,
    @Default([]) List<QualifierExpression> activeQualifiers,
    SortOption? sort,
  }) = _SearchState;

  /// Full query sent to GitHub API.
  String get apiQuery {
    final parts = <String>[
      ...scope.hiddenQualifiers.map((q) => q.toQueryString()),
      ...activeQualifiers.map((q) => q.toQueryFragment()),
      if (freeText.isNotEmpty) freeText,
      if (sort != null && !sort!.isBestMatch) 'sort:${sort!.key}',
    ];
    return parts.join(' ').trim();
  }

  /// User-visible query (no hidden qualifiers).
  String get displayQuery {
    final parts = <String>[
      ...activeQualifiers.map((q) => q.toQueryFragment()),
      if (freeText.isNotEmpty) freeText,
      if (sort != null && !sort!.isBestMatch) 'sort:${sort!.key}',
    ];
    return parts.join(' ').trim();
  }

  bool get isActive =>
      freeText.isNotEmpty ||
      activeQualifiers.isNotEmpty ||
      (sort != null && !sort!.isBestMatch);

  QuickFilter? get activeQuickFilter {
    for (final qf in scope.quickFilters) {
      if (activeQualifiers.any((q) => q == qf.qualifier)) return qf;
    }
    return null;
  }

  List<String> activeQualifierValues(String key) {
    final List<String> values = <String>[];
    for (final QualifierExpression q in activeQualifiers) {
      final String s = q.qualifier.toQueryString();
      final String qKey = s.contains(':') ? s.substring(0, s.indexOf(':')) : s;
      if (qKey == key && s.contains(':')) {
        values.add(s.substring(s.indexOf(':') + 1));
      }
    }
    return values;
  }

  SearchState get cleared => SearchState(scope: scope);

  SearchState withQuickFilter(QuickFilter filter) {
    final keyQualifier = filter.qualifier.qualifier;
    final others = activeQualifiers
        .where((q) => !_sameQualifierKey(q.qualifier, keyQualifier))
        .toList();
    return copyWith(activeQualifiers: [...others, filter.qualifier]);
  }

  SearchState withQuickOption(QuickOption option, {required bool enabled}) {
    if (enabled) {
      final others = activeQualifiers
          .where((q) => q.qualifier != option.qualifier.qualifier)
          .toList();
      return copyWith(activeQualifiers: [...others, option.qualifier]);
    }
    return copyWith(
      activeQualifiers: activeQualifiers
          .where((q) => q.qualifier != option.qualifier.qualifier)
          .toList(),
    );
  }

  static bool _sameQualifierKey(Qualifier a, Qualifier b) {
    final sa = a.toQueryString();
    final sb = b.toQueryString();
    final ka = sa.contains(':') ? sa.substring(0, sa.indexOf(':')) : sa;
    final kb = sb.contains(':') ? sb.substring(0, sb.indexOf(':')) : sb;
    return ka == kb;
  }
}
