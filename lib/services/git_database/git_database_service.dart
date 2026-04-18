import 'dart:convert';

import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub_graphql/schema.graphql.dart';
import 'package:diohub_graphql/queries/repositories/blame.graphql.dart';
import 'package:diohub_graphql/queries/repositories/create_commit_on_branch.graphql.dart';
import 'package:diohub_graphql/queries/repositories/git_tree.graphql.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/git/file_change.dart';
import 'package:diohub_models/models/repositories/code/blame_block.dart';
import 'package:diohub_models/models/repositories/code/code_gql_mappers.dart';
import 'package:diohub_models/models/repositories/code/code_tree_node.dart';
import 'package:diohub_models/models/repositories/code/directory_last_commit.dart';
import 'package:diohub_models/models/repositories/code/file_content.dart';
import 'package:diohub_models/models/repositories/tree_typedefs.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:lens_annotations/lens_annotations.dart';

@LensService(scope: Scope.repo, group: 'git')
class GitDatabaseService extends EntityService<RepoRef> {
  GitDatabaseService(super.apiClient, super.ref);

  /// Fetches the git tree for the given OID or commit context.
  @Lens(
    'get_tree',
    'Get git tree for a commit or expression.',
    category: ToolCategory.code,
    access: ToolAccess.read,
  )
  Future<TreeData> getTree({
    @Desc('Commit OID') String? oid,
    @Desc('Git expression (e.g., main:src)') String? expression,
  }) async {
    final GQLResponse res;
    if (expression != null) {
      res = await gql.query(
        documentNodeQuerygetFileByExpression,
        Variables$Query$getFileByExpression(
          owner: ref.owner,
          name: ref.name,
          expression: expression,
        ).toJson(),
      );
    } else {
      res = await gql.query(
        documentNodeQuerygetGitTree,
        Variables$Query$getGitTree(
          owner: ref.owner,
          name: ref.name,
          oid: oid!,
        ).toJson(),
      );
    }
    if (expression != null) {
      final Query$getFileByExpression data =
          Query$getFileByExpression.fromJson(res.data!);
      final obj = data.repository?.object;
      if (obj is Query$getFileByExpression$repository$object$$Tree) {
        return obj;
      }
      throw StateError('Expression $expression did not resolve to a tree');
    } else {
      final Query$getGitTree data = Query$getGitTree.fromJson(res.data!);
      final obj = data.repository?.object;
      if (obj is Query$getGitTree$repository$object$$Tree) {
        return obj;
      }
      throw StateError('Object $oid is not a tree');
    }
  }

