import 'package:freezed_annotation/freezed_annotation.dart';

part 'code_search_result.freezed.dart';
part 'code_search_result.g.dart';

@freezed
abstract class CodeSearchResult with _$CodeSearchResult {
  const factory CodeSearchResult({
    required String name,
    required String path,
    required String sha,
    @JsonKey(name: 'html_url') required String htmlUrl,
    required CodeSearchRepo repository,
    @JsonKey(name: 'text_matches') @Default([]) List<CodeTextMatch> textMatches,
  }) = _CodeSearchResult;

  factory CodeSearchResult.fromJson(Map<String, dynamic> json) =>
      _$CodeSearchResultFromJson(json);
}

@freezed
abstract class CodeSearchRepo with _$CodeSearchRepo {
  const factory CodeSearchRepo({
    @JsonKey(name: 'full_name') required String fullName,
    required CodeSearchRepoOwner? owner,
    required String name,
  }) = _CodeSearchRepo;

  factory CodeSearchRepo.fromJson(Map<String, dynamic> json) =>
      _$CodeSearchRepoFromJson(json);
}

@freezed
abstract class CodeSearchRepoOwner with _$CodeSearchRepoOwner {
  const factory CodeSearchRepoOwner({
    required String login,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
  }) = _CodeSearchRepoOwner;

  factory CodeSearchRepoOwner.fromJson(Map<String, dynamic> json) =>
      _$CodeSearchRepoOwnerFromJson(json);
}

@freezed
abstract class CodeTextMatch with _$CodeTextMatch {
  const factory CodeTextMatch({
    required String fragment,
    @Default([]) List<CodeMatchIndex> matches,
  }) = _CodeTextMatch;

  factory CodeTextMatch.fromJson(Map<String, dynamic> json) =>
      _$CodeTextMatchFromJson(json);
}

@freezed
abstract class CodeMatchIndex with _$CodeMatchIndex {
  const factory CodeMatchIndex({
    required List<int> indices,
    String? text,
  }) = _CodeMatchIndex;

  factory CodeMatchIndex.fromJson(Map<String, dynamic> json) =>
      _$CodeMatchIndexFromJson(json);
}
