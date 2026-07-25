import 'package:diohub/common/markdown_view/markdown_render_artifact.dart';
import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/models/repository_document.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/services/repositories/repository_document_service.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef RepositoryDocumentResourceKey = ({
  RepoRef repoRef,
  String branch,
  RepositoryDocumentKind kind,
});

/// Render-ready community document retained by ResourceRuntime.
final class RepositoryDocumentArtifact {
  const RepositoryDocumentArtifact({
    required this.document,
    required this.renderArtifact,
  });

  final RepositoryDocument document;
  final MarkdownRenderArtifact renderArtifact;
}

final class RepositoryDocumentResourceSpecs {
  const RepositoryDocumentResourceSpecs({
    required this.source,
    required this.artifact,
  });

  final ResourceSpec<RepositoryDocument?> source;
  final ResourceSpec<RepositoryDocumentArtifact?> artifact;
}

typedef RepositoryDocumentResourceSpecFactory =
    RepositoryDocumentResourceSpecs Function({
      required RepositoryDocumentResourceKey key,
      required ResourceScope scope,
    });

const ResourcePolicy repositoryDocumentSourcePolicy = ResourcePolicy(
  freshFor: Duration(minutes: 2),
  retainFor: Duration(minutes: 10),
  allowPrefetch: false,
);

const ResourcePolicy repositoryDocumentArtifactPolicy = ResourcePolicy(
  freshFor: Duration(minutes: 2),
  retainFor: Duration(minutes: 10),
  estimatedWeight: 2,
  allowPrefetch: false,
);

ResourceId<RepositoryDocument?> repositoryDocumentSourceResourceId({
  required final RepositoryDocumentResourceKey key,
  required final ResourceScope scope,
}) {
  _checkSupportedKind(key.kind);
  return ResourceId<RepositoryDocument?>(
    kind: 'repository-document-source',
    version: 1,
    scope: scope,
    key: _repositoryDocumentIdentity(key),
  );
}

ResourceId<RepositoryDocumentArtifact?> repositoryDocumentArtifactResourceId({
  required final RepositoryDocumentResourceKey key,
  required final ResourceScope scope,
}) {
  _checkSupportedKind(key.kind);
  return ResourceId<RepositoryDocumentArtifact?>(
    kind: 'repository-document-artifact',
    version: 1,
    scope: scope,
    key: _repositoryDocumentIdentity(key),
  );
}

RepositoryDocumentResourceSpecs repositoryDocumentResourceSpecs({
  required final RepositoryDocumentResourceKey key,
  required final ResourceScope scope,
  required final ApiClient apiClient,
}) {
  _checkSupportedKind(key.kind);
  final String repository = key.repoRef.fullName;
  final Set<ResourceTag> tags = <ResourceTag>{
    ResourceTag('repository', repository),
    ResourceTag('repository-branch', '$repository\u0000${key.branch}'),
    ResourceTag(
      'repository-document',
      '$repository\u0000${key.branch}\u0000${key.kind.name}',
    ),
  };
  final ResourceSpec<RepositoryDocument?> source =
      ResourceSpec<RepositoryDocument?>(
        id: repositoryDocumentSourceResourceId(key: key, scope: scope),
        policy: repositoryDocumentSourcePolicy,
        tags: tags,
        contract: 'repository-document-service-fetch-html-v1',
        workKind: ResourceWorkKind.network,
        load: (final ResourceLoadContext _) async {
          final RepositoryDocument? document = await key.repoRef
              .services(apiClient)
              .fetchRepositoryDocumentHtml(kind: key.kind, branch: key.branch);
          return ResourceLoadResult<RepositoryDocument?>(
            data: document,
            estimatedWeight: document == null
                ? 1
                : _contentWeight(document.content),
          );
        },
      );
  final ResourceSpec<RepositoryDocumentArtifact?> artifact =
      ResourceSpec<RepositoryDocumentArtifact?>(
        id: repositoryDocumentArtifactResourceId(key: key, scope: scope),
        policy: repositoryDocumentArtifactPolicy,
        tags: tags,
        contract: 'repository-document-markdown-artifact-v1',
        workKind: ResourceWorkKind.compute,
        dependencies: <ResourceId<dynamic>>{source.id},
        load: (final ResourceLoadContext context) async {
          final RepositoryDocument? document = (await context.require(
            source,
          )).data;
          if (document == null) {
            return const ResourceLoadResult<RepositoryDocumentArtifact?>(
              data: null,
              origin: ResourceOrigin.derived,
            );
          }
          final MarkdownRenderArtifact renderArtifact = await context
              .runInWorker<String, MarkdownRenderArtifact>(
                document.content,
                parseMarkdownRenderArtifact,
              );
          return ResourceLoadResult<RepositoryDocumentArtifact?>(
            data: RepositoryDocumentArtifact(
              document: document,
              renderArtifact: renderArtifact,
            ),
            origin: ResourceOrigin.derived,
            estimatedWeight: renderArtifact.estimatedWeight,
          );
        },
      );
  return RepositoryDocumentResourceSpecs(source: source, artifact: artifact);
}

