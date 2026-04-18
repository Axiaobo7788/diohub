import 'dart:collection';

import 'package:diohub/app/app_logger.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/commits/commit_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'commit_list_item_model.freezed.dart';

/// Data for a single commit in a list. All fields come from the list
/// pagination API so no per-card fetch is needed.
@freezed
abstract class CommitListItemModel with _$CommitListItemModel {
  const factory CommitListItemModel({
    required final String messageHeadline,
    required final DateTime committedDate,
    required final String sha,
    final String? messageBody,
    final String? authorLogin,
    final String? authorAvatarUrl,
    final String? commitUrl,
    final String? repoOwner,
    final String? repoName,
    final int? additions,
    final int? deletions,
    final int? changedFilesCount,
    final bool? isVerified,

    /// Signer login from signature.signer (GPG/SSH/S/MIME).
    final String? signerLogin,

    /// Signer email from signature.signer.
    final String? signerEmail,

    /// True when signature.wasSignedByGitHub.
    final bool? wasSignedByGitHub,
    // CI status from statusCheckRollup
    final String? statusCheckRollupState,
    // Associated PR
    final int? associatedPRNumber,
    final String? associatedPRUrl,
    // Comment count
    final int? commentsCount,
    // Committer when different from author
    final String? committerLogin,
    final String? committerAvatarUrl,
    // Committed via web
    final bool? committedViaWeb,
    // Parent count for merge commit detection
    final int? parentCount,
  }) = _CommitListItemModel;

  /// Formatted signer line for verification popup (login, email, or "Signed by GitHub").
  String? get signerDisplay {
    if (signerLogin != null && signerLogin!.isNotEmpty) {
      return signerEmail != null && signerEmail!.isNotEmpty
          ? '$signerLogin ($signerEmail)'
          : signerLogin;
    }
    return wasSignedByGitHub == true ? 'Signed by GitHub' : null;
  }

  /// Build from GraphQL commit list item (e.g. repository Commits tab).
  factory CommitListItemModel.fromGcommitListItem(
    final CommitNode commit,
    final RepoRef repo,
  ) {
    final String? authorLogin = commit.author?.user?.login ??
        commit.author?.name ??
        commit.author?.email;
    final String message = commit.message;
    final int firstNewline = message.indexOf('\n');
    final String headline = commit.messageHeadline;
    final String? body = firstNewline >= 0 && message.length > firstNewline + 1
        ? message.substring(firstNewline + 1).trim()
        : null;
    final String? statusCheckRollupState = _statusCheckRollupState(commit);
    final firstPR = commit.associatedPullRequests?.nodes?.firstOrNull;
    final int? associatedPRNumber = firstPR?.number;
    final String? associatedPRUrl = firstPR?.url.toString();
    final int? commentsCount = commit.comments.totalCount;
    final String? committerUserLogin = commit.committer?.user?.login;
    final String? committerLogin =
        (committerUserLogin != null && committerUserLogin != authorLogin)
            ? committerUserLogin
            : null;
    final String? committerAvatarUrl =
        committerLogin != null ? commit.committer?.avatarUrl.toString() : null;
    final bool? committedViaWeb = commit.committedViaWeb;
    final int? parentCount = commit.parents.edges?.length;
    final (String? signerLogin, String? signerEmail, bool? wasSignedByGitHub) =
        _commitSignatureSigner(commit);

    return CommitListItemModel(
      messageHeadline: headline,
      messageBody: (body == null || body.isEmpty) ? null : body,
      authorLogin: authorLogin,
      authorAvatarUrl: commit.author?.avatarUrl.toString(),
      committedDate: commit.committedDate,
      sha: commit.oid,
      commitUrl: commit.commitUrl.toString(),
      repoOwner: repo.owner,
      repoName: repo.name,
      additions: commit.additions,
      deletions: commit.deletions,
      changedFilesCount: commit.changedFilesIfAvailable,
      isVerified: _commitSignatureIsValid(commit),
      signerLogin: signerLogin,
      signerEmail: signerEmail,
      wasSignedByGitHub: wasSignedByGitHub,
      statusCheckRollupState: statusCheckRollupState,
      associatedPRNumber: associatedPRNumber,
      associatedPRUrl: associatedPRUrl,
      commentsCount: commentsCount,
      committerLogin: committerLogin,
      committerAvatarUrl: committerAvatarUrl,
      committedViaWeb: committedViaWeb,
      parentCount: parentCount,
    );
  }