  /// Fetches a blob by OID.
  ///
  /// Returns GQL blob data (oid, byteSize, isBinary, isTruncated, text).
  @Lens(
    'get_blob',
    'Get git blob by OID.',
    category: ToolCategory.code,
    access: ToolAccess.read,
  )
  Future<BlobData> getBlob(
    @Desc('Blob OID') final String? sha,
  ) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerygetGitBlob,
      Variables$Query$getGitBlob(
        owner: ref.owner,
        name: ref.name,
        oid: sha!,
      ).toJson(),
    );
    final Query$getGitBlob data = Query$getGitBlob.fromJson(res.data!);
    final Query$getGitBlob$repository$object? obj = data.repository?.object;
    if (obj is Query$getGitBlob$repository$object$$Blob) {
      return obj;
    }
    throw StateError('Object $sha is not a blob');
  }

  /// Fetches file contents by Git expression (e.g. `main:lib/foo.dart`). Returns GQL blob data.
  @Lens(
    'get_file_by_expression',
    'Get file contents by git expression.',
    category: ToolCategory.code,
    access: ToolAccess.read,
  )
  Future<ExpressionBlobData> getFileByExpression({
    @Desc('Git expression (e.g., main:lib/foo.dart)')
    required String expression,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerygetFileByExpression,
      Variables$Query$getFileByExpression(
        owner: ref.owner,
        name: ref.name,
        expression: expression,
      ).toJson(),
    );
    final Query$getFileByExpression data =
        Query$getFileByExpression.fromJson(res.data!);
    final Query$getFileByExpression$repository$object? obj =
        data.repository?.object;
    if (obj is Query$getFileByExpression$repository$object$$Blob) {
      return obj;
    }
    throw StateError('Expression $expression did not resolve to a blob');
  }

  /// Fetches git blame for a path at the given expression (e.g. branch or SHA).
  @Lens(
    'get_blame',
    'Get git blame for a file.',
    category: ToolCategory.code,
    access: ToolAccess.read,
  )
  Future<List<BlameRange>> getBlame(
    @Desc('Git expression (branch or SHA)') final String expression,
    @Desc('File path') final String path,
  ) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerygetBlame,
      Variables$Query$getBlame(
        owner: ref.owner,
        name: ref.name,
        expression: expression,
        path: path,
      ).toJson(),
    );
    final Query$getBlame data = Query$getBlame.fromJson(res.data!);
    final obj = data.repository?.object;
    if (obj == null) return <BlameRange>[];
    return obj.maybeWhen(
      commit: (c) => c.blame.ranges.toList(),
      orElse: () => <BlameRange>[],
    );
  }

  /// Fetches directory entries at [expression] (e.g. "main:" or "main:src/lib/"). Returns domain models.
  @Lens(
    'list_directory_entries',
    'List directory contents at a git expression.',
    category: ToolCategory.code,
    access: ToolAccess.read,
  )
  Future<List<CodeTreeNode>> fetchDirectoryEntries(
    @Desc('Git expression (e.g., main:src)') final String expression,
  ) async {
    final TreeData tree = await getTree(expression: expression);
    final entries = tree.entries;
    if (entries == null || entries.isEmpty) return <CodeTreeNode>[];
    return entries.map(codeTreeNodeFromTreeEntry).toList();
  }

  /// Fetches file content at [expression] (e.g. "main:lib/foo.dart").
  /// Returns a [FileContent] domain model.
  @Lens(
    'get_file_content',
    'Get file content at a git expression.',
    category: ToolCategory.code,
    access: ToolAccess.read,
  )
  Future<FileContent> fetchFileContent(
    @Desc('Git expression (e.g., main:lib/foo.dart)') final String expression,
  ) async {
    final ExpressionBlobData blob =
        await getFileByExpression(expression: expression);
    return FileContent(
      oid: blob.oid,
      byteSize: blob.byteSize,
      isBinary: blob.isBinary ?? false,
      isTruncated: blob.isTruncated,
      text: blob.text,
    );
  }

  /// Fetches blame for [path] at [expression] (branch or SHA).
  /// Returns [BlameBlock] domain models.
  @Lens(
    'get_blame_blocks',
    'Get blame blocks for a file.',
    category: ToolCategory.code,
    access: ToolAccess.read,
  )
  Future<List<BlameBlock>> fetchBlame(
    @Desc('Git expression (branch or SHA)') final String expression,
    @Desc('File path') final String path,
  ) async {
    final List<BlameRange> ranges = await getBlame(expression, path);
    return ranges.map(_blameBlockFromRange).toList();
  }

  static BlameBlock _blameBlockFromRange(
    Query$getBlame$repository$object$$Commit$blame$ranges range,
  ) {
    final c = range.commit;
    final parentNodes = c.parents.nodes;
    String? parentOid;
    if (parentNodes != null && parentNodes.isNotEmpty) {
      final firstNode = parentNodes.first;
      parentOid = firstNode != null ? firstNode.oid : null;
    } else {
      parentOid = null;
    }
    String? authorName = c.author?.name;
    String? authorAvatarUrl = c.author?.avatarUrl.toString();
    final user = c.author?.user;
    final String? authorLogin = user?.login;
    final int additions = c.additions;
    final int deletions = c.deletions;
    final bool? isVerified = c.signature?.isValid;
    final String? statusCheckState = c.statusCheckRollup?.state.name;
    int? associatedPRNumber;
    final prNodes = c.associatedPullRequests?.nodes;
    if (prNodes != null && prNodes.isNotEmpty) {
      final first = prNodes.first;
      if (first != null) associatedPRNumber = first.number;
    }
    return BlameBlock(
      age: range.age,
      startingLine: range.startingLine,
      endingLine: range.endingLine,
      commit: BlameCommitSummary(
        oid: c.oid,
        abbreviatedOid: c.abbreviatedOid,
        message: c.message,
        authoredDate: c.authoredDate,
        authorName: authorName,
        authorAvatarUrl: authorAvatarUrl,
        authorLogin: authorLogin,
        parentOid: parentOid,
        additions: additions,
        deletions: deletions,
        isVerified: isVerified,
        statusCheckState: statusCheckState,
        associatedPRNumber: associatedPRNumber,
      ),
    );
  }

  /// Fetches the last commit that touched [path] at [expression] (branch or SHA).
  @Lens(
    'get_last_commit_for_path',
    'Get the last commit that modified a path.',
    category: ToolCategory.code,
    access: ToolAccess.read,
  )
  Future<DirectoryLastCommit?> getLastCommitForPath(
    @Desc('Git expression (branch or SHA)') final String expression,
    @Desc('File or directory path') final String path,
  ) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerygetLastCommitForPath,
      Variables$Query$getLastCommitForPath(
        owner: ref.owner,
        name: ref.name,
        expression: expression,
        path: path,
      ).toJson(),
    );
    final Query$getLastCommitForPath data =
        Query$getLastCommitForPath.fromJson(res.data!);
    final obj = data.repository?.object;
    if (obj == null) return null;
    return obj.maybeWhen(
      commit: (commit) {
        final nodes = commit.history.nodes;
        if (nodes == null || nodes.isEmpty) return null;
        final node = nodes.first;
        if (node == null) return null;
        return DirectoryLastCommit(
          oid: node.oid,
          abbreviatedOid: node.abbreviatedOid,
          message: node.message,
          committedDate: node.committedDate,
          authorName: node.author?.name,
          authorAvatarUrl: node.author?.avatarUrl.toString(),
        );
      },
      orElse: () => null,
    );
  }

  /// Creates a commit on [branchRef] with the given [expectedHeadOid], [message],
  /// [additions] (path + UTF-8 content), and [deletions] (paths).
  ///
  /// Returns the new commit OID on success. Throws on API or validation errors.
  @Lens(
    'commit_file_changes',
    'Create a commit with file changes on a branch.',
    category: ToolCategory.code,
    access: ToolAccess.write,
  )
  Future<String> commitFileChanges({
    @Desc('Branch reference name') required String branchRef,
    @Desc('Expected current head OID') required String expectedHeadOid,
    @Desc('Commit message') required String message,
    @Desc('Files to add or modify') List<FileChange> additions = const [],
    @Desc('File paths to delete') List<String> deletions = const [],
  }) async {
    final Input$CreateCommitOnBranchInput input = Input$CreateCommitOnBranchInput(
      branch: Input$CommittableBranch(
        repositoryNameWithOwner: '${ref.owner}/${ref.name}',
        branchName: branchRef,
      ),
      expectedHeadOid: expectedHeadOid,
      message: Input$CommitMessage(
        headline: message,
      ),
      fileChanges: Input$FileChanges(
        additions: additions.map(
          (final FileChange a) => Input$FileAddition(
            path: a.path,
            contents: base64Encode(utf8.encode(a.content)),
          ),
        ).toList(),
        deletions: deletions.map(
          (final String path) => Input$FileDeletion(
            path: path,
          ),
        ).toList(),
      ),
    );
    final GQLResponse res = await gql.query(
      documentNodeMutationcreateCommitOnBranch,
      Variables$Mutation$createCommitOnBranch(
        input: input,
      ).toJson(),
    );
    final Mutation$createCommitOnBranch data =
        Mutation$createCommitOnBranch.fromJson(res.data!);
    final payload = data.createCommitOnBranch;
    if (payload?.commit == null) {
      throw StateError(
        res.errors?.isNotEmpty == true
            ? res.errors!.map((final e) => e.message).join('; ')
            : 'createCommitOnBranch returned no commit',
      );
    }
    return payload!.commit!.oid;
  }
}
