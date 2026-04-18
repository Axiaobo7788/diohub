import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_mutations.graphql.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:lens_annotations/lens_annotations.dart';

/// Creates issues in a repository. Repo-scoped; use [RepoRef.issueCreation].
@LensService(scope: Scope.repo, group: 'issues')
class IssueCreationService extends EntityService<RepoRef> {
  IssueCreationService(super.apiClient, super.ref);

  /// Create an issue via GraphQL. Returns the new issue number.
  /// [repositoryId] is the repo's GraphQL node ID (caller provides from repo data).
  @Lens(
    'create_issue',
    'Create a new issue in the repository.',
    category: ToolCategory.issue,
    access: ToolAccess.write,
  )
  Future<int?> createIssue({
    @Desc('Repository node ID') required final String repositoryId,
    @Desc('Issue title') required final String title,
    @Desc('Issue body') final String? body,
    @Desc('User node IDs to assign') final List<String>? assigneeIds,
    @Desc('Label node IDs to apply') final List<String>? labelIds,
    @Desc('Milestone node ID') final String? milestoneId,
    @Desc('Issue template name') final String? issueTemplate,
    @Desc('Project node IDs to add to') final List<String>? projectIds,
  }) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationcreateIssue,
      Variables$Mutation$createIssue(
        repositoryId: repositoryId,
        title: title,
        body: body,
        assigneeIds: assigneeIds,
        labelIds: labelIds,
        milestoneId: milestoneId,
        issueTemplate: issueTemplate,
        projectIds: projectIds,
      ).toJson(),
    );
    final Mutation$createIssue data = Mutation$createIssue.fromJson(res.data!);
    return data.createIssue?.issue?.number;
  }
}
