// Convenience typedefs for GQL-generated tree/blob/blame types.
// Import the generated data files so these types resolve.

import 'package:diohub_graphql/queries/repositories/blame.graphql.dart';
import 'package:diohub_graphql/queries/repositories/git_tree.graphql.dart';

/// Root repository object when it is a Tree (has oid + entries).
/// Use this so both getGitTree and getFileByExpression tree results are valid.
typedef TreeData = Fragment$treeFields;

/// A single entry in a tree (file, directory, or submodule).
typedef TreeEntry = Fragment$treeFields$entries;

/// Language fragment on a tree entry.
typedef TreeEntryLanguage = Fragment$treeFields$entries$language;

/// Blob from getGitBlob(oid).
typedef BlobData = Query$getGitBlob$repository$object$$Blob;

/// Blob from getFileByExpression(expression).
typedef ExpressionBlobData = Query$getFileByExpression$repository$object$$Blob;

/// One range from blame(path) on a Commit.
typedef BlameRange = Query$getBlame$repository$object$$Commit$blame$ranges;

extension TreeEntryX on TreeEntry {
  bool get isBlob => type == 'blob';
  bool get isTree => type == 'tree';

  /// Submodule mode in Git.
  bool get isSubmodule => mode == 160000;

  /// Symlink mode.
  bool get isSymlink => mode == 120000;

  /// Executable file mode.
  bool get isExecutable => mode == 100755;

  /// True when entry is a blob and object.isBinary is true.
  bool get isBinaryFile {
    final o = object;
    if (o == null) return false;
    if (o is Fragment$treeFields$entries$object$$Blob) {
      return o.isBinary ?? false;
    }
    return false;
  }
}
