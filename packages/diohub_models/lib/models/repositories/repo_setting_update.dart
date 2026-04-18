/// Type-safe repository setting update. Use with [RepositoryServices.updateSetting].
/// Set only the fields you want to change; null means "don't change".
/// All fields are sent via a single REST PATCH /repos/{owner}/{repo}.
class RepoSettingUpdate {
  const RepoSettingUpdate({
    this.name,
    this.description,
    this.homepageUrl,
    this.hasWikiEnabled,
    this.hasIssuesEnabled,
    this.hasProjectsEnabled,
    this.hasDiscussionsEnabled,
    this.isPrivate,
    this.allowMergeCommit,
    this.allowSquashMerge,
    this.allowRebaseMerge,
  });

  final String? name;
  final String? description;
  final String? homepageUrl;
  final bool? hasWikiEnabled;
  final bool? hasIssuesEnabled;
  final bool? hasProjectsEnabled;
  final bool? hasDiscussionsEnabled;
  final bool? isPrivate;
  final bool? allowMergeCommit;
  final bool? allowSquashMerge;
  final bool? allowRebaseMerge;

  /// Builds the REST PATCH body with only non-null fields. String fields use
  /// empty string when null to allow clearing.
  Map<String, dynamic> toRestBody() {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (name != null) body['name'] = name!;
    if (description != null) body['description'] = description!;
    if (homepageUrl != null) body['homepage'] = homepageUrl!;
    if (hasWikiEnabled != null) body['has_wiki'] = hasWikiEnabled!;
    if (hasIssuesEnabled != null) body['has_issues'] = hasIssuesEnabled!;
    if (hasProjectsEnabled != null) body['has_projects'] = hasProjectsEnabled!;
    if (hasDiscussionsEnabled != null) {
      body['has_discussions'] = hasDiscussionsEnabled!;
    }
    if (isPrivate != null) body['private'] = isPrivate!;
    if (allowMergeCommit != null) {
      body['allow_merge_commit'] = allowMergeCommit!;
    }
    if (allowSquashMerge != null) {
      body['allow_squash_merge'] = allowSquashMerge!;
    }
    if (allowRebaseMerge != null) {
      body['allow_rebase_merge'] = allowRebaseMerge!;
    }
    return body;
  }
}
