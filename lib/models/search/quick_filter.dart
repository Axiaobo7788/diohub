import 'package:flutter/material.dart';

import 'package:diohub_models/models/search/qualifier.dart';
import 'package:diohub_models/models/search/search_count_query.dart';
import 'package:diohub_models/models/search/search_expression.dart';
import 'package:diohub/models/search/search_scope.dart';

/// A built-in quick filter with count query generation.
///
/// Quick filters are defined per SearchScope and shown in
/// the navigation overlay filter popup.
class QuickFilter with SearchCountQueryMixin {
  QuickFilter({
    required this.qualifier,
    required this.displayLabel,
    this.icon,
    this.aliasKey,
  });

  final QualifierExpression qualifier;
  final String displayLabel;
  final IconData? icon;
  
  /// Optional stable alias key for count map and GQL variable names.
  /// When provided, this is used instead of deriving from [displayLabel].
  /// This decouples the key from UI text changes.
  final String? aliasKey;

  @override
  List<QualifierExpression> get filterQualifiers => [qualifier];

  /// Base qualifiers — set when bound to a scope via [boundTo].
  @override
  late List<Qualifier> baseQualifiers;

  /// Returns a copy of this filter bound to a specific scope's
  /// hidden qualifiers, enabling count query generation.
  QuickFilter boundTo(final SearchScope scope) {
    return QuickFilter(
      qualifier: qualifier,
      displayLabel: displayLabel,
      icon: icon,
      aliasKey: aliasKey,
    )..baseQualifiers = scope.hiddenQualifiers;
  }

  /// Returns a copy with viewer login substituted in user-based qualifiers.
  /// Call [boundTo] on the result to set [baseQualifiers].
  QuickFilter withViewer(String viewer) {
    return QuickFilter(
      qualifier: qualifier.withViewer(viewer),
      displayLabel: displayLabel,
      icon: icon,
      aliasKey: aliasKey,
    );
  }

  /// Stable alias key for count map and GQL variable names.
  /// Example: "assignedToMe" + "issues" -> "assignedToMeIssues".
  /// Variable name is this + "Q" (e.g. assignedToMeIssuesQ).
  /// Uses [aliasKey] if provided, otherwise derives from [displayLabel].
  String aliasKeyForScope(SearchScope scope) {
    final camel = aliasKey ?? _toCamelCase(displayLabel);
    final pascal = _toPascalCase(scope.tabKey);
    return '$camel$pascal';
  }

  static final RegExp _wsPattern = RegExp(r'\s+');

  static String _toCamelCase(String s) {
    final words = s.trim().split(_wsPattern);
    if (words.isEmpty) return '';
    final first = words.first.toLowerCase();
    final rest = words.skip(1).map((w) {
      if (w.isEmpty) return w;
      return w.substring(0, 1).toUpperCase() + w.substring(1).toLowerCase();
    });
    return first + rest.join();
  }

  static String _toPascalCase(String s) {
    if (s.isEmpty) return s;
    return s.substring(0, 1).toUpperCase() + s.substring(1).toLowerCase();
  }
}

/// Quick option (checkbox-style, e.g. "Open only").
class QuickOption {
  const QuickOption({required this.qualifier, required this.displayLabel});
  final QualifierExpression qualifier;
  final String displayLabel;
}
