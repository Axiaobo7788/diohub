import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/code/directory_last_commit.dart';
import 'package:diohub/common/riverpod/keep_alive_helper.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/providers/database_providers.dart';

/// Key for [directoryLastCommitProvider].
typedef LastCommitKey = ({RepoRef repo, String branch, String path});

/// Fetches the last commit that touched a specific path.
/// Designed to be watched lazily per visible tile.
final directoryLastCommitProvider =
    FutureProvider.autoDispose.family<DirectoryLastCommit?, LastCommitKey>(
  (ref, key) async {
    keepAliveFor(ref);
    return key.repo.gitDb(ref.read(apiClientProvider)).getLastCommitForPath(
      key.branch,
      key.path,
    );
  },
);