  /// Build from compare/summary commit data (e.g. push sheet, timeline, activity).
  /// [sha] and [message] required; [authorName], [authorAvatarUrl], [date] optional.
  factory CommitListItemModel.fromCompareCommitSummary(
    final String sha,
    final String message,
    final RepoRef repo, {
    final String? authorName,
    final String? authorAvatarUrl,
    final DateTime? date,
  }) {
    final int firstNewline = message.indexOf('\n');
    final String headline = firstNewline >= 0
        ? message.substring(0, firstNewline).trim()
        : message.trim();
    final String? body = firstNewline >= 0 && message.length > firstNewline + 1
        ? message.substring(firstNewline + 1).trim()
        : null;
    return CommitListItemModel(
      messageHeadline: headline.isEmpty ? 'No message' : headline,
      messageBody: (body == null || body.isEmpty) ? null : body,
      committedDate: date ?? DateTime.now(),
      sha: sha,
      authorLogin: authorName,
      authorAvatarUrl: authorAvatarUrl,
      commitUrl: null,
      repoOwner: repo.owner,
      repoName: repo.name,
      additions: null,
      deletions: null,
      changedFilesCount: null,
      isVerified: null,
      statusCheckRollupState: null,
      associatedPRNumber: null,
      associatedPRUrl: null,
      commentsCount: null,
      committerLogin: null,
      committerAvatarUrl: null,
      committedViaWeb: null,
      parentCount: null,
    );
  }

  /// Build from REST commit search item (GET /search/commits).
  factory CommitListItemModel.fromSearchCommitItem(
    final Map<String, dynamic> json,
  ) {
    final Map<String, dynamic>? commit =
        json['commit'] as Map<String, dynamic>?;
    final String message = commit?['message'] as String? ?? '';
    final int firstNewline = message.indexOf('\n');
    final String headline = firstNewline >= 0
        ? message.substring(0, firstNewline).trim()
        : message.trim();
    final String? body = firstNewline >= 0 && message.length > firstNewline + 1
        ? message.substring(firstNewline + 1).trim()
        : null;
    final Map<String, dynamic>? author =
        json['author'] as Map<String, dynamic>?;
    final Map<String, dynamic>? repoMap =
        json['repository'] as Map<String, dynamic>?;
    final String? fullName = repoMap?['full_name'] as String?;
    final int slash = fullName != null ? fullName.indexOf('/') : -1;
    final String? repoOwner =
        slash >= 0 && fullName != null ? fullName.substring(0, slash) : null;
    final String? repoName =
        slash >= 0 && fullName != null ? fullName.substring(slash + 1) : null;
    DateTime date = DateTime.now();
    if (commit != null) {
      final Map<String, dynamic>? committer =
          commit['committer'] as Map<String, dynamic>?;
      final Map<String, dynamic>? commitAuthor =
          commit['author'] as Map<String, dynamic>?;
      final String? dateStr =
          (committer?['date'] ?? commitAuthor?['date']) as String?;
      if (dateStr != null) date = DateTime.parse(dateStr);
    }
    return CommitListItemModel(
      messageHeadline: headline.isEmpty ? 'No message' : headline,
      messageBody: (body == null || body.isEmpty) ? null : body,
      authorLogin: author?['login'] as String?,
      authorAvatarUrl: author?['avatar_url'] as String?,
      committedDate: date,
      sha: json['sha'] as String? ?? '',
      commitUrl: (json['html_url'] ?? json['url']) as String?,
      repoOwner: repoOwner,
      repoName: repoName,
      additions: null,
      deletions: null,
      changedFilesCount: null,
      isVerified: null,
      statusCheckRollupState: null,
      associatedPRNumber: null,
      associatedPRUrl: null,
      commentsCount: null,
      committerLogin: null,
      committerAvatarUrl: null,
      committedViaWeb: null,
      parentCount: null,
    );
  }

