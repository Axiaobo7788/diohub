import 'package:freezed_annotation/freezed_annotation.dart';

part 'code_tree_node.freezed.dart';
part 'code_tree_node.g.dart';

enum CodeEntryKind { file, directory, submodule, symlink }

/// Domain model for a single entry in a git tree (file, directory, submodule, symlink).
/// Isolates UI and providers from GQL-generated types.
@freezed
abstract class CodeTreeNode with _$CodeTreeNode {
  const factory CodeTreeNode({
    required String name,
    required String path,
    required String oid,
    required CodeEntryKind kind,
    required int mode,
    required int size,
    @Default(0) int lineCount,
    String? extension,
    String? languageName,
    String? languageColor,
    @Default(false) bool isGenerated,
    @Default(false) bool isBinary,
    int? byteSize,
    String? submoduleBranch,
    String? submoduleGitUrl,
    String? submoduleCommitOid,
  }) = _CodeTreeNode;

  factory CodeTreeNode.fromJson(Map<String, dynamic> json) =>
      _$CodeTreeNodeFromJson(json);
}
