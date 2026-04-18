import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub_graphql/queries/issues_pulls/assignable_label_mutations.graphql.dart';
import 'package:diohub_models/models/issues/issue_pull_mutation_result.dart';
import 'package:diohub/services/base/node_service.dart';

/// Service for the GraphQL commentable `Subject` interface (issues and PRs).
class CommentableService extends NodeService {
  const CommentableService(super.apiClient, super.nodeId);

  Future<CommentAddedResult?> addComment({required final String body}) async {
    final GQLResponse response = await gql.mutation(
      documentNodeMutationaddComment,
      Variables$Mutation$addComment(
        subjectId: nodeId,
        body: body,
      ).toJson(),
    );
    final Mutation$addComment? data = Mutation$addComment.fromJson(response.data!);
    final payload = data?.addComment;
    if (payload == null) return null;
    final edge = payload.commentEdge;
    final subject = payload.subject;
    if (edge == null || subject == null) return null;
    final count = subject.maybeWhen(
      issue: (final Mutation$addComment$addComment$subject$$Issue i) =>
          i.comments.totalCount,
      pullRequest:
          (final Mutation$addComment$addComment$subject$$PullRequest p) =>
              p.comments.totalCount,
      orElse: () => 0,
    );
    return CommentAddedResult(commentEdge: edge, commentsTotalCount: count);
  }
}
