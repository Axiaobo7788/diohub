import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:diohub/common/search_overlay/filters.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/search/qualifier.dart';
import 'package:diohub_models/models/search/search_count_query.dart';
import 'package:diohub_models/models/search/search_expression.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub_models/models/search/sort_config.dart';

part 'custom_filter.freezed.dart';

/// User-saved custom filter with optional repo scope and count-query support.
@Freezed(equal: false)
abstract class CustomFilter with _$CustomFilter, SearchCountQueryMixin {
  const CustomFilter._();

  const factory CustomFilter({
    required String id,
    required String name,
    required SearchType searchType,
    required List<QualifierExpression> qualifiers,
    SortOption? sort,
    String? freeText,
    RepoRef? repoScope,
    required DateTime createdAt,
    @Default([]) List<Qualifier> baseQualifiers,
  }) = _CustomFilter;

  @override
  List<QualifierExpression> get filterQualifiers => qualifiers;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CustomFilter && id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Returns a copy bound to [scope] for count-query generation.
  CustomFilter boundTo(SearchScope scope) =>
      copyWith(baseQualifiers: scope.hiddenQualifiers);

  /// True if this filter applies to [scope] (same type and optional repo match).
  bool appliesTo(SearchScope scope) {
    if (scope.searchType != searchType) return false;
    if (repoScope == null) return true;
    return switch (scope) {
      RepoIssuesScope(repo: final r) => r == repoScope,
      RepoPullsScope(repo: final r) => r == repoScope,
      RepoDiscussionsScope(repo: final r) => r == repoScope,
      _ => false,
    };
  }

  /// Stable alias key for dynamic GQL (e.g. custom_a1b2c3d4).
  String get aliasKey {
    final clean = id.replaceAll('-', '').toLowerCase();
    final head = clean.length >= 8 ? clean.substring(0, 8) : clean;
    return 'custom_$head';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'searchType': searchType.name,
      'qualifiers': qualifiers.map((e) => e.toJson()).toList(),
      if (sort != null)
        'sort': <String, dynamic>{
          'key': sort!.key,
          'displayName': sort!.displayName,
        },
      if (freeText != null && freeText!.isNotEmpty) 'freeText': freeText,
      if (repoScope != null)
        'repoScope': <String, dynamic>{
          'owner': repoScope!.owner,
          'name': repoScope!.name,
        },
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static SortOption _sortFromJson(Map<String, dynamic> json) {
    return SortOption(
      key: json['key'] as String? ?? 'best',
      displayName: json['displayName'] as String? ?? 'Best match',
    );
  }

  static CustomFilter fromJson(Map<String, dynamic> json) {
    final qualList = json['qualifiers'] as List<dynamic>? ?? [];
    final sortJson = json['sort'] as Map<String, dynamic>?;
    final repoJson = json['repoScope'] as Map<String, dynamic>?;
    RepoRef? repo;
    if (repoJson != null) {
      repo = RepoRef(
        owner: repoJson['owner'] as String? ?? '',
        name: repoJson['name'] as String? ?? '',
      );
    }
    return CustomFilter(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      searchType: SearchType.values.byName(
        json['searchType'] as String? ?? SearchType.issuesPulls.name,
      ),
      qualifiers: qualList
          .map((e) => QualifierExpressionX.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
      sort: sortJson != null ? _sortFromJson(sortJson) : null,
      freeText: json['freeText'] as String?,
      repoScope: repo,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
