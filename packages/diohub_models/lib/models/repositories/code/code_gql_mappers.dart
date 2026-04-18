// Mappers from GQL tree/blob/blame types to code domain models.
// Only import this file from GitDatabaseService (and tests). Do not use in UI or providers.

import 'package:diohub_graphql/queries/repositories/git_tree.graphql.dart';
import 'package:diohub_models/models/repositories/code/code_tree_node.dart';
import 'package:diohub_models/models/repositories/tree_typedefs.dart';

/// Converts a GQL tree entry to [CodeTreeNode]. Used only in [GitDatabaseService].
CodeTreeNode codeTreeNodeFromTreeEntry(TreeEntry e) {
  final CodeEntryKind kind = e.isTree
      ? CodeEntryKind.directory
      : e.isSubmodule
          ? CodeEntryKind.submodule
          : e.isSymlink
              ? CodeEntryKind.symlink
              : CodeEntryKind.file;
  int? byteSize;
  final bool isBinary = e.isBinaryFile;
  final obj = e.object;
  if (obj is Fragment$treeFields$entries$object$$Blob) {
    byteSize = obj.byteSize;
  }
  return CodeTreeNode(
    name: e.name,
    path: e.path ?? e.name,
    oid: e.oid,
    kind: kind,
    mode: e.mode,
    size: e.size,
    lineCount: e.lineCount ?? 0,
    extension: e.$extension,
    languageName: e.language?.name,
    languageColor: e.language?.color,
    isGenerated: e.isGenerated,
    isBinary: isBinary,
    byteSize: byteSize,
    submoduleBranch: e.submodule?.branch,
    submoduleGitUrl: e.submodule?.gitUrl.toString(),
    // ignore: invalid_null_aware_operator - submodule is nullable; short-circuit is intentional
    submoduleCommitOid: e.submodule?.subprojectCommitOid,
  );
}
