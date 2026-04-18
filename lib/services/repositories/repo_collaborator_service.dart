import 'package:dio/dio.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub_graphql/queries/repositories/repo_lists.graphql.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/collaborator_item.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:diohub/services/base/rest_pagination_helper.dart';

class RepoCollaboratorService extends EntityService<RepoRef> {
  RepoCollaboratorService(super.apiClient, super.ref);

  Future<PaginatedResult<CollaboratorItem>> listCollaborators({
    final int page = 1,
    final int perPage = 30,
    final String affiliation = 'all',
  }) async {
    final Response<dynamic> res = await rest.get<dynamic>(
      '${ref.apiPath}/collaborators',
      queryParameters: <String, dynamic>{
        'page': page,
        'per_page': perPage,
        'affiliation': affiliation,
      },
    );
    final List<Object?> raw = extractListFromResponse<Object?>(res);
    final List<CollaboratorItem> items = raw
        .map((e) => CollaboratorItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return parsePaginatedRestResponse<CollaboratorItem>(
      response: res,
      items: items,
      currentPage: page,
    );
  }

  Future<
          PaginatedResult<
              Query$repoAssignableUsers$repository$assignableUsers$edges?>>
      listAssignableUsersGQL({
    required final int first,
    final String? after,
    final String? query,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQueryrepoAssignableUsers,
      Variables$Query$repoAssignableUsers(
        owner: ref.owner,
        name: ref.name,
        first: first,
        after: after,
        query: query,
      ).toJson(),
    );
    final data =
        Query$repoAssignableUsers.fromJson(res.data!);
    final users =
        data?.repository?.assignableUsers;
    return PaginatedResult.fromEdges(
      users?.edges?.toList() ??
          <Query$repoAssignableUsers$repository$assignableUsers$edges>[],
      users?.pageInfo.hasNextPage ?? false,
      users?.pageInfo.endCursor,
    );
  }
}
