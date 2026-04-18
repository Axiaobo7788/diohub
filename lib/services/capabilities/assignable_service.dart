import 'package:built_collection/built_collection.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub_graphql/queries/issues_pulls/assignable_label_mutations.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_info_only.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/pull_info_only.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_models/models/issues/issue_pull_mutation_result.dart';
import 'package:diohub/services/base/node_service.dart';

/// Service for the GraphQL `Assignable` interface (issues and PRs).
class AssignableService extends NodeService {
  const AssignableService(super.apiClient, super.nodeId);

  Future<AssigneesMutationResult?> addAssignees(
      final List<String> assigneeIds) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationaddAssigneesToAssignable,
      Variables$Mutation$addAssigneesToAssignable(
        assignableId: nodeId,
        assigneeIds: assigneeIds,
      ).toJson(),
    );
    final Mutation$addAssigneesToAssignable? data =
        Mutation$addAssigneesToAssignable.fromJson(res.data!);
    final Mutation$addAssigneesToAssignable$addAssigneesToAssignable$assignable?
        assignable = data?.addAssigneesToAssignable?.assignable;
    if (assignable == null) return null;
    return assignable.maybeWhen(
      issue:
          (final Mutation$addAssigneesToAssignable$addAssigneesToAssignable$assignable$$Issue
              i) {
        final nodes = i.assignees.nodes;
        if (nodes == null) return null;
        final list =
            BuiltList<IssueAssigneeNode?>(
          nodes
              .map((n) => n == null
                  ? null
                  : IssueAssigneeNode
                      .fromJson(n.toJson()))
              .toList(),
        );
        return AssigneesMutationResult(issueAssignees: list);
      },
      pullRequest:
          (final Mutation$addAssigneesToAssignable$addAssigneesToAssignable$assignable$$PullRequest
              p) {
        final nodes = p.assignees.nodes;
        if (nodes == null) return null;
        final list = BuiltList<
            PullAssigneeNode?>(
          nodes
              .map((n) => n == null
                  ? null
                  : PullAssigneeNode
                      .fromJson(n.toJson()))
              .toList(),
        );
        return AssigneesMutationResult(pullAssignees: list);
      },
      orElse: () => null,
    );
  }

  Future<AssigneesMutationResult?> removeAssignees(
    final List<String> assigneeIds,
  ) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationremoveAssigneesFromAssignable,
      Variables$Mutation$removeAssigneesFromAssignable(
        assignableId: nodeId,
        assigneeIds: assigneeIds,
      ).toJson(),
    );
    final Mutation$removeAssigneesFromAssignable? data =
        Mutation$removeAssigneesFromAssignable.fromJson(res.data!);
    final Mutation$removeAssigneesFromAssignable$removeAssigneesFromAssignable$assignable?
        assignable = data?.removeAssigneesFromAssignable?.assignable;
    if (assignable == null) return null;
    return assignable.maybeWhen(
      issue:
          (final Mutation$removeAssigneesFromAssignable$removeAssigneesFromAssignable$assignable$$Issue
              i) {
        final nodes = i.assignees.nodes;
        if (nodes == null) return null;
        final list =
            BuiltList<IssueAssigneeNode?>(
          nodes
              .map((n) => n == null
                  ? null
                  : IssueAssigneeNode
                      .fromJson(n.toJson()))
              .toList(),
        );
        return AssigneesMutationResult(issueAssignees: list);
      },
      pullRequest:
          (final Mutation$removeAssigneesFromAssignable$removeAssigneesFromAssignable$assignable$$PullRequest
              p) {
        final nodes = p.assignees.nodes;
        if (nodes == null) return null;
        final list = BuiltList<
            PullAssigneeNode?>(
          nodes
              .map((n) => n == null
                  ? null
                  : PullAssigneeNode
                      .fromJson(n.toJson()))
              .toList(),
        );
        return AssigneesMutationResult(pullAssignees: list);
      },
      orElse: () => null,
    );
  }
}
