import 'package:dio/dio.dart';
import 'package:diohub/common/markdown_view/markdown_render_artifact.dart';
import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/models/repository_document.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef RepositoryReadmeKey = ({RepoRef repoRef, String branch});

/// README source and its immutable rendering input.
final class RepositoryReadmeArtifact {
  const RepositoryReadmeArtifact({
    required this.document,
    required this.renderArtifact,
  });

  final RepositoryDocument document;
  final MarkdownRenderArtifact renderArtifact;
}

final class RepositoryReadmeResourceSpecs {
  const RepositoryReadmeResourceSpecs({
    required this.source,
    required this.artifact,
  });

  final ResourceSpec<RepositoryDocument?> source;
  final ResourceSpec<RepositoryReadmeArtifact?> artifact;
}

typedef RepositoryReadmeResourceSpecFactory =
    RepositoryReadmeResourceSpecs Function({
      required RepositoryReadmeKey key,
      required ResourceScope scope,
    });

const ResourcePolicy repositoryReadmeSourcePolicy = ResourcePolicy(
  freshFor: Duration(minutes: 2),
  retainFor: Duration(minutes: 10),
);

const ResourcePolicy repositoryReadmeArtifactPolicy = ResourcePolicy(
  freshFor: Duration(minutes: 2),
  retainFor: Duration(minutes: 10),
  estimatedWeight: 2,
);

ResourceId<RepositoryDocument?> repositoryReadmeSourceResourceId({
  required final RepositoryReadmeKey key,
  required final ResourceScope scope,
}) => ResourceId<RepositoryDocument?>(
  kind: 'repository-readme-source',
  version: 1,
  scope: scope,
  key: _repositoryReadmeIdentity(key),
);

ResourceId<RepositoryReadmeArtifact?> repositoryReadmeArtifactResourceId({
  required final RepositoryReadmeKey key,
  required final ResourceScope scope,
}) => ResourceId<RepositoryReadmeArtifact?>(
  kind: 'repository-readme-artifact',
  version: 1,
  scope: scope,
  key: _repositoryReadmeIdentity(key),
);

RepositoryReadmeResourceSpecs repositoryReadmeResourceSpecs({
  required final RepositoryReadmeKey key,
  required final ResourceScope scope,
  required final ApiClient apiClient,
}) {
  final String repository = key.repoRef.fullName;
  final Set<ResourceTag> tags = <ResourceTag>{
    ResourceTag('repository', repository),
    ResourceTag('repository-branch', '$repository\u0000${key.branch}'),
    ResourceTag(
      'repository-document',
      '$repository\u0000${key.branch}\u0000readme',
    ),
  };
  final ResourceSpec<RepositoryDocument?> source =
      ResourceSpec<RepositoryDocument?>(
        id: repositoryReadmeSourceResourceId(key: key, scope: scope),
        policy: repositoryReadmeSourcePolicy,
        tags: tags,
        contract: 'repository-services-fetch-readme-html-v1',
        workKind: ResourceWorkKind.network,
        load: (final ResourceLoadContext _) async {
          try {
            final String content = await key.repoRef
                .services(apiClient)
                .fetchReadmeHtml(branch: key.branch);
            return ResourceLoadResult<RepositoryDocument?>(
              data: RepositoryDocument(
                kind: RepositoryDocumentKind.readme,
                branch: key.branch,
                content: content,
                format: RepositoryDocumentFormat.html,
              ),
              estimatedWeight: _contentWeight(content),
            );
          } on DioException catch (error) {
            if (error.response?.statusCode == 404) {
              return const ResourceLoadResult<RepositoryDocument?>(data: null);
            }
            rethrow;
          }
        },
      );
  final ResourceSpec<RepositoryReadmeArtifact?> artifact =
      ResourceSpec<RepositoryReadmeArtifact?>(
        id: repositoryReadmeArtifactResourceId(key: key, scope: scope),
        policy: repositoryReadmeArtifactPolicy,
        tags: tags,
        contract: 'repository-readme-markdown-artifact-v1',
        workKind: ResourceWorkKind.compute,
        dependencies: <ResourceId<dynamic>>{source.id},
        load: (final ResourceLoadContext context) async {
          final ResourceLoadResult<RepositoryDocument?> sourceResult =
              await context.require(source);
          final RepositoryDocument? document = sourceResult.data;
          if (document == null) {
            return const ResourceLoadResult<RepositoryReadmeArtifact?>(
              data: null,
              origin: ResourceOrigin.derived,
            );
          }
          final MarkdownRenderArtifact renderArtifact = await context
              .runInWorker<String, MarkdownRenderArtifact>(
                document.content,
                parseMarkdownRenderArtifact,
              );
          return ResourceLoadResult<RepositoryReadmeArtifact?>(
            data: RepositoryReadmeArtifact(
              document: document,
              renderArtifact: renderArtifact,
            ),
            origin: ResourceOrigin.derived,
            estimatedWeight: renderArtifact.estimatedWeight,
          );
        },
      );
  return RepositoryReadmeResourceSpecs(source: source, artifact: artifact);
}

final Provider<RepositoryReadmeResourceSpecFactory>
repositoryReadmeResourceSpecFactoryProvider =
    Provider<RepositoryReadmeResourceSpecFactory>((final Ref ref) {
      final ApiClient apiClient = ref.watch(apiClientProvider);
      return ({
        required final RepositoryReadmeKey key,
        required final ResourceScope scope,
      }) => repositoryReadmeResourceSpecs(
        key: key,
        scope: scope,
        apiClient: apiClient,
      );
    });

void invalidateRepositoryReadmeResource({
  required final ResourceRuntime runtime,
  required final ResourceScope scope,
  required final RepositoryReadmeKey key,
}) {
  runtime.invalidate(
    ResourceSelector.forId(
      repositoryReadmeSourceResourceId(key: key, scope: scope),
    ),
  );
}

void invalidateRepositoryReadmeForFiles({
  required final ResourceRuntime runtime,
  required final ResourceScope scope,
  required final RepoRef repo,
  required final String branch,
  required final Iterable<String> filePaths,
}) {
  final bool changesRootReadme = filePaths.any((final String path) {
    if (path.contains('/')) return false;
    final String name = path.toLowerCase();
    return name == 'readme' || name.startsWith('readme.');
  });
  if (!changesRootReadme) {
    return;
  }
  invalidateRepositoryReadmeResource(
    runtime: runtime,
    scope: scope,
    key: (repoRef: repo, branch: branch),
  );
}

String _repositoryReadmeIdentity(final RepositoryReadmeKey key) => <String>[
  Uri.encodeComponent(key.repoRef.owner),
  Uri.encodeComponent(key.repoRef.name),
  Uri.encodeComponent(key.branch),
  'readme',
].join('/');

int _contentWeight(final String content) =>
    resourceWeightForBytes(content.length).clamp(1, 256);
