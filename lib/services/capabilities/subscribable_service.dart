import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub_graphql/schema.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/subscription_mutations.graphql.dart';
import 'package:diohub/services/base/node_service.dart';

/// Service for the GraphQL `Subscribable` interface (issues, PRs, repositories).
class SubscribableService extends NodeService {
  const SubscribableService(super.apiClient, super.nodeId);

  Future<Enum$SubscriptionState?> updateSubscription(
      final Enum$SubscriptionState state) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationupdateSubscription,
      Variables$Mutation$updateSubscription(
        subscribableId: nodeId,
        state: state,
      ).toJson(),
    );
    final Mutation$updateSubscription? data =
        Mutation$updateSubscription.fromJson(res.data!);
    final Mutation$updateSubscription$updateSubscription$subscribable? sub =
        data?.updateSubscription?.subscribable;
    if (sub == null) return null;
    return sub.maybeWhen(
      issue:
          (final Mutation$updateSubscription$updateSubscription$subscribable$$Issue
                  i) =>
              i.viewerSubscription,
      pullRequest:
          (final Mutation$updateSubscription$updateSubscription$subscribable$$PullRequest
                  p) =>
              p.viewerSubscription,
      orElse: () => null,
    );
  }
}
