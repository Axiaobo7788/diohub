/// Minimal commit summary from the REST compare API response.
///
/// Lightweight data class used by [PushCommitsSheet] and compare views —
/// avoids coupling the UI layer to the full [CommitModel] which requires GQL codegen types.
class CompareCommitSummary {
  const CompareCommitSummary({
    required this.sha,
    required this.message,
    this.authorName,
    this.authorAvatarUrl,
    this.date,
  });
  final String sha;
  final String message;
  final String? authorName;
  final String? authorAvatarUrl;
  final DateTime? date;
}

/// Full result of the GitHub compare API (commits + files + stats).
class CompareResult {
  const CompareResult({
    required this.status,
    required this.aheadBy,
    required this.behindBy,
    required this.totalCommits,
    required this.commits,
    required this.files,
  });

  factory CompareResult.fromJson(final Map<String, dynamic> json) {
    final List<dynamic> commitsList =
        (json['commits'] as List<dynamic>?) ?? <dynamic>[];
    final List<CompareCommitSummary> commits = commitsList.map((final c) {
      final Map<String, dynamic> commit = c as Map<String, dynamic>;
      final Map<String, dynamic>? commitData =
          commit['commit'] as Map<String, dynamic>?;
      final Map<String, dynamic>? author =
          commitData?['author'] as Map<String, dynamic>?;
      final Map<String, dynamic>? ghAuthor =
          commit['author'] as Map<String, dynamic>?;
      return CompareCommitSummary(
        sha: commit['sha'] as String? ?? '',
        message: commitData?['message'] as String? ?? '',
        authorName: author?['name'] as String? ?? ghAuthor?['login'] as String?,
        authorAvatarUrl: ghAuthor?['avatar_url'] as String?,
        date: author?['date'] != null
            ? DateTime.tryParse(author!['date'] as String)
            : null,
      );
    }).toList();
    final List<dynamic> filesList =
        (json['files'] as List<dynamic>?) ?? <dynamic>[];
    final List<CompareFile> files = filesList
        .map((final f) => CompareFile.fromJson(f as Map<String, dynamic>))
        .toList();

    return CompareResult(
      status: json['status'] as String? ?? '',
      aheadBy: json['ahead_by'] as int? ?? 0,
      behindBy: json['behind_by'] as int? ?? 0,
      totalCommits: json['total_commits'] as int? ?? 0,
      commits: commits,
      files: files,
    );
  }

  final String status;
  final int aheadBy;
  final int behindBy;
  final int totalCommits;
  final List<CompareCommitSummary> commits;
  final List<CompareFile> files;
}

/// Single file in a compare result.
class CompareFile {
  const CompareFile({
    required this.filename,
    required this.status,
    required this.additions,
    required this.deletions,
    required this.changes,
    this.patch,
  });

  factory CompareFile.fromJson(final Map<String, dynamic> json) {
    return CompareFile(
      filename: json['filename'] as String? ?? '',
      status: json['status'] as String? ?? 'modified',
      additions: json['additions'] as int? ?? 0,
      deletions: json['deletions'] as int? ?? 0,
      changes: json['changes'] as int? ?? 0,
      patch: json['patch'] as String?,
    );
  }

  final String filename;
  final String status;
  final int additions;
  final int deletions;
  final int changes;
  final String? patch;
}