final Provider<RepositoryDocumentResourceSpecFactory>
repositoryDocumentResourceSpecFactoryProvider =
    Provider<RepositoryDocumentResourceSpecFactory>((final Ref ref) {
      final ApiClient apiClient = ref.watch(apiClientProvider);
      return ({
        required final RepositoryDocumentResourceKey key,
        required final ResourceScope scope,
      }) => repositoryDocumentResourceSpecs(
        key: key,
        scope: scope,
        apiClient: apiClient,
      );
    });

void invalidateRepositoryDocumentResource({
  required final ResourceRuntime runtime,
  required final ResourceScope scope,
  required final RepositoryDocumentResourceKey key,
}) {
  runtime.invalidate(
    ResourceSelector.forId(
      repositoryDocumentSourceResourceId(key: key, scope: scope),
    ),
  );
}

void invalidateRepositoryDocumentResources({
  required final ResourceRuntime runtime,
  required final ResourceScope scope,
  required final RepoRef repo,
  required final String branch,
}) {
  for (final RepositoryDocumentKind kind in const <RepositoryDocumentKind>[
    RepositoryDocumentKind.contributing,
    RepositoryDocumentKind.security,
  ]) {
    invalidateRepositoryDocumentResource(
      runtime: runtime,
      scope: scope,
      key: (repoRef: repo, branch: branch, kind: kind),
    );
  }
}

void invalidateRepositoryDocumentsForFiles({
  required final ResourceRuntime runtime,
  required final ResourceScope scope,
  required final RepoRef repo,
  required final String branch,
  required final Iterable<String> filePaths,
}) {
  final Set<String> changedPaths = filePaths
      .map(_normalizeRepositoryPath)
      .toSet();
  for (final RepositoryDocumentKind kind in const <RepositoryDocumentKind>[
    RepositoryDocumentKind.contributing,
    RepositoryDocumentKind.security,
  ]) {
    if (!RepositoryDocumentService.candidatePathsFor(
      kind,
    ).any(changedPaths.contains)) {
      continue;
    }
    invalidateRepositoryDocumentResource(
      runtime: runtime,
      scope: scope,
      key: (repoRef: repo, branch: branch, kind: kind),
    );
  }
}

String _repositoryDocumentIdentity(final RepositoryDocumentResourceKey key) =>
    <String>[
      Uri.encodeComponent(key.repoRef.owner),
      Uri.encodeComponent(key.repoRef.name),
      Uri.encodeComponent(key.branch),
      key.kind.name,
    ].join('/');

String _normalizeRepositoryPath(final String path) {
  String normalized = path.replaceAll('\\', '/');
  while (normalized.startsWith('/')) {
    normalized = normalized.substring(1);
  }
  while (normalized.startsWith('./')) {
    normalized = normalized.substring(2);
  }
  return normalized;
}

void _checkSupportedKind(final RepositoryDocumentKind kind) {
  if (kind != RepositoryDocumentKind.contributing &&
      kind != RepositoryDocumentKind.security) {
    throw ArgumentError.value(
      kind,
      'kind',
      'Only CONTRIBUTING and SECURITY use this resource contract.',
    );
  }
}

int _contentWeight(final String content) =>
    resourceWeightForBytes(content.length).clamp(1, 256);
