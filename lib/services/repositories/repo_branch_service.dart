import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub/services/repositories/gql_order_helpers.dart';
import 'package:diohub_graphql/schema.graphql.dart';
import 'package:diohub_graphql/queries/repositories/branches_list.graphql.dart';
import 'package:diohub_graphql/queries/repositories/ref_mutations.graphql.dart';
import 'package:diohub_graphql/queries/repositories/tags_list.graphql.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/branch_rename_result.dart';
import 'package:diohub_models/models/repositories/create_ref_name.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:lens_annotations/lens_annotations.dart';

/// Branch, tag, and ref operations for a repository.
@LensService(scope: Scope.repo, group: 'branches')
class RepoBranchService extends EntityService<RepoRef> {
  RepoBranchService(super.apiClient, super.ref);

  @Lens(
    'get_branches_raw',
    'Get raw branch list without pagination wrapper.',
    category: ToolCategory.branches,
    access: ToolAccess.read,
  )
  Future<List<Query$branchesList$repository$refs$edges>> fetchBranchListGQL({
    @Desc('Number of results') required final int first,
    @Desc('Pagination cursor') final String? after,
    @Desc('Search query') final String? query,
    @Desc('Sort field: ALPHABETICAL, TAG_COMMIT_DATE')
    final Enum$RefOrderField? orderField,
    @Desc('Sort direction: ASC, DESC')
    final Enum$OrderDirection? orderDirection,
    @Skip() final bool refresh = false,
  }) async {
    final order = buildRefOrder(field: orderField, direction: orderDirection);
    final GQLResponse response = await gql.query(
      documentNodeQuerybranchesList,
      Variables$Query$branchesList(
        owner: ref.owner,
        repo: ref.name,
        first: first,
        after: after,
        query: query,
        orderBy: order,
        defaultBranchName: '',
        includeCompare: false,
      ).toJson(),
      refreshCache: refresh,
    );
    final data = Query$branchesList.fromJson(response.data!).repository!;
    final List<Query$branchesList$repository$refs$edges?> edges =
        data.refs?.edges?.toList() ??
        <Query$branchesList$repository$refs$edges?>[];

    return edges.whereType<Query$branchesList$repository$refs$edges>().toList();
  }

  /// Return repository branch names (paginated). Requires repo context.
  @Lens(
    'list_branches',
    'List repository branches with optional search query and ordering.',
    category: ToolCategory.branches,
    access: ToolAccess.read,
  )
  Future<PaginatedResult<Query$branchesList$repository$refs$edges>>
  fetchBranchesPaginated({
    @Desc('Number of results') required final int first,
    @Desc('Pagination cursor') final String? after,
    @Desc('Search query') final String? query,
    @Desc('Sort field: ALPHABETICAL, TAG_COMMIT_DATE')
    final Enum$RefOrderField? orderField,
    @Desc('Sort direction: ASC, DESC')
    final Enum$OrderDirection? orderDirection,
    @Skip() final bool refresh = false,
    @Skip() final String? defaultBranchName,
  }) async {
    final order = buildRefOrder(field: orderField, direction: orderDirection);
    final bool includeCompare =
        defaultBranchName != null && defaultBranchName.isNotEmpty;
    final GQLResponse response = await gql.query(
      documentNodeQuerybranchesList,
      Variables$Query$branchesList(
        owner: ref.owner,
        repo: ref.name,
        first: first,
        after: after,
        query: query,
        orderBy: order,
        defaultBranchName: defaultBranchName ?? '',
        includeCompare: includeCompare,
      ).toJson(),
      refreshCache: refresh,
    );
    final data = Query$branchesList.fromJson(response.data!).repository!;
    final List<Query$branchesList$repository$refs$edges?> edges =
        data.refs?.edges?.toList() ??
        <Query$branchesList$repository$refs$edges?>[];
    final pageInfo = data.refs?.pageInfo;
    return PaginatedResult(
      items: edges
          .whereType<Query$branchesList$repository$refs$edges>()
          .toList(),
      hasNextPage: pageInfo?.hasNextPage ?? false,
      endCursor: pageInfo?.endCursor,
    );
  }

