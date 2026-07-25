import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/providers/resource_runtime/resource_runtime_provider.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/code/code_tree_node.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Existing directory identity used by Code pages.
typedef DirectoryKey = ({RepoRef repo, String branch, String path});

typedef DirectoryResourceSpecFactory =
    ResourceSpec<List<CodeTreeNode>> Function({
      required DirectoryKey key,
      required ResourceScope scope,
    });

const ResourcePolicy repositoryDirectoryResourcePolicy = ResourcePolicy(
  freshFor: Duration(minutes: 2),
  retainFor: Duration(minutes: 5),
);

ResourceSpec<List<CodeTreeNode>> repositoryDirectoryResourceSpec({
  required final DirectoryKey key,
  required final ResourceScope scope,
  required final ApiClient apiClient,
}) {
  final String path = key.path.isEmpty ? '/' : key.path;
  final String repository = '${key.repo.owner}/${key.repo.name}';
  final String identity = [
    Uri.encodeComponent(key.repo.owner),
    Uri.encodeComponent(key.repo.name),
    Uri.encodeComponent(key.branch),
    Uri.encodeComponent(path),
  ].join('/');
  return ResourceSpec<List<CodeTreeNode>>(
    id: ResourceId<List<CodeTreeNode>>(
      kind: 'repository-code-directory',
      version: 1,
      scope: scope,
      key: identity,
    ),
    policy: repositoryDirectoryResourcePolicy,
    tags: <ResourceTag>{
      ResourceTag('repository', repository),
      ResourceTag('repository-branch', '$repository\u0000${key.branch}'),
      ResourceTag(
        'repository-directory',
        '$repository\u0000${key.branch}\u0000$path',
      ),
    },
    contract: 'git-database-fetch-directory-entries-v1',
    load: (final ResourceLoadContext _) async {
      final String expression = key.path.isEmpty
          ? '${key.branch}:'
          : '${key.branch}:${key.path}';
      final List<CodeTreeNode> entries = await key.repo
          .gitDb(apiClient)
          .fetchDirectoryEntries(expression);
      return ResourceLoadResult<List<CodeTreeNode>>(
        data: entries,
        estimatedWeight: entries.isEmpty ? 1 : entries.length,
      );
    },
  );
}

final directoryResourceSpecFactoryProvider =
    Provider<DirectoryResourceSpecFactory>((final Ref ref) {
      final ApiClient apiClient = ref.watch(apiClientProvider);
      return ({
        required final DirectoryKey key,
        required final ResourceScope scope,
      }) => repositoryDirectoryResourceSpec(
        key: key,
        scope: scope,
        apiClient: apiClient,
      );
    });

Set<ResourceTag> repositoryDirectoryInvalidationTags({
  required final RepoRef repo,
  required final String branch,
  required final String path,
}) {
  final String repository = '${repo.owner}/${repo.name}';
  final String normalizedPath = path.isEmpty ? '/' : path;
  return <ResourceTag>{
    ResourceTag(
      'repository-directory',
      '$repository\u0000$branch\u0000$normalizedPath',
    ),
  };
}

void invalidateRepositoryDirectoryResource({
  required final ResourceRuntime runtime,
  required final ResourceScope scope,
  required final RepoRef repo,
  required final String branch,
  required final String path,
}) {
  runtime.invalidate(
    ResourceSelector.forTags(
      repositoryDirectoryInvalidationTags(
        repo: repo,
        branch: branch,
        path: path,
      ),
      scope: scope,
    ),
  );
}

String repositoryFileParentPath(final String filePath) {
  final int separator = filePath.lastIndexOf('/');
  return separator < 0 ? '' : filePath.substring(0, separator);
}

void invalidateRepositoryDirectoriesForFiles({
  required final ResourceRuntime runtime,
  required final ResourceScope scope,
  required final RepoRef repo,
  required final String branch,
  required final Iterable<String> filePaths,
}) {
  for (final String parentPath
      in filePaths.map(repositoryFileParentPath).toSet()) {
    invalidateRepositoryDirectoryResource(
      runtime: runtime,
      scope: scope,
      repo: repo,
      branch: branch,
      path: parentPath,
    );
  }
}

PrefetchTicket? prefetchRepositoryRootDirectory(
  final WidgetRef ref, {
  required final RepoRef repo,
  required final String branch,
}) {
  final ResourceScope? scope = ref.read(activeResourceScopeProvider);
  if (scope == null || branch.isEmpty) return null;
  final DirectoryResourceSpecFactory specFactory = ref.read(
    directoryResourceSpecFactoryProvider,
  );
  return ref
      .read(resourceRuntimeProvider)
      .prefetch(
        specFactory(key: (repo: repo, branch: branch, path: ''), scope: scope),
      );
}
