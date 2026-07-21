import 'package:diohub/workbench/domain/workbench_models.dart';
import 'package:diohub/workbench/domain/workspace_models.dart';

/// Parses GitHub and GitHub Enterprise remotes without retaining credentials.
final class GitRemoteParser {
  const GitRemoteParser();

  NormalizedGitRemote? tryParse(final String remoteUrl) {
    final String value = remoteUrl.trim();
    if (value.isEmpty) {
      return null;
    }

    final Uri? uri = Uri.tryParse(value);
    final String scheme = uri?.scheme.toLowerCase() ?? '';
    if (uri != null && (scheme == 'https' || scheme == 'ssh')) {
      return _fromUri(uri, scheme: scheme);
    }
    return _fromScpLike(value);
  }

  RepoLink? tryCreateRepoLink({
    required final String localRootPath,
    required final String remoteName,
    required final String remoteUrl,
  }) {
    final NormalizedGitRemote? address = tryParse(remoteUrl);
    if (address == null) {
      return null;
    }
    return RepoLink(
      localRootPath: localRootPath,
      repository: address.repository,
      source: RepoLinkSource.remote,
      remoteName: remoteName,
      remoteRole: roleForName(remoteName),
      remoteAddress: address,
    );
  }

  GitRemoteRole roleForName(final String remoteName) =>
      switch (remoteName.trim().toLowerCase()) {
        'origin' => GitRemoteRole.origin,
        'upstream' => GitRemoteRole.upstream,
        _ => GitRemoteRole.other,
      };

  NormalizedGitRemote? _fromUri(final Uri uri, {required final String scheme}) {
    if (uri.host.isEmpty) {
      return null;
    }
    final ({String owner, String name})? path = _parsePath(uri.pathSegments);
    if (path == null) {
      return null;
    }
    final String host = uri.host.toLowerCase();
    final GitHubRepositoryRef repository = GitHubRepositoryRef(
      host: host,
      owner: path.owner,
      name: path.name,
    );
    final String port = uri.hasPort ? ':${uri.port}' : '';
    return NormalizedGitRemote(
      repository: repository,
      transport: scheme == 'https'
          ? GitRemoteTransport.https
          : GitRemoteTransport.ssh,
      displayUrl: '$scheme://$host$port/${path.owner}/${path.name}.git',
    );
  }

  NormalizedGitRemote? _fromScpLike(final String value) {
    if (value.contains('://')) {
      return null;
    }
    final RegExpMatch? match = RegExp(
      r'^(?:[^@\s/:]+@)?([^/\s:]+):(.+)$',
    ).firstMatch(value);
    if (match == null) {
      return null;
    }
    final String host = match.group(1)!.toLowerCase();
    final String rawPath = match.group(2)!;
    final ({String owner, String name})? path = _parsePath(rawPath.split('/'));
    if (path == null) {
      return null;
    }
    return NormalizedGitRemote(
      repository: GitHubRepositoryRef(
        host: host,
        owner: path.owner,
        name: path.name,
      ),
      transport: GitRemoteTransport.scpLike,
      displayUrl: '$host:${path.owner}/${path.name}.git',
    );
  }

  ({String owner, String name})? _parsePath(
    final Iterable<String> rawSegments,
  ) {
    final List<String> segments = rawSegments
        .where((final String segment) => segment.isNotEmpty)
        .toList(growable: false);
    if (segments.length != 2) {
      return null;
    }
    final String owner = segments.first;
    String name = segments.last;
    if (name.toLowerCase().endsWith('.git')) {
      name = name.substring(0, name.length - 4);
    }
    if (!_isValidSegment(owner) || !_isValidSegment(name)) {
      return null;
    }
    return (owner: owner, name: name);
  }

  bool _isValidSegment(final String value) =>
      value.isNotEmpty && value != '.' && value != '..';
}
