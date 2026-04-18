import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub_graphql/queries/repositories/deployments.graphql.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/autolink_item.dart';
import 'package:diohub_models/models/repositories/deploy_key_item.dart';
import 'package:diohub_models/models/repositories/environment.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:diohub/services/base/rest_pagination_helper.dart';
import 'package:lens_annotations/lens_annotations.dart';

/// Deployments, environments, deploy keys, and autolinks for a repository.
@LensService(scope: Scope.repo, group: 'deployments')
class RepoDeploymentService extends EntityService<RepoRef> {
  RepoDeploymentService(super.apiClient, super.ref);

  /// List deployments for the repository. Requires repo context.
  @Lens(
    'list_deployments',
    'List repository deployments with optional environment filter.',
    category: ToolCategory.deployments,
    access: ToolAccess.read,
  )
  Future<Query$repositoryDeployments$repository$deployments> fetchDeployments({
    @Desc('Number of results') final int first = 20,
    @Desc('Pagination cursor') final String? after,
    @Desc('Filter by environment names') final List<String>? environments,
    @Skip() final bool refresh = false,
  }) async {
    final GQLResponse response = await gql.query(
      documentNodeQueryrepositoryDeployments,
      Variables$Query$repositoryDeployments(
        owner: ref.owner,
        name: ref.name,
        first: first,
        after: after,
        environments: environments,
      ).toJson(),
      refreshCache: refresh,
    );
    final Query$repositoryDeployments data =
        Query$repositoryDeployments.fromJson(response.data!);
    return data.repository!.deployments;
  }

  /// List environments for the repository. Requires repo context.
  @Lens(
    'list_environments',
    'List repository environments.',
    category: ToolCategory.deployments,
    access: ToolAccess.read,
  )
  Future<EnvironmentsResponse> listEnvironments({
    @Desc('Results per page') final int perPage = 30,
    @Desc('Page number') final int page = 1,
  }) async {
    final response = await rest.get<Map<String, dynamic>>(
      '${ref.apiPath}/environments',
      queryParameters: <String, dynamic>{'per_page': perPage, 'page': page},
    );
    return EnvironmentsResponse.fromJson(response.data ?? <String, dynamic>{});
  }

  @Lens(
    'delete_environment',
    'Delete a repository environment.',
    category: ToolCategory.deployments,
    access: ToolAccess.write,
  )
  Future<void> deleteEnvironment({
    @Desc('Environment name to delete') required final String environmentName,
  }) async {
    await rest.delete<void>('${ref.apiPath}/environments/$environmentName');
  }

  @Lens(
    'list_deploy_keys',
    'List repository deploy keys.',
    category: ToolCategory.deployments,
    access: ToolAccess.read,
  )
  Future<PaginatedResult<DeployKeyItem>> listDeployKeys({
    @Desc('Page number') final int page = 1,
    @Desc('Results per page') final int perPage = 30,
  }) async {
    final response = await rest.get<dynamic>(
      '${ref.apiPath}/keys',
      queryParameters: <String, dynamic>{'page': page, 'per_page': perPage},
    );
    final List<Object?> list = extractListFromResponse<Object?>(response);
    final items = list
        .map(
          (e) => DeployKeyItem.fromJson(
            Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
          ),
        )
        .toList();
    return parsePaginatedRestResponse(
      response: response,
      items: items,
      currentPage: page,
    );
  }

  @Lens(
    'list_autolinks',
    'List repository autolink references.',
    category: ToolCategory.deployments,
    access: ToolAccess.read,
  )
  Future<PaginatedResult<AutolinkItem>> listAutolinks({
    @Desc('Page number') final int page = 1,
    @Desc('Results per page') final int perPage = 30,
  }) async {
    final response = await rest.get<dynamic>(
      '${ref.apiPath}/autolinks',
      queryParameters: <String, dynamic>{'page': page, 'per_page': perPage},
    );
    final List<Object?> list = extractListFromResponse<Object?>(response);
    final items = list
        .map(
          (e) => AutolinkItem.fromJson(
            Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
          ),
        )
        .toList();
    return parsePaginatedRestResponse<AutolinkItem>(
      response: response,
      items: items,
      currentPage: page,
    );
  }

  @Lens(
    'create_deploy_key',
    'Create a new deploy key for the repository.',
    category: ToolCategory.deployments,
    access: ToolAccess.write,
  )
  Future<DeployKeyItem> createDeployKey({
    @Desc('Deploy key title') required final String title,
    @Desc('SSH public key content') required final String key,
    @Desc('Whether key is read-only') final bool readOnly = true,
  }) async {
    final response = await rest.post<Map<String, dynamic>>(
      '${ref.apiPath}/keys',
      data: <String, dynamic>{
        'title': title,
        'key': key,
        'read_only': readOnly,
      },
    );
    return DeployKeyItem.fromJson(response.data!);
  }

  @Lens(
    'delete_deploy_key',
    'Delete a deploy key.',
    category: ToolCategory.deployments,
    access: ToolAccess.write,
  )
  Future<void> deleteDeployKey(@Desc('Deploy key ID') final int keyId) async {
    await rest.delete<void>('${ref.apiPath}/keys/$keyId');
  }

  @Lens(
    'create_autolink',
    'Create a new autolink reference.',
    category: ToolCategory.deployments,
    access: ToolAccess.write,
  )
  Future<AutolinkItem> createAutolink({
    @Desc('Key prefix (e.g., "JIRA-")') required final String keyPrefix,
    @Desc('URL template with <num> placeholder')
    required final String urlTemplate,
    @Desc('Whether reference is alphanumeric') final bool isAlphanumeric = true,
  }) async {
    final response = await rest.post<Map<String, dynamic>>(
      '${ref.apiPath}/autolinks',
      data: <String, dynamic>{
        'key_prefix': keyPrefix,
        'url_template': urlTemplate,
        'is_alphanumeric': isAlphanumeric,
      },
    );
    return AutolinkItem.fromJson(response.data!);
  }

  @Lens(
    'delete_autolink',
    'Delete an autolink reference.',
    category: ToolCategory.deployments,
    access: ToolAccess.write,
  )
  Future<void> deleteAutolink(
    @Desc('Autolink reference ID') final int autolinkId,
  ) async {
    await rest.delete<void>('${ref.apiPath}/autolinks/$autolinkId');
  }
}
