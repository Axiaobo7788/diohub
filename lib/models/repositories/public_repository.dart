import 'package:diohub_models/models/entity_ref.dart';

enum PublicRepositoryEntryKind { directory, file, symlink, submodule, unknown }

class PublicRepositorySummary {
  const PublicRepositorySummary({
    required this.id,
    required this.name,
    required this.owner,
    required this.fullName,
    required this.htmlUrl,
    required this.defaultBranch,
    required this.stargazerCount,
    required this.forkCount,
    required this.isArchived,
    this.description,
    this.language,
  });

  factory PublicRepositorySummary.fromJson(final Map<String, dynamic> json) {
    final Map<String, dynamic> owner = _map(json['owner']);
    return PublicRepositorySummary(
      id: _int(json['id']),
      name: _string(json['name']),
      owner: _string(owner['login']),
      fullName: _string(json['full_name']),
      description: _nullableString(json['description']),
      htmlUrl: Uri.parse(_string(json['html_url'])),
      defaultBranch: _string(json['default_branch'], fallback: 'main'),
      stargazerCount: _int(json['stargazers_count']),
      forkCount: _int(json['forks_count']),
      language: _nullableString(json['language']),
      isArchived: json['archived'] as bool? ?? false,
    );
  }

  final int id;
  final String name;
  final String owner;
  final String fullName;
  final String? description;
  final Uri htmlUrl;
  final String defaultBranch;
  final int stargazerCount;
  final int forkCount;
  final String? language;
  final bool isArchived;
}

class PublicRepositoryEntry {
  const PublicRepositoryEntry({
    required this.name,
    required this.path,
    required this.sha,
    required this.kind,
    required this.size,
    required this.htmlUrl,
    this.downloadUrl,
  });

  factory PublicRepositoryEntry.fromJson(final Map<String, dynamic> json) {
    return PublicRepositoryEntry(
      name: _string(json['name']),
      path: _string(json['path']),
      sha: _string(json['sha']),
      kind: switch (_nullableString(json['type'])) {
        'dir' => PublicRepositoryEntryKind.directory,
        'file' => PublicRepositoryEntryKind.file,
        'symlink' => PublicRepositoryEntryKind.symlink,
        'submodule' => PublicRepositoryEntryKind.submodule,
        _ => PublicRepositoryEntryKind.unknown,
      },
      size: _int(json['size']),
      htmlUrl: Uri.parse(_string(json['html_url'])),
      downloadUrl: switch (_nullableString(json['download_url'])) {
        final String value => Uri.tryParse(value),
        null => null,
      },
    );
  }

  final String name;
  final String path;
  final String sha;
  final PublicRepositoryEntryKind kind;
  final int size;
  final Uri htmlUrl;
  final Uri? downloadUrl;

  bool get isDirectory => kind == PublicRepositoryEntryKind.directory;
  bool get isFile =>
      kind == PublicRepositoryEntryKind.file ||
      kind == PublicRepositoryEntryKind.symlink;
}

class PublicRepositoryIssuePullSummary {
  const PublicRepositoryIssuePullSummary({
    required this.nodeId,
    required this.repo,
    required this.number,
    required this.title,
    required this.createdAt,
    required this.commentsCount,
    required this.state,
    required this.labels,
    required this.htmlUrl,
    required this.isPullRequest,
    required this.isDraft,
    required this.isMerged,
    this.author,
    this.closedAt,
    this.stateReason,
  });

  factory PublicRepositoryIssuePullSummary.fromJson(
    final Map<String, dynamic> json, {
    required final RepoRef repo,
  }) {
    final Map<String, dynamic> user = _map(json['user']);
    final Map<String, dynamic> pullRequest = _map(json['pull_request']);
    final String nodeId = _string(
      json['node_id'],
      fallback: _int(json['id']).toString(),
    );
    final Uri? htmlUrl = Uri.tryParse(_string(json['html_url']));
    if (nodeId.isEmpty || htmlUrl == null) {
      throw const FormatException(
        'GitHub returned an invalid public issue or pull request.',
      );
    }
    final List<PublicRepositoryIssuePullLabel> labels =
        (json['labels'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(PublicRepositoryIssuePullLabel.fromJson)
            .where((final PublicRepositoryIssuePullLabel label) {
              return label.name.isNotEmpty && label.color.isNotEmpty;
            })
            .toList(growable: false);
    final DateTime? createdAt = DateTime.tryParse(_string(json['created_at']));
    if (createdAt == null) {
      throw const FormatException(
        'GitHub returned an issue without a valid creation time.',
      );
    }
    return PublicRepositoryIssuePullSummary(
      nodeId: nodeId,
      repo: repo,
      number: _int(json['number']),
      title: _string(json['title']),
      author: _nullableString(user['login']),
      createdAt: createdAt,
      closedAt: switch (_nullableString(json['closed_at'])) {
        final String value => DateTime.tryParse(value),
        null => null,
      },
      commentsCount: _int(json['comments']),
      state: _string(json['state'], fallback: 'open'),
      stateReason: _nullableString(json['state_reason']),
      labels: labels,
      htmlUrl: htmlUrl,
      isPullRequest: pullRequest.isNotEmpty,
      isDraft: json['draft'] as bool? ?? false,
      isMerged: _nullableString(pullRequest['merged_at']) != null,
    );
  }

  final String nodeId;
  final RepoRef repo;
  final int number;
  final String title;
  final String? author;
  final DateTime createdAt;
  final DateTime? closedAt;
  final int commentsCount;
  final String state;
  final String? stateReason;
  final List<PublicRepositoryIssuePullLabel> labels;
  final Uri htmlUrl;
  final bool isPullRequest;
  final bool isDraft;
  final bool isMerged;
}

class PublicRepositoryIssuePullLabel {
  const PublicRepositoryIssuePullLabel({
    required this.name,
    required this.color,
  });

  factory PublicRepositoryIssuePullLabel.fromJson(
    final Map<String, dynamic> json,
  ) {
    return PublicRepositoryIssuePullLabel(
      name: _string(json['name']),
      color: _string(json['color']),
    );
  }

  final String name;
  final String color;
}

Map<String, dynamic> _map(final Object? value) =>
    value is Map<String, dynamic> ? value : const <String, dynamic>{};

String _string(final Object? value, {final String fallback = ''}) =>
    value is String && value.isNotEmpty ? value : fallback;

String? _nullableString(final Object? value) =>
    value is String && value.isNotEmpty ? value : null;

int _int(final Object? value) => value is int ? value : 0;
