import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub/services/repositories/gql_order_helpers.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub_graphql/schema.graphql.dart';
import 'package:diohub_graphql/fragments/release_list_item.graphql.dart';
import 'package:diohub_graphql/queries/repositories/release_assets.graphql.dart';
import 'package:diohub_graphql/queries/repositories/release_by_tag.graphql.dart';
import 'package:diohub_graphql/queries/repositories/releases_list.graphql.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/release_result.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:lens_annotations/lens_annotations.dart';

/// Release and release-asset operations for a repository.
@LensService(scope: Scope.repo, group: 'releases')
class RepoReleaseService extends EntityService<RepoRef> {
  RepoReleaseService(super.apiClient, super.ref);

  @Lens(
    'get_releases_raw',
    'Get raw release list without pagination wrapper.',
    category: ToolCategory.release,
    access: ToolAccess.read,
  )
  Future<List<Query$releasesList$repository$releases$edges>>
  fetchReleasesListGQL({
    @Desc('Number of results') required final int first,
    @Desc('Pagination cursor') final String? after,
    @Desc('Order field for sorting') final Enum$ReleaseOrderField? orderField,
    @Desc('Order direction') final Enum$OrderDirection? orderDirection,
    @Skip() final bool refresh = false,
  }) async {
    final order = buildReleaseOrder(
      field: orderField,
      direction: orderDirection,
    );
    final GQLResponse response = await gql.query(
      documentNodeQueryreleasesList,
      Variables$Query$releasesList(
        owner: ref.owner,
        repo: ref.name,
        first: first,
        after: after,
        orderBy: order,
      ).toJson(),
      refreshCache: refresh,
    );
    final data = Query$releasesList.fromJson(response.data!).repository!;
    final List<Query$releasesList$repository$releases$edges?> edges =
        data.releases.edges?.toList() ??
        <Query$releasesList$repository$releases$edges?>[];
    return edges
        .whereType<Query$releasesList$repository$releases$edges>()
        .toList();
  }

  /// List repository releases (paginated). Requires repo context.
  @Lens(
    'list_releases',
    'List repository releases with optional ordering.',
    category: ToolCategory.release,
    access: ToolAccess.read,
  )
  Future<PaginatedResult<Query$releasesList$repository$releases$edges>>
  fetchReleasesPaginated({
    @Desc('Number of results') required final int first,
    @Desc('Pagination cursor') final String? after,
    @Desc('Order field for sorting') final Enum$ReleaseOrderField? orderField,
    @Desc('Order direction') final Enum$OrderDirection? orderDirection,
    @Skip() final bool refresh = false,
  }) async {
    final order = buildReleaseOrder(
      field: orderField,
      direction: orderDirection,
    );
    final GQLResponse response = await gql.query(
      documentNodeQueryreleasesList,
      Variables$Query$releasesList(
        owner: ref.owner,
        repo: ref.name,
        first: first,
        after: after,
        orderBy: order,
      ).toJson(),
      refreshCache: refresh,
    );
    final data = Query$releasesList.fromJson(response.data!).repository!;
    final List<Query$releasesList$repository$releases$edges?> edges =
        data.releases.edges?.toList() ??
        <Query$releasesList$repository$releases$edges?>[];
    final items = edges
        .whereType<Query$releasesList$repository$releases$edges>()
        .toList();
    final pageInfo = data.releases.pageInfo;
    return PaginatedResult(
      items: items,
      hasNextPage: pageInfo.hasNextPage,
      endCursor: pageInfo.endCursor,
    );
  }

  @Lens(
    'create_release',
    'Create a new release.',
    category: ToolCategory.release,
    access: ToolAccess.write,
  )
  Future<ReleaseResult> createRelease({
    @Desc('Tag name') required final String tagName,
    @Desc('Target branch or commit') final String? targetCommitish,
    @Desc('Release name') final String? name,
    @Desc('Release body') final String? body,
    @Desc('Is draft') final bool draft = false,
    @Desc('Is prerelease') final bool prerelease = false,
    @Desc('Auto-generate release notes')
    final bool generateReleaseNotes = false,
  }) async {
    final response = await rest.post<Map<String, dynamic>>(
      '${ref.apiPath}/releases',
      data: <String, dynamic>{
        'tag_name': tagName,
        if (targetCommitish != null) 'target_commitish': targetCommitish,
        if (name != null) 'name': name,
        if (body != null) 'body': body,
        'draft': draft,
        'prerelease': prerelease,
        'generate_release_notes': generateReleaseNotes,
      },
    );
    return ReleaseResult.fromJson(response.data!);
  }

