import 'package:diohub/workbench/domain/workbench_models.dart';

enum GitRemoteRole { origin, upstream, other }

enum GitRemoteTransport { https, ssh, scpLike }

/// Credential-free representation of a recognized GitHub remote.
final class NormalizedGitRemote {
  const NormalizedGitRemote({
    required this.repository,
    required this.transport,
    required this.displayUrl,
  });

  final GitHubRepositoryRef repository;
  final GitRemoteTransport transport;

  /// Sanitized address suitable for UI. It must never contain credentials.
  final String displayUrl;
}

enum RepoLinkSource { remote, manual }

/// Associates a local repository with one GitHub repository identity.
///
/// Multiple links are expected: for example, origin may be the user's fork
/// while upstream is the project repository.
final class RepoLink {
  const RepoLink({
    required this.localRootPath,
    required this.repository,
    required this.source,
    required this.remoteRole,
    this.remoteName,
    this.remoteAddress,
  });

  final String localRootPath;
  final GitHubRepositoryRef repository;
  final RepoLinkSource source;
  final String? remoteName;
  final GitRemoteRole remoteRole;
  final NormalizedGitRemote? remoteAddress;
}

/// Tracking relationship for one checked-out local branch.
final class BranchLink {
  const BranchLink({
    required this.localBranch,
    required this.remoteName,
    required this.remoteBranch,
    required this.ahead,
    required this.behind,
  }) : assert(ahead >= 0, 'ahead must not be negative'),
       assert(behind >= 0, 'behind must not be negative');

  final String localBranch;
  final String remoteName;
  final String remoteBranch;
  final int ahead;
  final int behind;

  String get trackingRef => '$remoteName/$remoteBranch';
}

final class GitChangeSummary {
  const GitChangeSummary({
    required this.staged,
    required this.unstaged,
    required this.untracked,
    required this.conflicted,
  }) : assert(staged >= 0, 'staged must not be negative'),
       assert(unstaged >= 0, 'unstaged must not be negative'),
       assert(untracked >= 0, 'untracked must not be negative'),
       assert(conflicted >= 0, 'conflicted must not be negative');

  const GitChangeSummary.clean()
    : staged = 0,
      unstaged = 0,
      untracked = 0,
      conflicted = 0;

  final int staged;
  final int unstaged;
  final int untracked;
  final int conflicted;

  bool get isDirty => staged + unstaged + untracked + conflicted > 0;
}

/// One regular checkout or linked Git worktree.
final class Worktree {
  const Worktree({
    required this.path,
    required this.isMain,
    required this.isDetached,
    required this.changes,
    this.headSha,
    this.headSummary,
    this.branch,
    this.branchLink,
  }) : assert(
         isDetached || branch != null,
         'A non-detached worktree must have a branch.',
       );

  final String path;
  final bool isMain;
  final bool isDetached;
  final String? headSha;
  final String? headSummary;
  final String? branch;
  final BranchLink? branchLink;
  final GitChangeSummary changes;

  bool get isDirty => changes.isDirty;
}

/// Read-only snapshot returned after inspecting a user-selected local path.
final class LocalRepo {
  LocalRepo({
    required this.rootPath,
    required this.commonGitDirectoryPath,
    required this.isBare,
    required final List<Worktree> worktrees,
    required final List<RepoLink> repositoryLinks,
    required final List<String> unmatchedRemoteNames,
    this.selectedWorktreePath,
  }) : worktrees = List<Worktree>.unmodifiable(worktrees),
       repositoryLinks = List<RepoLink>.unmodifiable(repositoryLinks),
       unmatchedRemoteNames = List<String>.unmodifiable(unmatchedRemoteNames);

  final String rootPath;
  final String commonGitDirectoryPath;
  final bool isBare;
  final String? selectedWorktreePath;
  final List<Worktree> worktrees;
  final List<RepoLink> repositoryLinks;
  final List<String> unmatchedRemoteNames;

  Worktree? get selectedWorktree {
    final String? selectedPath = selectedWorktreePath;
    if (selectedPath == null) {
      return null;
    }
    for (final Worktree worktree in worktrees) {
      if (worktree.path == selectedPath) {
        return worktree;
      }
    }
    return null;
  }

  RepoLink? linkForRemote(final String remoteName) {
    for (final RepoLink link in repositoryLinks) {
      if (link.remoteName == remoteName) {
        return link;
      }
    }
    return null;
  }
}

/// A safe, semantic editor destination. Process arguments are adapter details.
final class EditorTarget {
  const EditorTarget({
    required this.workspacePath,
    this.relativeFilePath,
    this.line,
    this.column,
    this.expectedHeadSha,
  }) : assert(line == null || line > 0, 'line must be positive'),
       assert(column == null || column > 0, 'column must be positive'),
       assert(
         column == null || line != null,
         'column cannot be supplied without line',
       );

  final String workspacePath;
  final String? relativeFilePath;
  final int? line;
  final int? column;

  /// Optional guard used by a desktop adapter before mapping an annotation.
  final String? expectedHeadSha;
}
