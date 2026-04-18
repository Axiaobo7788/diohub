import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/models/home_destination.dart';
import 'package:diohub_models/models/server_config.dart';
import 'package:diohub_models/models/navigable.dart';
import 'package:diohub_models/models/unrecognized_destination.dart';
import 'package:diohub/utils/github_url.dart';
import 'package:diohub_models/models/home_filter.dart';

/// Stateless parser that converts GitHub URLs into [Navigable] destinations.
///
/// Returns an [EntityRef] subtype for entity URLs (repos, issues, PRs, etc.),
/// [HomeDestination] for home-path URLs, [UnrecognizedDestination] for valid
/// GitHub URLs that can't be handled in-app, or `null` for non-GitHub URLs.
abstract class GitHubLinkParser {
  /// Parses a GitHub URL into a [Navigable] destination.
  /// [serverConfig] when set allows enterprise hosts; pass active server for deep links.
  static Navigable? parse(final Uri uri, {final ServerConfig? serverConfig}) {
    final GitHubUrl ghUrl =
        GitHubUrl.tryParse(uri.toString(), serverConfig: serverConfig);

    // Not a valid GitHub URL
    if (ghUrl.owner == null && ghUrl.segments.isEmpty) {
      return null;
    }

    // Exception URLs - return UnrecognizedDestination to open in browser
    if (_isExceptionUrl(ghUrl)) {
      return UnrecognizedDestination(uri: uri);
    }

    // Parse line numbers from fragment (e.g., #L42 or #L42-L50)
    int? lineStart;
    int? lineEnd;
    final String? fragment = uri.fragment.isNotEmpty ? uri.fragment : null;
    if (fragment != null && fragment.startsWith('L')) {
      final RegExpMatch? lineMatch =
          RegExp(r'L(\d+)(?:-L(\d+))?').firstMatch(fragment);
      if (lineMatch != null) {
        lineStart = int.tryParse(lineMatch.group(1)!);
        lineEnd = lineMatch.group(2) != null
            ? int.tryParse(lineMatch.group(2)!)
            : null;
      }
    }

    // Parse comment ID from fragment (e.g., #issuecomment-123 or #discussion_r456)
    String? commentId;
    if (fragment != null &&
        (fragment.startsWith('issuecomment-') ||
            fragment.startsWith('discussion_r'))) {
      commentId = fragment;
    }

    final List<String> segments = ghUrl.segments;

    // Home pages (0 or 1 segment)
    if (segments.isEmpty) {
      return const HomeDestination();
    }

    if (segments.length == 1) {
      final String first = segments[0];
      if (_isHomePositionPath(first)) {
        return HomeDestination(initialTabPath: first);
      }
      // User profile (e.g. /username?tab=repositories)
      final String? tabParam = uri.queryParameters['tab'];
      return UserRef(login: first, tab: tabParam);
    }

    // Check for home pages with filters: /issues/assigned, /issues/mentioned, etc.
    if (segments.length == 2) {
      final String first = segments[0];
      final String second = segments[1];
      final HomeFilter? filter = HomeFilter.fromString(second);

      if (_isHomePositionPath(first) && filter != null) {
        return HomeDestination(
          initialTabPath: first,
          filter: filter,
        );
      }
    }

    // Need at least owner/repo for most patterns
    if (segments.length < 2) {
      return UnrecognizedDestination(uri: uri);
    }

    final String owner = segments[0];
    final String repoName = segments[1];
    final RepoRef repo = RepoRef(owner: owner, name: repoName);

    // Just owner/repo - basic repo page
    if (segments.length == 2) {
      return repo;
    }

    final String entityType = segments[2];

    // New issue: /owner/repo/issues/new
    if (entityType == 'issues' &&
        segments.length == 4 &&
        segments[3] == 'new') {
      final String? templateId = uri.queryParameters['template'];
      return RepoRef(
        owner: owner,
        name: repoName,
        location: RepoLocation.newIssue(templateId: templateId),
      );
    }

    // Issue: /owner/repo/issues/123[#issuecomment-456]
    if (entityType == 'issues' && segments.length >= 4) {
      final String numberStr = segments[3];
      final int? number = int.tryParse(numberStr);
      if (number != null) {
        if (commentId != null && commentId.startsWith('issuecomment-')) {
          final int? id =
              int.tryParse(commentId.substring('issuecomment-'.length));
          if (id != null) {
            return IssueCommentRef(
              repo: repo,
              issueNumber: number,
              commentId: id,
            );
          }
        }
        return IssueRef(repo: repo, number: number);
      }
    }

    // Pull request: /owner/repo/pull/456 or /owner/repo/pulls/456
    if ((entityType == 'pull' || entityType == 'pulls') &&
        segments.length >= 4) {
      final String numberStr = segments[3];
      final int? number = int.tryParse(numberStr);
      if (number != null) {
        String? diffPath;
        if (segments.length >= 5 &&
            segments[4] == 'files' &&
            segments.length > 5) {
          diffPath = segments.skip(5).join('/');
        }
        return PullRequestRef(
          repo: repo,
          number: number,
          diffPath: diffPath,
        );
      }
    }

    // Commit: /owner/repo/commit/sha[#fragment]
    if (entityType == 'commit' && segments.length >= 4) {
      final String sha = segments[3];
      return CommitRef(repo: repo, oid: sha);
    }

    // Code tree: /owner/repo/tree/branch[/path]
    if (entityType == 'tree' && segments.length >= 4) {
      final String branch = segments[3];
      final String? path =
          segments.length > 4 ? segments.skip(4).join('/') : null;
      return RepoRef(
        owner: owner,
        name: repoName,
        location: RepoLocation.tree(branch: branch, path: path),
      );
    }

    // File blob: /owner/repo/blob/branch/path
    if (entityType == 'blob' && segments.length >= 5) {
      final String branch = segments[3];
      final String filePath = segments.skip(4).join('/');
      return RepoRef(
        owner: owner,
        name: repoName,
        location: RepoLocation.blob(
          branch: branch,
          filePath: filePath,
          lineStart: lineStart,
          lineEnd: lineEnd,
        ),
      );
    }

    // Commits list: /owner/repo/commits[/branch]
    if (entityType == 'commits') {
      final String? branch = segments.length >= 4 ? segments[3] : null;
      return RepoRef(
        owner: owner,
        name: repoName,
        location: RepoLocation.commits(branch: branch),
      );
    }

    // Issues list: /owner/repo/issues
    if (entityType == 'issues' && segments.length == 3) {
      return RepoRef(
        owner: owner,
        name: repoName,
        location: const RepoLocation.issues(),
      );
    }

    // Pulls list: /owner/repo/pulls
    if (entityType == 'pulls' && segments.length == 3) {
      return RepoRef(
        owner: owner,
        name: repoName,
        location: const RepoLocation.pulls(),
      );
    }

    // Wiki: /owner/repo/wiki or /owner/repo/wiki/PageSlug
    if (entityType == 'wiki') {
      final String? slug =
          segments.length >= 4 ? segments.skip(3).join('/') : null;
      return WikiRef(repo: repo, path: slug ?? '');
    }

    // Compare: /owner/repo/compare or /owner/repo/compare/base...head
    if (entityType == 'compare') {
      String? baseRef;
      String? headRef;
      if (segments.length >= 4) {
        final List<String> parts = segments[3].split('...');
        baseRef = parts.isNotEmpty ? parts[0] : null;
        headRef = parts.length > 1 ? parts[1] : null;
      }
      return RepoRef(
        owner: owner,
        name: repoName,
        location: RepoLocation.compare(
          baseRef: baseRef,
          headRef: headRef,
        ),
      );
    }

    // Repo page with tab (e.g., /owner/repo/actions, /owner/repo/security)
    final RepoLocation? location = _tabToLocation(entityType);
    return RepoRef(
      owner: owner,
      name: repoName,
      location: location,
    );
  }

