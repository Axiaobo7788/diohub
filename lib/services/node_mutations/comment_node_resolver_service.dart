import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub_graphql/queries/common/resolve_node.graphql.dart';
import 'package:diohub/services/base/base_service.dart';

/// Resolves comment node metadata by ID (e.g. createdAt).
/// Use from providers via [commentNodeResolverServiceProvider] instead of static mixin methods.
class CommentNodeResolverService extends BaseService {
  CommentNodeResolverService(super.apiClient);

  /// Resolve the `createdAt` timestamp for any comment node by ID.
  Future<DateTime?> resolveNodeCreatedAt(final String nodeId) async {
    final GQLResponse response = await gql.query(
      documentNodeQueryresolveNode,
      Variables$Query$resolveNode(id: nodeId).toJson(),
    );
    final Query$resolveNode? data = Query$resolveNode.fromJson(response.data!);
    final Query$resolveNode$node? node = data?.node;
    if (node == null) return null;
    return node.maybeWhen(
      issueComment: (final Query$resolveNode$node$$IssueComment c) =>
          c.createdAt,
      pullRequestReviewComment: (
        final Query$resolveNode$node$$PullRequestReviewComment c,
      ) =>
          c.createdAt,
      discussionComment: (final Query$resolveNode$node$$DiscussionComment c) =>
          c.createdAt,
      orElse: () => null,
    );
  }
}
