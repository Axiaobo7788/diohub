import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub_graphql/schema.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_reactions.graphql.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub/services/base/node_service.dart';

/// Service for the GraphQL `Reactable` interface (issues, PRs, comments, etc.).
class ReactableService extends NodeService {
  const ReactableService(super.apiClient, super.nodeId);

  Future<List<ReactorsGroup>?> addReaction(
      final Enum$ReactionContent content) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationaddReaction,
      Variables$Mutation$addReaction(
        content: content,
        id: nodeId,
      ).toJson(),
    );
    final Mutation$addReaction? data = Mutation$addReaction.fromJson(res.data!);
    final List<Fragment$reactorsGroup>? list =
        data?.addReaction?.reactionGroups;
    return list;
  }

  Future<List<ReactorsGroup>?> removeReaction(
      final Enum$ReactionContent content) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationremoveReaction,
      Variables$Mutation$removeReaction(
        id: nodeId,
        content: content,
      ).toJson(),
    );
    final Mutation$removeReaction? data = Mutation$removeReaction.fromJson(res.data!);
    final List<Fragment$reactorsGroup>? list =
        data?.removeReaction?.reactionGroups;
    return list;
  }

  Future<List<ReactorsGroupEdge?>> getReactors(
    final Enum$ReactionContent content,
  ) async {
    final page = await getReactorsPage(content, first: 11, after: null);
    return page.items;
  }

  Future<CursorPage<ReactorsGroupEdge?>> getReactorsPage(
    final Enum$ReactionContent content, {
    required final int first,
    final String? after,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerygetReactors,
      Variables$Query$getReactors(
        id: nodeId,
        reactorsFirst: first,
        reactorsAfter: after,
      ).toJson(),
    );
    final data = Query$getReactors.fromJson(res.data!);
    final edges = data.node!.maybeWhen<List<ReactorsGroupEdge?>>(
      issue: (final Query$getReactors$node$$Issue p0) =>
          _reactorsEdgesFromGroups(p0.reactionGroups, content),
      pullRequest: (final Query$getReactors$node$$PullRequest p0) =>
          _reactorsEdgesFromGroups(p0.reactionGroups, content),
      issueComment: (final Query$getReactors$node$$IssueComment p0) =>
          _reactorsEdgesFromGroups(p0.reactionGroups, content),
      pullRequestReviewComment:
          (final Query$getReactors$node$$PullRequestReviewComment p0) =>
              _reactorsEdgesFromGroups(p0.reactionGroups, content),
      discussionComment:
          (final Query$getReactors$node$$DiscussionComment p0) =>
              _reactorsEdgesFromGroups(p0.reactionGroups, content),
      orElse: () => throw UnimplementedError(),
    );
    final Map<String, dynamic> raw = res.data!;
    final pageInfo = _reactorsPageInfoFromRaw(raw, content);
    return CursorPage<ReactorsGroupEdge?>(
      items: edges.toList(),
      hasNextPage: pageInfo.hasNextPage,
      endCursor: pageInfo.endCursor,
    );
  }

  ({bool hasNextPage, String? endCursor}) _reactorsPageInfoFromRaw(
    final Map<String, dynamic> raw,
    final Enum$ReactionContent content,
  ) {
    final contentStr = content.name;
    final node = raw['node'] as Map<String, dynamic>?;
    if (node == null) return (hasNextPage: false, endCursor: null);
    final groups = node['reactionGroups'] as List<dynamic>?;
    if (groups == null) return (hasNextPage: false, endCursor: null);
    for (final g in groups) {
      if (g is! Map<String, dynamic>) continue;
      if (g['content'] != contentStr) continue;
      final reactors = g['reactors'] as Map<String, dynamic>?;
      if (reactors == null) return (hasNextPage: false, endCursor: null);
      final info = reactors['pageInfo'] as Map<String, dynamic>?;
      if (info == null) return (hasNextPage: false, endCursor: null);
      return (
        hasNextPage: info['hasNextPage'] as bool? ?? false,
        endCursor: info['endCursor'] as String?,
      );
    }
    return (hasNextPage: false, endCursor: null);
  }

  Future<List<ReactorsGroup>> getReactionGroups(
      {final bool refresh = false}) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerygetReactors,
      Variables$Query$getReactors(id: nodeId).toJson(),
      refreshCache: refresh,
    );
    return Query$getReactors.fromJson(res.data!)
        .node!
        .maybeWhen<List<ReactorsGroup>>(
          issue: (final Query$getReactors$node$$Issue p0) =>
              _toReactionGroupsList(p0.reactionGroups),
          pullRequest: (final Query$getReactors$node$$PullRequest p0) =>
              _toReactionGroupsList(p0.reactionGroups),
          issueComment: (final Query$getReactors$node$$IssueComment p0) =>
              _toReactionGroupsList(p0.reactionGroups),
          pullRequestReviewComment:
              (final Query$getReactors$node$$PullRequestReviewComment p0) =>
                  _toReactionGroupsList(p0.reactionGroups),
          discussionComment:
              (final Query$getReactors$node$$DiscussionComment p0) =>
                  _toReactionGroupsList(p0.reactionGroups),
          orElse: () => throw UnimplementedError(),
        );
  }

  List<ReactorsGroupEdge?>
      _reactorsEdgesFromGroups<T extends ReactorsGroup>(
    List<T>? groups,
    Enum$ReactionContent content,
  ) {
    if (groups == null || groups.isEmpty) {
      return <ReactorsGroupEdge?>[];
    }
    final g = groups.firstWhere((e) => e.content == content);
    return g.reactors.edges ?? <ReactorsGroupEdge?>[];
  }

  List<ReactorsGroup> _toReactionGroupsList<T extends ReactorsGroup>(
    List<T>? groups,
  ) {
    return groups ?? <ReactorsGroup>[];
  }
}
