import 'package:built_collection/built_collection.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub_graphql/queries/issues_pulls/assignable_label_mutations.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_info_only.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/pull_info_only.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_models/models/issues/issue_pull_mutation_result.dart';
import 'package:diohub/services/base/node_service.dart';

/// Service for the GraphQL `Labelable` interface (issues and PRs).
class LabelableService extends NodeService {
  const LabelableService(super.apiClient, super.nodeId);

  Future<LabelsMutationResult?> addLabels(final List<String> labelIds) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationaddLabelsToLabelable,
      Variables$Mutation$addLabelsToLabelable(
        labelableId: nodeId,
        labelIds: labelIds,
      ).toJson(),
    );
    final Mutation$addLabelsToLabelable? data =
        Mutation$addLabelsToLabelable.fromJson(res.data!);
    final Mutation$addLabelsToLabelable$addLabelsToLabelable$labelable? labelable =
        data?.addLabelsToLabelable?.labelable;
    if (labelable == null) return null;
    return labelable.maybeWhen(
      issue:
          (final Mutation$addLabelsToLabelable$addLabelsToLabelable$labelable$$Issue
              i) {
        final nodes = i.labels?.nodes;
        if (nodes == null) return null;
        final list =
            BuiltList<IssueLabelNode?>(
          nodes
              .map((n) => n == null
                  ? null
                  : IssueLabelNode.fromJson(
                      n.toJson()))
              .toList(),
        );
        return LabelsMutationResult(issueLabels: list);
      },
      pullRequest:
          (final Mutation$addLabelsToLabelable$addLabelsToLabelable$labelable$$PullRequest
              p) {
        final nodes = p.labels?.nodes;
        if (nodes == null) return null;
        final list =
            BuiltList<PullLabelNode?>(
          nodes
              .map((n) => n == null
                  ? null
                  : PullLabelNode
                      .fromJson(n.toJson()))
              .toList(),
        );
        return LabelsMutationResult(pullLabels: list);
      },
      orElse: () => null,
    );
  }

  Future<LabelsMutationResult?> removeLabels(
      final List<String> labelIds) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationremoveLabelsFromLabelable,
      Variables$Mutation$removeLabelsFromLabelable(
        labelableId: nodeId,
        labelIds: labelIds,
      ).toJson(),
    );
    final Mutation$removeLabelsFromLabelable? data =
        Mutation$removeLabelsFromLabelable.fromJson(res.data!);
    final Mutation$removeLabelsFromLabelable$removeLabelsFromLabelable$labelable?
        labelable = data?.removeLabelsFromLabelable?.labelable;
    if (labelable == null) return null;
    return labelable.maybeWhen(
      issue:
          (final Mutation$removeLabelsFromLabelable$removeLabelsFromLabelable$labelable$$Issue
              i) {
        final nodes = i.labels?.nodes;
        if (nodes == null) return null;
        final list =
            BuiltList<IssueLabelNode?>(
          nodes
              .map((n) => n == null
                  ? null
                  : IssueLabelNode.fromJson(
                      n.toJson()))
              .toList(),
        );
        return LabelsMutationResult(issueLabels: list);
      },
      pullRequest:
          (final Mutation$removeLabelsFromLabelable$removeLabelsFromLabelable$labelable$$PullRequest
              p) {
        final nodes = p.labels?.nodes;
        if (nodes == null) return null;
        final list =
            BuiltList<PullLabelNode?>(
          nodes
              .map((n) => n == null
                  ? null
                  : PullLabelNode
                      .fromJson(n.toJson()))
              .toList(),
        );
        return LabelsMutationResult(pullLabels: list);
      },
      orElse: () => null,
    );
  }
}
