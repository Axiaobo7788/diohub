import 'package:diohub/app/settings/repository.dart' as repo_app_settings;
import 'package:diohub_models/models/entity_ref.dart';

/// Kind of repository tab; used for initial focus instead of string labels.
enum RepositoryTabKind {
  readme,
  code,
  issues,
  pulls,
  commits,
  license,
  releases,
  discussions,
  projects,
  wiki,
  actions,
  security,
  insights,
}

/// Initial state for the repository screen (tab + branch + code path).
/// Built from [RepoLocation] when [RepoRef.location] is set.
class RepositoryInitialState {
  const RepositoryInitialState({
    this.tabKind,
    this.branch,
    this.codePath,
    this.wikiSlug,
  });

  final RepositoryTabKind? tabKind;
  final String? branch;
  final String? codePath;
  final String? wikiSlug;

  /// Build from legacy route args (string tab label, branch, path).
  /// Used when migrating from separate route params to location-only.
  static RepositoryInitialState fromRouteArgs(
    final String? tabLabel,
    final String? branch,
    final String? codePath,
  ) {
    final RepositoryTabKind? kind = _tabLabelToKind(tabLabel);
    return RepositoryInitialState(
      tabKind: kind,
      branch: branch,
      codePath: codePath,
      wikiSlug: null,
    );
  }

  /// Map settings default tab to [RepositoryTabKind].
  static RepositoryTabKind tabKindFromRepositoryDefaultTab(
    final repo_app_settings.RepositoryDefaultTab value,
  ) {
    return switch (value) {
      repo_app_settings.RepositoryDefaultTab.readme => RepositoryTabKind.readme,
      repo_app_settings.RepositoryDefaultTab.code => RepositoryTabKind.code,
      repo_app_settings.RepositoryDefaultTab.issues => RepositoryTabKind.issues,
      repo_app_settings.RepositoryDefaultTab.pulls => RepositoryTabKind.pulls,
      repo_app_settings.RepositoryDefaultTab.commits =>
        RepositoryTabKind.commits,
    };
  }

  static RepositoryTabKind? _tabLabelToKind(final String? label) {
    if (label == null || label.isEmpty) return null;
    return switch (label) {
      'Readme' => RepositoryTabKind.readme,
      'Code' => RepositoryTabKind.code,
      'Issues' => RepositoryTabKind.issues,
      'Pull Requests' => RepositoryTabKind.pulls,
      'Commits' => RepositoryTabKind.commits,
      'License' => RepositoryTabKind.license,
      'Releases' => RepositoryTabKind.releases,
      'Discussions' => RepositoryTabKind.discussions,
      'Projects' => RepositoryTabKind.projects,
      'Wiki' => RepositoryTabKind.wiki,
      'Actions' => RepositoryTabKind.actions,
      'Security' => RepositoryTabKind.security,
      'Insights' => RepositoryTabKind.insights,
      _ => null,
    };
  }
}

/// Resolves [RepoLocation] to [RepositoryInitialState].
/// Used when [RepoRef.location] is set (e.g. from deeplink).
RepositoryInitialState resolveRepoLocation(final RepoLocation? location) {
  if (location == null) return const RepositoryInitialState();
  return switch (location) {
    RepoLocationRoot() => const RepositoryInitialState(),
    RepoLocationTree(:final branch, :final path) => RepositoryInitialState(
      tabKind: RepositoryTabKind.code,
      branch: branch,
      codePath: path,
    ),
    RepoLocationBlob(:final branch, :final filePath) => RepositoryInitialState(
      tabKind: RepositoryTabKind.code,
      branch: branch,
      codePath: filePath,
    ),
    RepoLocationIssues() => const RepositoryInitialState(
      tabKind: RepositoryTabKind.issues,
    ),
    RepoLocationPulls() => const RepositoryInitialState(
      tabKind: RepositoryTabKind.pulls,
    ),
    RepoLocationCommits(:final branch) => RepositoryInitialState(
      tabKind: RepositoryTabKind.commits,
      branch: branch,
    ),
    RepoLocationWiki(:final page) => RepositoryInitialState(
      tabKind: RepositoryTabKind.wiki,
      wikiSlug: page,
    ),
    RepoLocationReleases() => const RepositoryInitialState(
      tabKind: RepositoryTabKind.releases,
    ),
    RepoLocationDiscussions() => const RepositoryInitialState(
      tabKind: RepositoryTabKind.discussions,
    ),
    RepoLocationProjects() => const RepositoryInitialState(
      tabKind: RepositoryTabKind.projects,
    ),
    RepoLocationActions() => const RepositoryInitialState(
      tabKind: RepositoryTabKind.actions,
    ),
    RepoLocationSecurity() => const RepositoryInitialState(
      tabKind: RepositoryTabKind.security,
    ),
    RepoLocationInsights() => const RepositoryInitialState(
      tabKind: RepositoryTabKind.insights,
    ),
    RepoLocationLicense() => const RepositoryInitialState(
      tabKind: RepositoryTabKind.license,
    ),
    RepoLocationNewIssue() => const RepositoryInitialState(),
    RepoLocationCompare() => const RepositoryInitialState(),
  };
}

/// True if [s] looks like a full commit SHA (40 hex chars). Used when deriving
/// initial ref for repo GraphQL: we do not pass commit SHAs as [initialRef].
bool looksLikeFullSha(final String s) =>
    s.length == 40 && int.tryParse(s, radix: 16) != null;
