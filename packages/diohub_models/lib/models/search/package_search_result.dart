import 'package:freezed_annotation/freezed_annotation.dart';

part 'package_search_result.freezed.dart';
part 'package_search_result.g.dart';

@freezed
abstract class PackageSearchResult with _$PackageSearchResult {
  const factory PackageSearchResult({
    required String name,
    @JsonKey(name: 'package_type') required String packageType,
    @JsonKey(name: 'html_url') required String htmlUrl,
    String? description,
    PackageRepo? repository,
  }) = _PackageSearchResult;

  factory PackageSearchResult.fromJson(Map<String, dynamic> json) =>
      _$PackageSearchResultFromJson(json);
}

@freezed
abstract class PackageRepo with _$PackageRepo {
  const factory PackageRepo({
    @JsonKey(name: 'full_name') required String fullName,
    PackageRepoOwner? owner,
    required String name,
  }) = _PackageRepo;

  factory PackageRepo.fromJson(Map<String, dynamic> json) =>
      _$PackageRepoFromJson(json);
}

@freezed
abstract class PackageRepoOwner with _$PackageRepoOwner {
  const factory PackageRepoOwner({
    required String login,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
  }) = _PackageRepoOwner;

  factory PackageRepoOwner.fromJson(Map<String, dynamic> json) =>
      _$PackageRepoOwnerFromJson(json);
}
