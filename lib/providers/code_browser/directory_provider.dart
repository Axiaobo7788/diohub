import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/code/code_tree_node.dart';
import 'package:diohub/common/riverpod/keep_alive_helper.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/providers/database_providers.dart';

/// Key for [directoryProvider]: repo + branch (or SHA) + directory path (empty = root).
typedef DirectoryKey = ({RepoRef repo, String branch, String path});

/// Provides the list of [CodeTreeNode] entries for a directory path.
final directoryProvider = AsyncNotifierProvider.autoDispose
    .family<DirectoryNotifier, List<CodeTreeNode>, DirectoryKey>(
  DirectoryNotifier.new,
);

class DirectoryNotifier extends AsyncNotifier<List<CodeTreeNode>> {
  DirectoryNotifier(this._key);
  final DirectoryKey _key;

  @override
  Future<List<CodeTreeNode>> build() async {
    keepAliveFor(ref);
    final String expression =
        _key.path.isEmpty ? '${_key.branch}:' : '${_key.branch}:${_key.path}';
    return _key.repo.gitDb(ref.read(apiClientProvider)).fetchDirectoryEntries(expression);
  }
}
