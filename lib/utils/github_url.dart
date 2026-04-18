import 'package:diohub/app/app_logger.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/server_config.dart';

/// Universal GitHub URL decomposition utility.
///
/// Replaces all scattered `split('/')`, `replaceAll('github.com')`,
/// `githubURLtoPath()`, and `toRepoAPIResource()` logic with a single,
/// well-tested class.
///
/// Handles both HTML URLs (github.com) and API URLs (api.github.com).
class GitHubUrl {
  /// Parse any GitHub URL (HTML, API, or bare path).
  ///
  /// Examples:
  /// - `https://github.com/flutter/flutter`
  /// - `https://api.github.com/repos/flutter/flutter`
  /// - `flutter/flutter/issues/123`
  ///
  /// Returns `null` if the URL is not a valid GitHub URL.
  /// [serverConfig] when set allows enterprise hosts; pass active server for deep links.
  factory GitHubUrl.tryParse(final String url,
      {final ServerConfig? serverConfig}) {
    try {
      Uri uri;
      if (url.startsWith('http://') || url.startsWith('https://')) {
        uri = Uri.parse(url);
      } else {
        // Bare path — assume the given server (or github.com default)
        final String webBase = serverConfig?.webBaseUrl ?? 'https://github.com';
        uri = Uri.parse('$webBase/$url');
      }

      // Validate: accept github.com, api.github.com, or known enterprise host
      final String host = uri.host.toLowerCase();
      final bool isKnownHost = host.contains('github.com') ||
          (serverConfig != null &&
              host == Uri.parse(serverConfig.webBaseUrl).host.toLowerCase());
      if (!isKnownHost) {
        throw FormatException('Not a recognized GitHub URL: $url');
      }

      // Clean and normalize path segments
      final List<String> pathSegments = uri.pathSegments
          .where((final String segment) => segment.isNotEmpty)
          .toList();

      // For API URLs, remove the leading "repos" if present
      final List<String> cleanSegments;
      if (host.contains('api.github.com') &&
          pathSegments.isNotEmpty &&
          pathSegments[0] == 'repos') {
        cleanSegments = pathSegments.skip(1).toList();
      } else {
        cleanSegments = pathSegments;
      }

      return GitHubUrl._(uri, cleanSegments);
    } catch (e) {
      AppLogger.info('Failed to parse GitHub URL: $url', tag: 'GitHubUrl');
      return GitHubUrl._(Uri(), <String>[]);
    }
  }
  GitHubUrl._(this.uri, this.segments);

  final Uri uri;
  final List<String> segments;

  /// Whether this is an API URL (api.github.com).
  bool get isApi => uri.host.toLowerCase().contains('api.github.com');

  /// Whether this is an HTML URL (github.com or www.github.com).
  bool get isHtml => uri.host.toLowerCase().contains('github.com') && !isApi;

  /// The repository owner (first path segment).
  ///
  /// For `github.com/flutter/flutter`, returns `"flutter"`.
  String? get owner => segments.isNotEmpty ? segments[0] : null;

  /// The repository name (second path segment).
  ///
  /// For `github.com/flutter/flutter`, returns `"flutter"`.
  String? get repo => segments.length > 1 ? segments[1] : null;

  /// The entity type (third path segment).
  ///
  /// For `github.com/flutter/flutter/issues/123`, returns `"issues"`.
  /// For `github.com/flutter/flutter/commit/abc`, returns `"commit"`.
  String? get entityType => segments.length > 2 ? segments[2] : null;

  /// The entity ID (fourth path segment, if it's numeric or a SHA).
  ///
  /// For `github.com/flutter/flutter/issues/123`, returns `"123"`.
  /// For `github.com/flutter/flutter/commit/abc123`, returns `"abc123"`.
  String? get entityId => segments.length > 3 ? segments[3] : null;

  /// The branch name (fourth path segment for tree/blob URLs).
  ///
  /// For `github.com/flutter/flutter/tree/main`, returns `"main"`.
  String? get branch {
    if (segments.length > 3 &&
        (entityType == 'tree' ||
            entityType == 'blob' ||
            entityType == 'commits')) {
      return segments[3];
    }
    return null;
  }

  /// The file path (segments after branch for tree/blob URLs).
  ///
  /// For `github.com/flutter/flutter/blob/main/lib/main.dart`,
  /// returns `"lib/main.dart"`.
  String? get filePath {
    if (segments.length > 4 && (entityType == 'tree' || entityType == 'blob')) {
      return segments.skip(4).join('/');
    }
    return null;
  }

  /// Convert to API URL for the given [server].
  String apiUrl(final ServerConfig server) {
    if (owner == null || repo == null) {
      return '${server.restBaseUrl}/repos';
    }

    final StringBuffer buffer =
        StringBuffer('${server.restBaseUrl}/repos/$owner/$repo');

    if (entityType != null) {
      switch (entityType) {
        case 'issues':
          buffer.write('/issues');
          if (entityId != null) buffer.write('/$entityId');
        case 'pull':
          buffer.write('/pulls');
          if (entityId != null) buffer.write('/$entityId');
        case 'commit':
        case 'commits':
          buffer.write('/commits');
          if (entityId != null) buffer.write('/$entityId');
        default:
          break;
      }
    }

    return buffer.toString();
  }

  /// Convert to HTML URL for the given [server].
  String htmlUrl(final ServerConfig server) {
    if (owner == null || repo == null) {
      return server.webBaseUrl;
    }
    return '${server.webBaseUrl}/${segments.join('/')}';
  }

  /// Convert to a RepoRef if this URL represents a repository.
  ///
  /// Returns `null` if owner or repo is missing.
  RepoRef? get toRepoRef {
    if (owner == null || repo == null) return null;
    return RepoRef(owner: owner!, name: repo!);
  }

  /// Get the full name (owner/repo).
  ///
  /// For `github.com/flutter/flutter`, returns `"flutter/flutter"`.
  String? get fullName {
    if (owner == null || repo == null) return null;
    return '$owner/$repo';
  }

  @override
  String toString() => uri.toString();

  /// Parses a submodule git URL (https or git@ form) into [RepoRef], or null.
  ///
  /// Handles: https://github.com/owner/repo, https://github.com/owner/repo.git,
  /// git@github.com:owner/repo.git.
  /// [server] when set allows enterprise host (url must contain [ServerConfig.host]).
  static RepoRef? tryParseRepoFromGitUrl(final Uri gitUrl,
      {final ServerConfig? server}) {
    final String url = gitUrl.toString();
    final String matchHost = server?.host ?? 'github.com';
    if (!url.contains(matchHost)) return null;
    final String? owner;
    final String? repoName;
    if (url.startsWith('git@')) {
      final int colon = url.indexOf(':');
      if (colon < 0) return null;
      final String path = url.substring(colon + 1);
      final List<String> parts =
          path.split('/').where((s) => s.isNotEmpty).toList();
      if (parts.length < 2) return null;
      owner = parts[0];
      repoName = parts[1].replaceFirst('.git', '');
    } else {
      final GitHubUrl gh = GitHubUrl.tryParse(url, serverConfig: server);
      if (gh.owner == null || gh.repo == null) return null;
      owner = gh.owner;
      repoName = gh.repo!.replaceFirst('.git', '');
    }
    if (owner == null || owner.isEmpty || repoName == null || repoName.isEmpty)
      return null;
    return RepoRef(owner: owner!, name: repoName!);
  }
}
