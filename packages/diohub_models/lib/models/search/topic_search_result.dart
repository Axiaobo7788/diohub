import 'package:freezed_annotation/freezed_annotation.dart';

part 'topic_search_result.freezed.dart';
part 'topic_search_result.g.dart';

@freezed
abstract class TopicSearchResult with _$TopicSearchResult {
  const factory TopicSearchResult({
    required String name,
    String? displayName,
    String? shortDescription,
    @JsonKey(name: 'created_by') String? createdBy,
    @Default(false) bool curated,
    @Default(false) bool featured,
    double? score,
  }) = _TopicSearchResult;

  factory TopicSearchResult.fromJson(Map<String, dynamic> json) =>
      _$TopicSearchResultFromJson(json);
}
