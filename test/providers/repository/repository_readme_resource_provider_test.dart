import 'dart:async';

import 'package:diohub/common/markdown_view/markdown_render_artifact.dart';
import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/models/repository_document.dart';
import 'package:diohub/providers/repository/repository_readme_resource.dart';
import 'package:diohub/providers/repository/repository_readme_resource_provider.dart';
import 'package:diohub/providers/resource_runtime/resource_runtime_provider.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../common/resource_runtime/resource_runtime_test_support.dart';

const ResourceScope _scope = ResourceScope(
  serverId: 'github.com',
  principal: 'account-1',
);
const RepoRef _repo = RepoRef(owner: 'octocat', name: 'hello-world');
const RepositoryReadmeKey _key = (repoRef: _repo, branch: 'main');

void main() {
  test(
    'provider reuses both README source and parsed artifact after auto-dispose',
    () async {
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
      final ControlledResourceLoader<RepositoryDocument?> sourceLoader =
          ControlledResourceLoader<RepositoryDocument?>();
      var parseCount = 0;
      final RepositoryReadmeResourceSpecFactory factory = _factory(
        sourceLoader,
        onParse: () => parseCount++,
      );

      final ProviderContainer firstContainer = _container(
        runtime: runtime,
        factory: factory,
      );
      final provider = repositoryReadmeArtifactProvider(_key);
      final ProviderSubscription<AsyncValue<RepositoryReadmeArtifact?>>
      firstSubscription = firstContainer.listen(
        provider,
        (final _, final __) {},
      );
      await sourceLoader.waitForCalls(1);
      sourceLoader.succeed(0, _document('<h1>First</h1><p>Body</p>'));
      final RepositoryReadmeArtifact? first = await firstContainer.read(
        provider.future,
      );
      expect(first?.renderArtifact.headings.single.text, 'First');
      expect(parseCount, 1);
      firstSubscription.close();
      firstContainer.dispose();

      final ProviderContainer secondContainer = _container(
        runtime: runtime,
        factory: factory,
      );
      final ProviderSubscription<AsyncValue<RepositoryReadmeArtifact?>>
      secondSubscription = secondContainer.listen(
        provider,
        (final _, final __) {},
      );
      final RepositoryReadmeArtifact? second = await secondContainer.read(
        provider.future,
      );

      expect(identical(second, first), isTrue);
      expect(sourceLoader.callCount, 1);
      expect(parseCount, 1);

      secondSubscription.close();
      secondContainer.dispose();
      runtime.dispose();
    },
  );

  test(
    'explicit refresh reloads source and rebuilds the artifact once',
    () async {
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
      final ControlledResourceLoader<RepositoryDocument?> sourceLoader =
          ControlledResourceLoader<RepositoryDocument?>();
      var parseCount = 0;
      final ProviderContainer container = _container(
        runtime: runtime,
        factory: _factory(sourceLoader, onParse: () => parseCount++),
      );
      addTearDown(() {
        container.dispose();
        runtime.dispose();
      });

      final provider = repositoryReadmeArtifactProvider(_key);
      final ProviderSubscription<AsyncValue<RepositoryReadmeArtifact?>>
      subscription = container.listen(provider, (final _, final __) {});
      addTearDown(subscription.close);
      await sourceLoader.waitForCalls(1);
      sourceLoader.succeed(0, _document('<h1>First</h1>'));
      await container.read(provider.future);

      final Future<void> refresh = container
          .read(provider.notifier)
          .refreshResource();
      await sourceLoader.waitForCalls(2);
      sourceLoader.succeed(1, _document('<h1>Second</h1>'));
      await refresh;
      final RepositoryReadmeArtifact? refreshed = container
          .read(provider)
          .value;

      expect(refreshed?.renderArtifact.headings.single.text, 'Second');
      expect(sourceLoader.callCount, 2);
      expect(parseCount, 2);
    },
  );

  test('only root README file changes invalidate README resources', () async {
    final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
    final ControlledResourceLoader<RepositoryDocument?> sourceLoader =
        ControlledResourceLoader<RepositoryDocument?>();
    final RepositoryReadmeResourceSpecs specs = _factory(
      sourceLoader,
      onParse: () {},
    )(key: _key, scope: _scope);
    final ResourceLease<RepositoryReadmeArtifact?> lease = runtime.acquire(
      specs.artifact,
    );
    addTearDown(runtime.dispose);
    await sourceLoader.waitForCalls(1);
    sourceLoader.succeed(0, _document('<h1>First</h1>'));
    await waitForData(lease);

    invalidateRepositoryReadmeForFiles(
      runtime: runtime,
      scope: _scope,
      repo: _repo,
      branch: 'main',
      filePaths: <String>['docs/README.md', 'lib/file.dart'],
    );
    await Future<void>.delayed(Duration.zero);
    expect(sourceLoader.callCount, 1);

    invalidateRepositoryReadmeForFiles(
      runtime: runtime,
      scope: _scope,
      repo: _repo,
      branch: 'main',
      filePaths: <String>['README.md'],
    );
    await sourceLoader.waitForCalls(2);
    sourceLoader.succeed(1, _document('<h1>Second</h1>'));
    await waitForData(lease);
  });
}

