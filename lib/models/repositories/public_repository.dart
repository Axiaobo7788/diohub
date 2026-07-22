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

Map<String, dynamic> _map(final Object? value) =>
    value is Map<String, dynamic> ? value : const <String, dynamic>{};

String _string(final Object? value, {final String fallback = ''}) =>
    value is String && value.isNotEmpty ? value : fallback;

String? _nullableString(final Object? value) =>
    value is String && value.isNotEmpty ? value : null;

int _int(final Object? value) => value is int ? value : 0;