  /// Paginated tags for [SliverListBody].
  @Lens(
    'list_tags',
    'List repository tags with optional search query and ordering.',
    category: ToolCategory.branches,
    access: ToolAccess.read,
  )
  Future<PaginatedResult<Query$tagsList$repository$refs$edges>>
  fetchTagsPaginated({
    @Desc('Number of results') required final int first,
    @Desc('Pagination cursor') final String? after,
    @Desc('Search query') final String? query,
    @Desc('Sort field: ALPHABETICAL, TAG_COMMIT_DATE')
    final Enum$RefOrderField? orderField,
    @Desc('Sort direction: ASC, DESC')
    final Enum$OrderDirection? orderDirection,
    @Skip() final bool refresh = false,
  }) async {
    final order = buildRefOrder(
      field: orderField,
      direction: orderDirection,
      defaultField: Enum$RefOrderField.TAG_COMMIT_DATE,
      defaultDirection: Enum$OrderDirection.DESC,
    );
    final GQLResponse response = await gql.query(
      documentNodeQuerytagsList,
      Variables$Query$tagsList(
        owner: ref.owner,
        repo: ref.name,
        first: first,
        after: after,
        query: query,
        orderBy: order,
      ).toJson(),
      refreshCache: refresh,
    );
    final data = Query$tagsList.fromJson(response.data!).repository!;
    final List<Query$tagsList$repository$refs$edges?> edges =
        data.refs?.edges?.toList() ?? <Query$tagsList$repository$refs$edges?>[];
    final pageInfo = data.refs?.pageInfo;
    return PaginatedResult(
      items: edges.whereType<Query$tagsList$repository$refs$edges>().toList(),
      hasNextPage: pageInfo?.hasNextPage ?? false,
      endCursor: pageInfo?.endCursor,
    );
  }

  /// Paginated tags list (GraphQL). [orderBy] defaults to ALPHABETICAL ASC.
  @Lens(
    'get_tags_raw',
    'Get raw tag list without pagination wrapper.',
    category: ToolCategory.branches,
    access: ToolAccess.read,
  )
  Future<List<Query$tagsList$repository$refs$edges>> fetchTagsListGQL({
    @Desc('Number of results') required final int first,
    @Desc('Pagination cursor') final String? after,
    @Desc('Search query') final String? query,
    @Desc('Order field for sorting') final Enum$RefOrderField? orderField,
    @Desc('Order direction') final Enum$OrderDirection? orderDirection,
    @Skip() final bool refresh = false,
  }) async {
    final order = buildRefOrder(field: orderField, direction: orderDirection);
    final GQLResponse response = await gql.query(
      documentNodeQuerytagsList,
      Variables$Query$tagsList(
        owner: ref.owner,
        repo: ref.name,
        first: first,
        after: after,
        query: query,
        orderBy: order,
      ).toJson(),
      refreshCache: refresh,
    );
    final data = Query$tagsList.fromJson(response.data!).repository!;
    final List<Query$tagsList$repository$refs$edges?> edges =
        data.refs?.edges?.toList() ?? <Query$tagsList$repository$refs$edges?>[];
    return edges.whereType<Query$tagsList$repository$refs$edges>().toList();
  }

  /// Create a ref (branch or tag) via GraphQL createRef.
  @Lens(
    'create_ref',
    'Create a new branch or tag reference.',
    category: ToolCategory.branches,
    access: ToolAccess.write,
  )
  Future<void> createRef({
    @Desc('Repository node ID') required final String repositoryId,
    @Desc('Ref type: branch or tag') required final String refType,
    @Desc('Branch or tag name') required final String refName,
    @Desc('Commit OID') required final String oid,
  }) async {
    final ref = switch (refType) {
      'tag' => CreateRefName.tag(refName),
      _ => CreateRefName.branch(refName),
    };
    await gql.mutation(
      documentNodeMutationcreateRef,
      Variables$Mutation$createRef(
        repositoryId: repositoryId,
        name: ref.qualifiedName,
        oid: oid,
      ).toJson(),
    );
  }

  /// Delete a ref (branch or tag) via GraphQL deleteRef.
  @Lens(
    'delete_ref',
    'Delete a branch or tag reference.',
    category: ToolCategory.branches,
    access: ToolAccess.write,
  )
  Future<void> deleteRef({
    @Desc('Ref node ID') required final String refId,
  }) async {
    await gql.mutation(
      documentNodeMutationdeleteRef,
      Variables$Mutation$deleteRef(refId: refId).toJson(),
    );
  }

  /// Rename a branch. REST POST /repos/{owner}/{repo}/branches/{branch}/rename
  @Lens(
    'rename_branch',
    'Rename a branch.',
    category: ToolCategory.branches,
    access: ToolAccess.write,
  )
  Future<BranchRenameResult> renameBranch({
    @Desc('Current branch name') required final String branch,
    @Desc('New branch name') required final String newName,
  }) async {
    final response = await rest.post<Map<String, dynamic>>(
      '${ref.apiPath}/branches/$branch/rename',
      data: <String, dynamic>{'new_name': newName},
    );
    return BranchRenameResult.fromJson(response.data!);
  }
}
