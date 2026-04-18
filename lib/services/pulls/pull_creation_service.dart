import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub_graphql/queries/issues_pulls/pull_mutations.graphql.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:lens_annotations/lens_annotations.dart';

/// Creates pull requests in a repository. Repo-scoped; use [RepoRef.pullCreation].
@LensService(scope: Scope.repo, group: 'pulls')
class PullCreationService extends EntityService<RepoRef> {
  PullCreationService(super.apiClient, super.ref);

  /// Create a pull request via GraphQL. Returns the new PR number.
  /// [repositoryId] is the repo's GraphQL node ID (caller provides from repo data).
  @Lens(
    'create_pull_request',
    'Create a new pull request in the repository.',
    category: ToolCategory.pullRequest,
    access: ToolAccess.write,
  )
  Future<int?> createPullRequest({
    @Desc('Repository node ID') required final String repositoryId,
    @Desc('PR title') required final String title,
    @Desc('Base branch ref name') required final String baseRefName,
    @Desc('Head branch ref name') required final String headRefName,
    @Desc('PR body') final String? body,
    @Desc('Is draft PR') final bool? draft,
    @Desc('Head repository node ID (for forks)') final String? headRepositoryId,
    @Desc('Allow maintainer edits') final bool? maintainerCanModify,
  }) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationcreatePullRequest,
      Variables$Mutation$createPullRequest(
        repositoryId: repositoryId,
        title: title,
        body: body,
        baseRefName: baseRefName,
        headRefName: headRefName,
        draft: draft,
        headRepositoryId: headRepositoryId,
        maintainerCanModify: maintainerCanModify,
      ).toJson(),
    );
    final Mutation$createPullRequest data =
        Mutation$createPullRequest.fromJson(res.data!);
    return data.createPullRequest?.pullRequest?.number;
  }
}
