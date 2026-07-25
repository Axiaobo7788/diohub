import 'dart:async';

import 'package:diohub/common/markdown_view/markdown_render_artifact.dart';
import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/models/repository_document.dart';
import 'package:diohub/providers/repository/repository_document_provider.dart';
import 'package:diohub/providers/repository/repository_document_resource.dart';
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
const ResourceScope _otherScope = ResourceScope(
  serverId: 'github.com',
  principal: 'account-2',
);
const RepoRef _repo = RepoRef(owner: 'octocat', name: 'hello-world');
const RepositoryDocumentKey _securityKey = (
  repoRef: _repo,
  branch: 'main',
  kind: RepositoryDocumentKind.security,
);
const RepositoryDocumentRequest _codeSecurityRequest = (
  key: _securityKey,
  consumer: RepositoryDocumentConsumer.code,
);
const RepositoryDocumentRequest _securityPageRequest = (
  key: _securityKey,
  consumer: RepositoryDocumentConsumer.security,
);

void main() {
  test(
    'Code and Security adapters share one source and one parsed artifact',
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

      final codeProvider = repositoryDocumentProvider(_codeSecurityRequest);
      final securityProvider = repositoryDocumentProvider(_securityPageRequest);
      final ProviderSubscription<AsyncValue<RepositoryDocumentArtifact?>>
      codeSubscription = container.listen(codeProvider, (final _, final __) {});
      final ProviderSubscription<AsyncValue<RepositoryDocumentArtifact?>>
      securitySubscription = container.listen(
        securityProvider,
        (final _, final __) {},
      );
      addTearDown(() {
        codeSubscription.close();
        securitySubscription.close();
      });

      await sourceLoader.waitForCalls(1);
      sourceLoader.succeed(0, _document('<h1>Policy</h1>'));
      final List<RepositoryDocumentArtifact?> results =
          await Future.wait(<Future<RepositoryDocumentArtifact?>>[
            container.read(codeProvider.future),
            container.read(securityProvider.future),
          ]);

      expect(sourceLoader.callCount, 1);
      expect(parseCount, 1);
      expect(identical(results.first, results.last), isTrue);
      expect(results.first?.renderArtifact.headings.single.text, 'Policy');
    },
  );

  test(
    'auto-dispose return and missing document reuse retained Runtime data',
    () async {
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
      final ControlledResourceLoader<RepositoryDocument?> sourceLoader =
          ControlledResourceLoader<RepositoryDocument?>();
      var parseCount = 0;
      final RepositoryDocumentResourceSpecFactory factory = _factory(
        sourceLoader,
        onParse: () => parseCount++,
      );

      final ProviderContainer first = _container(
        runtime: runtime,
        factory: factory,
      );
      final provider = repositoryDocumentProvider(_codeSecurityRequest);
      final ProviderSubscription<AsyncValue<RepositoryDocumentArtifact?>>
      firstSubscription = first.listen(provider, (final _, final __) {});
      await sourceLoader.waitForCalls(1);
      sourceLoader.succeed(0, null);
      expect(await first.read(provider.future), isNull);
      firstSubscription.close();
      first.dispose();

      final ProviderContainer second = _container(
        runtime: runtime,
        factory: factory,
      );
      final ProviderSubscription<AsyncValue<RepositoryDocumentArtifact?>>
      secondSubscription = second.listen(provider, (final _, final __) {});
      expect(await second.read(provider.future), isNull);

      expect(sourceLoader.callCount, 1);
      expect(parseCount, 0);
      secondSubscription.close();
      second.dispose();
      runtime.dispose();
    },
  );

  test(
    'explicit refresh reloads and reparses once across both adapters',
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

      final codeProvider = repositoryDocumentProvider(_codeSecurityRequest);
      final securityProvider = repositoryDocumentProvider(_securityPageRequest);
      final ProviderSubscription<AsyncValue<RepositoryDocumentArtifact?>>
      codeSubscription = container.listen(codeProvider, (final _, final __) {});
      final ProviderSubscription<AsyncValue<RepositoryDocumentArtifact?>>
      securitySubscription = container.listen(
        securityProvider,
        (final _, final __) {},
      );
      addTearDown(() {
        codeSubscription.close();
        securitySubscription.close();
      });
      await sourceLoader.waitForCalls(1);
      sourceLoader.succeed(0, _document('<h1>First</h1>'));
      await Future.wait(<Future<RepositoryDocumentArtifact?>>[
        container.read(codeProvider.future),
        container.read(securityProvider.future),
      ]);

      final Future<void> refresh = container
          .read(codeProvider.notifier)
          .refreshResource();
      await sourceLoader.waitForCalls(2);
      sourceLoader.succeed(1, _document('<h1>Second</h1>'));
      await refresh;

      expect(sourceLoader.callCount, 2);
      expect(parseCount, 2);
      expect(
        container
            .read(securityProvider)
            .requireValue
            ?.renderArtifact
            .headings
            .single
            .text,
        'Second',
      );
    },
  );

  test('failed first load can retry through the same Runtime lease', () async {
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

    final provider = repositoryDocumentProvider(_codeSecurityRequest);
    final ProviderSubscription<AsyncValue<RepositoryDocumentArtifact?>>
    subscription = container.listen(provider, (final _, final __) {});
    addTearDown(subscription.close);
    await sourceLoader.waitForCalls(1);
    sourceLoader.fail(0, StateError('offline'));

    await expectLater(
      container.read(provider.future),
      throwsA(isA<StateError>()),
    );
    final Future<void> retry = container
        .read(provider.notifier)
        .refreshResource();
    await sourceLoader.waitForCalls(2);
    sourceLoader.succeed(1, _document('<h1>Recovered</h1>'));
    await retry;

    expect(sourceLoader.callCount, 2);
    expect(parseCount, 1);
    expect(
      container
          .read(provider)
          .requireValue
          ?.renderArtifact
          .headings
          .single
          .text,
      'Recovered',
    );
  });

  test(
    'account change cannot publish an obsolete in-flight document',
    () async {
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
      final ControlledResourceLoader<RepositoryDocument?> sourceLoader =
          ControlledResourceLoader<RepositoryDocument?>();
      final RepositoryDocumentResourceSpecFactory factory = _factory(
        sourceLoader,
        onParse: () {},
      );
      final ProviderContainer container = _container(
        runtime: runtime,
        factory: factory,
      );
      addTearDown(() {
        container.dispose();
        runtime.dispose();
      });

      final provider = repositoryDocumentProvider(_codeSecurityRequest);
      final ProviderSubscription<AsyncValue<RepositoryDocumentArtifact?>>
      subscription = container.listen(provider, (final _, final __) {});
      addTearDown(subscription.close);
      await sourceLoader.waitForCalls(1);

      container.updateOverrides(<Override>[
        activeResourceScopeProvider.overrideWithValue(_otherScope),
        resourceRuntimeProvider.overrideWithValue(runtime),
        repositoryDocumentResourceSpecFactoryProvider.overrideWithValue(
          factory,
        ),
      ]);
      await container.pump();
      await sourceLoader.waitForCalls(2);
      sourceLoader.succeed(1, _document('<h1>Current</h1>'));
      final RepositoryDocumentArtifact? current = await container.read(
        provider.future,
      );

      sourceLoader.succeed(0, _document('<h1>Obsolete</h1>'));
      await container.pump();

      expect(current?.renderArtifact.headings.single.text, 'Current');
      expect(
        container
            .read(provider)
            .requireValue
            ?.renderArtifact
            .headings
            .single
            .text,
        'Current',
      );
    },
  );

  test('branch and document kind are separate resource identities', () {
    const RepositoryDocumentResourceKey contributingMain = (
      repoRef: _repo,
      branch: 'main',
      kind: RepositoryDocumentKind.contributing,
    );
    const RepositoryDocumentResourceKey contributingRelease = (
      repoRef: _repo,
      branch: 'release',
      kind: RepositoryDocumentKind.contributing,
    );
    const RepositoryDocumentResourceKey securityMain = (
      repoRef: _repo,
      branch: 'main',
      kind: RepositoryDocumentKind.security,
    );

    expect(
      repositoryDocumentSourceResourceId(key: contributingMain, scope: _scope),
      isNot(
        repositoryDocumentSourceResourceId(
          key: contributingRelease,
          scope: _scope,
        ),
      ),
    );
    expect(
      repositoryDocumentArtifactResourceId(
        key: contributingMain,
        scope: _scope,
      ),
      isNot(
        repositoryDocumentArtifactResourceId(key: securityMain, scope: _scope),
      ),
    );
  });

  test(
    'file changes invalidate only the matching document and branch',
    () async {
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
      final Map<
        RepositoryDocumentResourceKey,
        ControlledResourceLoader<RepositoryDocument?>
      >
      loaders =
          <
            RepositoryDocumentResourceKey,
            ControlledResourceLoader<RepositoryDocument?>
          >{
            (
              repoRef: _repo,
              branch: 'main',
              kind: RepositoryDocumentKind.contributing,
            ): ControlledResourceLoader<RepositoryDocument?>(),
            (
              repoRef: _repo,
              branch: 'main',
              kind: RepositoryDocumentKind.security,
            ): ControlledResourceLoader<RepositoryDocument?>(),
            (
              repoRef: _repo,
              branch: 'release',
              kind: RepositoryDocumentKind.contributing,
            ): ControlledResourceLoader<RepositoryDocument?>(),
          };
      addTearDown(runtime.dispose);
      final Map<
        RepositoryDocumentResourceKey,
        ResourceLease<RepositoryDocumentArtifact?>
      >
      leases =
          <
            RepositoryDocumentResourceKey,
            ResourceLease<RepositoryDocumentArtifact?>
          >{};
      for (final MapEntry<
            RepositoryDocumentResourceKey,
            ControlledResourceLoader<RepositoryDocument?>
          >
          entry
          in loaders.entries) {
        final RepositoryDocumentResourceSpecs specs = _factoryForKey(
          entry.value,
        )(key: entry.key, scope: _scope);
        leases[entry.key] = runtime.acquire(specs.artifact);
      }
      for (final ControlledResourceLoader<RepositoryDocument?> loader
          in loaders.values) {
        await loader.waitForCalls(1);
        loader.succeed(0, _document('<h1>Initial</h1>'));
      }
      await Future.wait(leases.values.map(waitForData));

      invalidateRepositoryDocumentsForFiles(
        runtime: runtime,
        scope: _scope,
        repo: _repo,
        branch: 'main',
        filePaths: <String>['docs/CONTRIBUTING.md', 'README.md'],
      );
      final ControlledResourceLoader<RepositoryDocument?> contributingMain =
          loaders[(
            repoRef: _repo,
            branch: 'main',
            kind: RepositoryDocumentKind.contributing,
          )]!;
      await contributingMain.waitForCalls(2);

      expect(
        loaders[(
              repoRef: _repo,
              branch: 'main',
              kind: RepositoryDocumentKind.security,
            )]!
            .callCount,
        1,
      );
      expect(
        loaders[(
              repoRef: _repo,
              branch: 'release',
              kind: RepositoryDocumentKind.contributing,
            )]!
            .callCount,
        1,
      );
      contributingMain.succeed(
        1,
        _document(
          '<h1>Updated</h1>',
          kind: RepositoryDocumentKind.contributing,
          path: 'docs/CONTRIBUTING.md',
        ),
      );
      await waitForData(
        leases[(
          repoRef: _repo,
          branch: 'main',
          kind: RepositoryDocumentKind.contributing,
        )]!,
      );
    },
  );
}

