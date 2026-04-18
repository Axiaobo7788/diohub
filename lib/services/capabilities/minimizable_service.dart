import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub_graphql/schema.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/pr_review_mutations.graphql.dart';
import 'package:diohub/services/base/node_service.dart';

/// Service for the GraphQL `Minimizable` interface (issue/PR comments).
class MinimizableService extends NodeService {
  const MinimizableService(super.apiClient, super.nodeId);

  Future<void> minimize(final Enum$ReportedContentClassifiers classifier) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationminimizeComment,
      Variables$Mutation$minimizeComment(
        subjectId: nodeId,
        classifier: classifier,
      ).toJson(),
    );
    Mutation$minimizeComment.fromJson(res.data!);
  }

  Future<void> unminimize() async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationunminimizeComment,
      Variables$Mutation$unminimizeComment(subjectId: nodeId).toJson(),
    );
    Mutation$unminimizeComment.fromJson(res.data!);
  }
}