  /// Build from REST Commit (e.g. repository Code tab commit browser).
  factory CommitListItemModel.fromCommit(
      final Commit commit, final RepoRef repo) {
    final CommitDetail? detail = commit.commit;
    final String message = detail?.message ?? '';
    final int firstNewline = message.indexOf('\n');
    final String headline = firstNewline >= 0
        ? message.substring(0, firstNewline).trim()
        : message.trim();
    final String? body = firstNewline >= 0 && message.length > firstNewline + 1
        ? message.substring(firstNewline + 1).trim()
        : null;
    final DateTime date =
        detail?.committer?.date ?? detail?.author?.date ?? DateTime.now();
    return CommitListItemModel(
      messageHeadline: headline.isEmpty ? 'No message' : headline,
      messageBody: (body == null || body.isEmpty) ? null : body,
      authorLogin: commit.author?.login,
      authorAvatarUrl: commit.author?.avatarUrl,
      committedDate: date,
      sha: commit.sha,
      commitUrl: commit.htmlUrl ?? commit.url,
      repoOwner: repo.owner,
      repoName: repo.name,
      additions: null,
      deletions: null,
      changedFilesCount: null,
      isVerified: null,
      signerLogin: null,
      signerEmail: null,
      wasSignedByGitHub: null,
      statusCheckRollupState: null,
      associatedPRNumber: null,
      associatedPRUrl: null,
      commentsCount: null,
      committerLogin: null,
      committerAvatarUrl: null,
      committedViaWeb: null,
      parentCount: null,
    );
  }

  const CommitListItemModel._();

  /// Reads signature.signer and wasSignedByGitHub from commit (after codegen).
  static (String? login, String? email, bool? wasSignedByGitHub)
      _commitSignatureSigner(final CommitNode commit) {
    try {
      final dynamic d = commit;
      final Object? sig = d.signature;
      if (sig == null) return (null, null, null);
      final dynamic s = sig;
      final bool? gh = s.wasSignedByGitHub as bool?;
      final Object? signer = s.signer;
      if (signer == null) return (null, null, gh);
      final dynamic sr = signer;
      final String? login = sr.login as String?;
      final String? email = sr.email as String?;
      return (login, email, gh);
    } catch (e, st) {
      AppLogger.warning(
        'Failed to read commit signature signer',
        error: e,
        stackTrace: st,
        tag: 'CommitListItemModel',
      );
    }
    return (null, null, null);
  }

  /// Reads signature.isValid from a commit list node if present (after codegen).
  static bool? _commitSignatureIsValid(final CommitNode commit) {
    final sig = commit.signature;
    return sig?.isValid;
  }

  /// Reads statusCheckRollup.state from commit (codegen exposes as enum, we need string).
  static String? _statusCheckRollupState(final CommitNode commit) {
    try {
      final rollup = commit.statusCheckRollup;
      if (rollup == null) return null;
      final state = rollup.state;
      return state.name;
    } catch (e, st) {
      AppLogger.warning(
        'Reading statusCheckRollup.state failed',
        error: e,
        stackTrace: st,
        tag: 'CommitNode',
      );
    }
    return null;
  }

  /// Full repo name "owner/name" when both repoOwner and repoName are set.
  String? get repoFullName =>
      (repoOwner != null && repoName != null) ? '$repoOwner/$repoName' : null;
}