RepositoryDocument _document(final String content) => RepositoryDocument(
  kind: RepositoryDocumentKind.readme,
  branch: 'main',
  content: content,
  format: RepositoryDocumentFormat.html,
);

RepositoryReadmeResourceSpecFactory _factory(
  final ControlledResourceLoader<RepositoryDocument?> sourceLoader, {
  required final void Function() onParse,
}) =>
    ({
      required final RepositoryReadmeKey key,
      required final ResourceScope scope,
    }) {
      final ResourceSpec<RepositoryDocument?> source =
          ResourceSpec<RepositoryDocument?>(
            id: repositoryReadmeSourceResourceId(key: key, scope: scope),
            policy: repositoryReadmeSourcePolicy,
            tags: <ResourceTag>{
              const ResourceTag('repository-document', 'test-readme'),
            },
            load: sourceLoader.call,
            contract: 'test-readme-source-v1',
          );
      final ResourceSpec<RepositoryReadmeArtifact?> artifact =
          ResourceSpec<RepositoryReadmeArtifact?>(
            id: repositoryReadmeArtifactResourceId(key: key, scope: scope),
            policy: repositoryReadmeArtifactPolicy,
            tags: <ResourceTag>{
              const ResourceTag('repository-document', 'test-readme'),
            },
            workKind: ResourceWorkKind.compute,
            dependencies: <ResourceId<dynamic>>{source.id},
            load: (final ResourceLoadContext context) async {
              final RepositoryDocument? document = (await context.require(
                source,
              )).data;
              if (document == null) {
                return const ResourceLoadResult<RepositoryReadmeArtifact?>(
                  data: null,
                  origin: ResourceOrigin.derived,
                );
              }
              onParse();
              final MarkdownRenderArtifact renderArtifact =
                  const MarkdownArtifactParser().parse(document.content);
              return ResourceLoadResult<RepositoryReadmeArtifact?>(
                data: RepositoryReadmeArtifact(
                  document: document,
                  renderArtifact: renderArtifact,
                ),
                origin: ResourceOrigin.derived,
              );
            },
            contract: 'test-readme-artifact-v1',
          );
      return RepositoryReadmeResourceSpecs(source: source, artifact: artifact);
    };

ProviderContainer _container({
  required final ResourceRuntime runtime,
  required final RepositoryReadmeResourceSpecFactory factory,
}) => ProviderContainer(
  overrides: <Override>[
    activeResourceScopeProvider.overrideWithValue(_scope),
    resourceRuntimeProvider.overrideWithValue(runtime),
    repositoryReadmeResourceSpecFactoryProvider.overrideWithValue(factory),
  ],
);
