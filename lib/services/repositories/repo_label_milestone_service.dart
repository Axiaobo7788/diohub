import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub_graphql/schema.graphql.dart';
import 'package:diohub_graphql/queries/repositories/label_mutations.graphql.dart';
import 'package:diohub_graphql/queries/repositories/repo_lists.graphql.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/milestone_result.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:lens_annotations/lens_annotations.dart';

/// Labels and milestones for a repository.
@LensService(scope: Scope.repo, group: 'labels_milestones')
class RepoLabelMilestoneService extends EntityService<RepoRef> {
  RepoLabelMilestoneService(super.apiClient, super.ref);

  /// List repository labels (paginated). Requires repo context.
  @Lens(
    'list_labels',
    'List repository labels.',
    category: ToolCategory.label,
    access: ToolAccess.read,
  )
  Future<PaginatedResult<Query$repoLabels$repository$labels$edges?>>
  listAvailableLabelsGQL({
    @Desc('Number of results') required final int first,
    @Desc('Pagination cursor') final String? after,
    @Desc('Search query') final String? query,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQueryrepoLabels,
      Variables$Query$repoLabels(
        owner: ref.owner,
        name: ref.name,
        first: first,
        after: after,
        query: query,
      ).toJson(),
    );
    final data = Query$repoLabels.fromJson(res.data!);
    final labels = data?.repository?.labels;
    return PaginatedResult.fromEdges(
      labels?.edges?.toList() ?? <Query$repoLabels$repository$labels$edges?>[],
      labels?.pageInfo.hasNextPage ?? false,
      labels?.pageInfo.endCursor,
    );
  }

  @Lens(
    'create_label',
    'Create a new label.',
    category: ToolCategory.label,
    access: ToolAccess.write,
  )
  Future<Mutation$createLabel$createLabel$label?> createLabel({
    @Desc('Repository node ID') required final String repositoryId,
    @Desc('Label name') required final String name,
    @Desc('Label color (hex without #)') required final String color,
    @Desc('Label description') final String? description,
  }) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationcreateLabel,
      Variables$Mutation$createLabel(
        repositoryId: repositoryId,
        name: name,
        color: color,
        description: description,
      ).toJson(),
    );
    final data = Mutation$createLabel.fromJson(res.data!);
    return data?.createLabel?.label;
  }

  @Lens(
    'update_label',
    'Update an existing label.',
    category: ToolCategory.label,
    access: ToolAccess.write,
  )
  Future<Mutation$updateLabel$updateLabel$label?> updateLabel({
    @Desc('Label node ID') required final String labelId,
    @Desc('New label name') final String? name,
    @Desc('New label color (hex without #)') final String? color,
    @Desc('New label description') final String? description,
  }) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationupdateLabel,
      Variables$Mutation$updateLabel(
        id: labelId,
        name: name,
        color: color,
        description: description,
      ).toJson(),
    );
    final data = Mutation$updateLabel.fromJson(res.data!);
    return data?.updateLabel?.label;
  }

  @Lens(
    'delete_label',
    'Delete a label.',
    category: ToolCategory.label,
    access: ToolAccess.write,
  )
  Future<void> deleteLabel({
    @Desc('Label node ID') required final String labelId,
  }) async {
    await gql.mutation(
      documentNodeMutationdeleteLabel,
      Variables$Mutation$deleteLabel(id: labelId).toJson(),
    );
  }

  /// List repository milestones (paginated). Requires repo context.
  @Lens(
    'list_milestones',
    'List repository milestones.',
    category: ToolCategory.milestone,
    access: ToolAccess.read,
  )
  Future<
    PaginatedResult<Query$repositoryMilestones$repository$milestones$edges?>
  >
  listMilestonesGQL({
    @Desc('Number of results') required final int first,
    @Desc('Pagination cursor') final String? after,
    @Desc('Filter by states (OPEN, CLOSED)')
    final List<Enum$MilestoneState>? states,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQueryrepositoryMilestones,
      Variables$Query$repositoryMilestones(
        owner: ref.owner,
        name: ref.name,
        first: first,
        after: after,
        states: states,
      ).toJson(),
    );
    final data = Query$repositoryMilestones.fromJson(res.data!);
    final milestones = data?.repository?.milestones;
    return PaginatedResult.fromEdges(
      milestones?.edges?.toList() ??
          <Query$repositoryMilestones$repository$milestones$edges>[],
      milestones?.pageInfo.hasNextPage ?? false,
      milestones?.pageInfo.endCursor,
    );
  }

  @Lens(
    'create_milestone',
    'Create a new milestone.',
    category: ToolCategory.milestone,
    access: ToolAccess.write,
  )
  Future<MilestoneResult> createMilestone({
    @Desc('Milestone title') required final String title,
    @Desc('Milestone description') final String? description,
    @Desc('Due date') final DateTime? dueOn,
  }) async {
    final response = await rest.post(
      '/repos/${ref.owner}/${ref.name}/milestones',
      data: <String, dynamic>{
        'title': title,
        if (description != null) 'description': description,
        if (dueOn != null) 'due_on': dueOn.toUtc().toIso8601String(),
      },
    );
    return MilestoneResult.fromJson(response.data as Map<String, dynamic>);
  }

  @Lens(
    'update_milestone',
    'Update an existing milestone.',
    category: ToolCategory.milestone,
    access: ToolAccess.write,
  )
  Future<MilestoneResult> updateMilestone({
    @Desc('Milestone number') required final int milestoneNumber,
    @Desc('New milestone title') final String? title,
    @Desc('New milestone description') final String? description,
    @Desc('New due date') final DateTime? dueOn,
    @Desc('State: open or closed') final String? state,
  }) async {
    final response = await rest.patch(
      '/repos/${ref.owner}/${ref.name}/milestones/$milestoneNumber',
      data: <String, dynamic>{
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (dueOn != null) 'due_on': dueOn.toUtc().toIso8601String(),
        if (state != null) 'state': state,
      },
    );
    return MilestoneResult.fromJson(response.data as Map<String, dynamic>);
  }

  @Lens(
    'delete_milestone',
    'Delete a milestone.',
    category: ToolCategory.milestone,
    access: ToolAccess.write,
  )
  Future<void> deleteMilestone({
    @Desc('Milestone number') required final int milestoneNumber,
  }) async {
    await rest.delete(
      '/repos/${ref.owner}/${ref.name}/milestones/$milestoneNumber',
    );
  }
}