RepositoryDocument _document(
  final String content, {
  final RepositoryDocumentKind kind = RepositoryDocumentKind.security,
  final String branch = 'main',
  final String? path = 'SECURITY.md',
}) => RepositoryDocument(
  kind: kind,
  branch: branch,
  content: content,
  format: RepositoryDocumentFormat.html,
  path: path,
);

RepositoryDocumentResourceSpecFactory _factory(
  final ControlledResourceLoader<RepositoryDocument?> sourceLoader, {
  required final void Function() onParse,
}) =>
    ({
      required final RepositoryDocumentResourceKey key,
      required final ResourceScope scope,
    }) => _testSpecs(
      key: key,
      scope: scope,
      sourceLoader: sourceLoader,
      onParse: onParse,
    );

RepositoryDocumentResourceSpecFactory _factoryForKey(
  final ControlledResourceLoader<RepositoryDocument?> sourceLoader,
) => _factory(sourceLoader, onParse: () {});

RepositoryDocumentResourceSpecs _testSpecs({
  required final RepositoryDocumentResourceKey key,
  required final ResourceScope scope,
  required final ControlledResourceLoader<RepositoryDocument?> sourceLoader,
  required final void Function() onParse,
}) {
  final ResourceSpec<RepositoryDocument?> source =
      ResourceSpec<RepositoryDocument?>(
        id: repositoryDocumentSourceResourceId(key: key, scope: scope),
        policy: repositoryDocumentSourcePolicy,
        tags: <ResourceTag>{ResourceTag('repository-document', key.kind.name)},
        load: sourceLoader.call,
        contract: 'test-repository-document-source-v1',
      );
  final ResourceSpec<RepositoryDocumentArtifact?> artifact =
      ResourceSpec<RepositoryDocumentArtifact?>(
        id: repositoryDocumentArtifactResourceId(key: key, scope: scope),
        policy: repositoryDocumentArtifactPolicy,
        tags: <ResourceTag>{ResourceTag('repository-document', key.kind.name)},
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
          onParse();
          final MarkdownRenderArtifact renderArtifact =
              const MarkdownArtifactParser().parse(document.content);
          return ResourceLoadResult<RepositoryDocumentArtifact?>(
            data: RepositoryDocumentArtifact(
              document: document,
              renderArtifact: renderArtifact,
            ),
            origin: ResourceOrigin.derived,
          );
        },
        contract: 'test-repository-document-artifact-v1',
      );
  return RepositoryDocumentResourceSpecs(source: source, artifact: artifact);
}

ProviderContainer _container({
  required final ResourceRuntime runtime,
  required final RepositoryDocumentResourceSpecFactory factory,
}) => ProviderContainer(
  overrides: <Override>[
    activeResourceScopeProvider.overrideWithValue(_scope),
    resourceRuntimeProvider.overrideWithValue(runtime),
    repositoryDocumentResourceSpecFactoryProvider.overrideWithValue(factory),
  ],
);
