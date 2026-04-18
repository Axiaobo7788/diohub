import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_models/models/commits/commit_model.dart';

/// Pure mapping from PR-files GQL edge to [FileElement] for UI.
/// Kept in lib/common so views do not depend on the pulls service layer.
FileElement fileFromPullFileEdge(
  final PullFileEdge edge,
) {
  final PullFileNode node =
      edge.node!;
  return DiffEntry(
    filename: node.path,
    status: node.changeType.name.toLowerCase(),
    additions: node.additions,
    deletions: node.deletions,
    changes: node.additions + node.deletions,
  );
}
