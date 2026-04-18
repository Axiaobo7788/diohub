import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/providers/database_providers.dart';

/// Key for [lastCommitProvider].
typedef CommitHistoryKey = ({RepoRef repoRef, String path, String branchRef});

final lastCommitProvider = FutureProvider.autoDispose
    .family<List<CommitEdge>, CommitHistoryKey>((ref, key) {
  final refStr =
      key.branchRef.length == 40 ? null : 'refs/heads/${key.branchRef}';
  final oid = key.branchRef.length == 40 ? key.branchRef : null;
  return key.repoRef.services(ref.read(apiClientProvider)).loadCommitHistoryEdges(
    first: 1,
    path: key.path,
    ref: refStr,
    oid: oid,
  );
});
