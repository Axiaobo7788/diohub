import 'package:diohub_models/models/search/qualifier.dart';
import 'package:diohub_models/models/search/sort_config.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_expression.freezed.dart';

/// Part of a search: free text, qualifier, or sort.
@freezed
sealed class SearchExpression with _$SearchExpression {
  const SearchExpression._();

  const factory SearchExpression.freeText(String text) = FreeTextExpression;

  const factory SearchExpression.qualifier(
    Qualifier qualifier, {
    @Default(false) bool negated,
  }) = QualifierExpression;

  const factory SearchExpression.sort(SortOption option) = SortExpression;

  String toQueryFragment() => switch (this) {
        FreeTextExpression(:final text) => text,
        QualifierExpression(:final qualifier, :final negated) =>
          negated ? '-${qualifier.toQueryString()}' : qualifier.toQueryString(),
        SortExpression(:final option) => 'sort:${option.key}',
      };
}

extension FreeTextExpressionX on FreeTextExpression {
  String toQueryFragment() => text;
}

extension QualifierExpressionX on QualifierExpression {
  String toQueryFragment() =>
      negated ? '-${qualifier.toQueryString()}' : qualifier.toQueryString();

  QualifierExpression withViewer(String viewer) =>
      QualifierExpression(qualifier.withViewer(viewer), negated: negated);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'qualifier': qualifier.toJson(),
        'negated': negated,
      };

  static QualifierExpression fromJson(Map<String, dynamic> json) =>
      QualifierExpression(
        Qualifier.fromJson(
          Map<String, dynamic>.from(json['qualifier'] as Map),
        ),
        negated: json['negated'] as bool? ?? false,
      );
}

extension SortExpressionX on SortExpression {
  String toQueryFragment() => 'sort:${option.key}';

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'key': option.key, 'displayName': option.displayName};

  static SortExpression fromJson(Map<String, dynamic> json) => SortExpression(
        SortOption(
          key: json['key'] as String? ?? 'best',
          displayName: json['displayName'] as String? ?? 'Best match',
        ),
      );
}