  /// Check if this is an exception URL that should be opened in browser.
  static bool _isExceptionUrl(final GitHubUrl ghUrl) {
    final List<String> segments = ghUrl.segments;
    if (segments.isEmpty) return false;

    final String first = segments[0];

    // Settings pages
    if (first == 'settings') return true;

    // Login/device flow
    if (first == 'login' && segments.length > 1 && segments[1] == 'device') {
      return true;
    }

    return false;
  }

  static const Set<String> _homePositionPaths = <String>{
    'dashboard',
    'events',
    'issues',
    'pulls',
    'notifications',
    'orgs',
    'accounts',
    'themes',
    'settings',
  };

  static bool _isHomePositionPath(final String path) =>
      _homePositionPaths.contains(path.toLowerCase());

  /// Map URL entity type segment to RepoLocation for repo tabs.
  static RepoLocation? _tabToLocation(final String entityType) {
    return switch (entityType) {
      'issues' => const RepoLocation.issues(),
      'pulls' => const RepoLocation.pulls(),
      'commits' => const RepoLocation.commits(),
      'wiki' => const RepoLocation.wiki(),
      'releases' => const RepoLocation.releases(),
      'discussions' => const RepoLocation.discussions(),
      'projects' => const RepoLocation.projects(),
      'license' => const RepoLocation.license(),
      _ => null,
    };
  }
}
