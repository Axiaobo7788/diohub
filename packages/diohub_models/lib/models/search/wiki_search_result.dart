import 'package:freezed_annotation/freezed_annotation.dart';

part 'wiki_search_result.freezed.dart';
part 'wiki_search_result.g.dart';

@freezed
abstract class WikiSearchResult with _$WikiSearchResult {
  const factory WikiSearchResult({
    required String title,
    required String path,
    required String sha,
    @JsonKey(name: 'html_url') required String htmlUrl,
    required WikiRepo repository,
    @JsonKey(name: 'text_matches')
    @Default([])
    List<WikiTextMatch> textMatches,
  }) = _WikiSearchResult;

  factory WikiSearchResult.fromJson(Map<String, dynamic> json) =>
      _$WikiSearchResultFromJson(json);
}

@freezed
abstract class WikiRepo with _$WikiRepo {
  const factory WikiRepo({
    @JsonKey(name: 'full_name') required String fullName,
    WikiRepoOwner? owner,
    required String name,
  }) = _WikiRepo;

  factory WikiRepo.fromJson(Map<String, dynamic> json) =>
      _$WikiRepoFromJson(json);
}

@freezed
abstract class WikiRepoOwner with _$WikiRepoOwner {
  const factory WikiRepoOwner({
    required String login,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
  }) = _WikiRepoOwner;

  factory WikiRepoOwner.fromJson(Map<String, dynamic> json) =>
      _$WikiRepoOwnerFromJson(json);
}

@freezed
abstract class WikiTextMatch with _$WikiTextMatch {
  const factory WikiTextMatch({
    required String fragment,
  }) = _WikiTextMatch;

  factory WikiTextMatch.fromJson(Map<String, dynamic> json) =>
      _$WikiTextMatchFromJson(json);
}