  @Lens(
    'delete_release',
    'Delete a release.',
    category: ToolCategory.release,
    access: ToolAccess.write,
  )
  Future<void> deleteRelease({
    @Desc('Release ID') required final int releaseId,
  }) async {
    await rest.delete<void>('${ref.apiPath}/releases/$releaseId');
  }

  @Lens(
    'update_release',
    'Update an existing release.',
    category: ToolCategory.release,
    access: ToolAccess.write,
  )
  Future<ReleaseResult> updateRelease({
    @Desc('Release ID') required final int releaseId,
    @Desc('Tag name') final String? tagName,
    @Desc('Release name') final String? name,
    @Desc('Release body') final String? body,
    @Desc('Is draft') final bool? draft,
    @Desc('Is prerelease') final bool? prerelease,
  }) async {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (tagName != null) data['tag_name'] = tagName;
    if (name != null) data['name'] = name;
    if (body != null) data['body'] = body;
    if (draft != null) data['draft'] = draft;
    if (prerelease != null) data['prerelease'] = prerelease;
    final response = await rest.patch<Map<String, dynamic>>(
      '${ref.apiPath}/releases/$releaseId',
      data: data,
    );
    return ReleaseResult.fromJson(response.data ?? <String, dynamic>{});
  }

  @Lens(
    'get_release_by_tag',
    'Get a specific release by tag name.',
    category: ToolCategory.release,
    access: ToolAccess.read,
  )
  Future<Fragment$releaseListItem?> fetchReleaseByTag(
    @Desc('Tag name') final String tagName,
  ) async {
    final GQLResponse response = await gql.query(
      documentNodeQueryreleaseByTag,
      Variables$Query$releaseByTag(
        owner: ref.owner,
        name: ref.name,
        tagName: tagName,
      ).toJson(),
    );
    final data = Query$releaseByTag.fromJson(response.data!);
    return data?.repository?.release;
  }

  @Lens(
    'get_release_assets',
    'Get assets for a release.',
    category: ToolCategory.release,
    access: ToolAccess.read,
  )
  Future<List<ReleaseAssetNode>> fetchReleaseAssets(
    @Desc('Release node ID') final String releaseNodeId, {
    @Desc('Number of results') final int first = 100,
    @Desc('Pagination cursor') final String? after,
  }) async {
    final page = await fetchReleaseAssetsPage(
      releaseNodeId,
      first: first,
      after: after,
    );
    return page.items;
  }

  @Lens(
    'get_release_assets_page',
    'Get assets for a release with pagination metadata.',
    category: ToolCategory.release,
    access: ToolAccess.read,
  )
  Future<CursorPage<ReleaseAssetNode>> fetchReleaseAssetsPage(
    @Desc('Release node ID') final String releaseNodeId, {
    @Desc('Number of results') required final int first,
    @Desc('Pagination cursor') final String? after,
  }) async {
    final GQLResponse response = await gql.query(
      documentNodeQueryreleaseAssets,
      Variables$Query$releaseAssets(
        id: releaseNodeId,
        first: first,
        after: after,
      ).toJson(),
    );
    final data = Query$releaseAssets.fromJson(response.data!);
    final node = data?.node;
    if (node == null) {
      return const CursorPage<ReleaseAssetNode>(items: [], hasNextPage: false);
    }
    return node.maybeWhen(
      release: (final r) {
        final List<ReleaseAssetNode?>? rawNodes = r.releaseAssets.nodes
            ?.toList();
        final items =
            rawNodes?.whereType<ReleaseAssetNode>().toList() ??
            <ReleaseAssetNode>[];
        final pageInfo = r.releaseAssets.pageInfo;
        return CursorPage<ReleaseAssetNode>(
          items: items,
          hasNextPage: pageInfo.hasNextPage,
          endCursor: pageInfo.endCursor,
        );
      },
      orElse: () =>
          const CursorPage<ReleaseAssetNode>(items: [], hasNextPage: false),
    );
  }
}
