import 'package:diohub/app/settings/layout.dart';
import 'package:diohub/common/search_overlay/adapters/search_adapter_code.dart';
import 'package:diohub/common/search_overlay/adapters/search_adapter_commits.dart';
import 'package:diohub/common/search_overlay/adapters/search_adapter_discussions.dart';
import 'package:diohub/common/search_overlay/adapters/search_adapter_issues_pulls.dart';
import 'package:diohub/common/search_overlay/adapters/search_adapter_packages.dart';
import 'package:diohub/common/search_overlay/adapters/search_adapter_repos.dart';
import 'package:diohub/common/search_overlay/adapters/search_adapter_topics.dart';
import 'package:diohub/common/search_overlay/adapters/search_adapter_users.dart';
import 'package:diohub/common/search_overlay/adapters/search_adapter_wiki.dart';
import 'package:diohub/common/search_overlay/search_type.dart';
import 'package:diohub/common/search_overlay/search_type_adapter.dart';
import 'package:diohub/providers/settings/layout_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Returns a type-safe adapter for the given [SearchType].
/// [ref] is used for layout-dependent options (e.g. showDescription for issues/pulls).
SearchTypeAdapter<Object> adapterForSearchType(
  final SearchType type, {
  required WidgetRef ref,
  final bool showRepoOwner = true,
  final bool showRepoNameOnIssues = true,
}) {
  final bool showDescription =
      ref.read(layoutProvider).density == LayoutDensity.spacious;
  return switch (type) {
    SearchType.repositories =>
      RepoSearchAdapter(ref, showOwner: showRepoOwner) as SearchTypeAdapter<Object>,
    SearchType.issuesPulls => IssuePullSearchAdapter(
        ref,
        showRepoNameOnIssues: showRepoNameOnIssues,
        showDescription: showDescription,
      ) as SearchTypeAdapter<Object>,
    SearchType.users => UserSearchAdapter(ref) as SearchTypeAdapter<Object>,
    SearchType.discussions =>
      DiscussionSearchAdapter(ref) as SearchTypeAdapter<Object>,
    SearchType.code => CodeSearchAdapter(ref) as SearchTypeAdapter<Object>,
    SearchType.commits => CommitSearchAdapter(ref) as SearchTypeAdapter<Object>,
    SearchType.topics => TopicSearchAdapter(ref) as SearchTypeAdapter<Object>,
    SearchType.packages => PackageSearchAdapter(ref) as SearchTypeAdapter<Object>,
    SearchType.wiki => WikiSearchAdapter(ref) as SearchTypeAdapter<Object>,
  };
}
