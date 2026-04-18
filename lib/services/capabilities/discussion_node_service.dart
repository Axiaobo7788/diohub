import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub_graphql/queries/discussions/discussion_mutations.graphql.dart';
import 'package:diohub_graphql/schema.graphql.dart';
import 'package:diohub/services/base/node_service.dart';

/// Service for GitHub Discussions: poll vote and upvote.
class DiscussionNodeService extends NodeService {
  const DiscussionNodeService(super.apiClient, super.nodeId);

  Future<Mutation$addDiscussionPollVote$addDiscussionPollVote$pollOption?>
      addPollVote(final String pollOptionId) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationaddDiscussionPollVote,
      Variables$Mutation$addDiscussionPollVote(
        input: Input$AddDiscussionPollVoteInput(pollOptionId: pollOptionId),
      ).toJson(),
    );
    final Mutation$addDiscussionPollVote? data =
        Mutation$addDiscussionPollVote.fromJson(res.data!);
    return data?.addDiscussionPollVote?.pollOption;
  }

  Future<Mutation$addDiscussionUpvote$addUpvote$subject?> addUpvote() async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationaddDiscussionUpvote,
      Variables$Mutation$addDiscussionUpvote(
        input: Input$AddUpvoteInput(subjectId: nodeId),
      ).toJson(),
    );
    final Mutation$addDiscussionUpvote? data =
        Mutation$addDiscussionUpvote.fromJson(res.data!);
    return data?.addUpvote?.subject;
  }

  Future<Mutation$removeDiscussionUpvote$removeUpvote$subject?>
      removeUpvote() async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationremoveDiscussionUpvote,
      Variables$Mutation$removeDiscussionUpvote(
        input: Input$RemoveUpvoteInput(subjectId: nodeId),
      ).toJson(),
    );
    final Mutation$removeDiscussionUpvote? data =
        Mutation$removeDiscussionUpvote.fromJson(res.data!);
    return data?.removeUpvote?.subject;
  }
}
