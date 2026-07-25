import 'dart:async';

import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/providers/code_browser/directory_provider.dart';
import 'package:diohub/providers/code_browser/directory_resource.dart';
import 'package:diohub/providers/resource_runtime/resource_runtime_provider.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/code/code_tree_node.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../common/resource_runtime/resource_runtime_test_support.dart';

const ResourceScope _scope = ResourceScope(
  serverId: 'github.com',
  principal: 'account-1',
);
const RepoRef _repo = RepoRef(owner: 'octocat', name: 'hello-world');
const DirectoryKey _rootKey = (repo: _repo, branch: 'main', path: '');
const DirectoryKey _nestedKey = (repo: _repo, branch: 'main', path: 'lib/src');

void main() {
  test(
    'prefetch and visible root provider share one request and presence refresh',
    () async {
      final ManualResourceClock clock = ManualResourceClock();
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime(
        clock: clock,
      );
      final ControlledResourceLoader<List<CodeTreeNode>> loader =
          ControlledResourceLoader<List<CodeTreeNode>>();
      final DirectoryResourceSpecFactory factory = _factory(loader);
      final ProviderContainer container = _container(
        runtime: runtime,
        factory: factory,
      );
      addTearDown(() {
        container.dispose();
        runtime.dispose();
      });

      final PrefetchTicket ticket = runtime.prefetch(
        factory(key: _rootKey, scope: _scope),
      );
      final provider = directoryProvider(_rootKey);
      final ProviderSubscription<AsyncValue<List<CodeTreeNode>>> subscription =
          container.listen(provider, (final _, final __) {});
      addTearDown(subscription.close);

      await loader.waitForCalls(1);
      expect(loader.callCount, 1);

      final List<CodeTreeNode> firstEntries = <CodeTreeNode>[];
      loader.succeed(0, firstEntries);
      await ticket.done;
      final List<CodeTreeNode> delivered = await container.read(
        provider.future,
      );
      expect(identical(delivered, firstEntries), isTrue);
      expect(runtime.telemetry.count(ResourceMetricKind.prefetchClaimed), 1);

      container.read(provider.notifier).setPresence(ResourcePresence.retained);
      container.read(provider.notifier).setPresence(ResourcePresence.visible);
      expect(loader.callCount, 1, reason: 'fresh retained data must be reused');

      clock.advance(const Duration(minutes: 3));
      container.read(provider.notifier).setPresence(ResourcePresence.retained);
      container.read(provider.notifier).setPresence(ResourcePresence.visible);
      await loader.waitForCalls(2);

      final List<CodeTreeNode> refreshedEntries = <CodeTreeNode>[];
      final Completer<void> refreshed = Completer<void>();
      final ProviderSubscription<AsyncValue<List<CodeTreeNode>>>
      refreshSubscription = container.listen(provider, (
        final AsyncValue<List<CodeTreeNode>>? _,
        final AsyncValue<List<CodeTreeNode>> next,
      ) {
        if (next case AsyncData<List<CodeTreeNode>>(
          :final value,
        ) when identical(value, refreshedEntries)) {
          refreshed.complete();
        }
      });
      loader.succeed(1, refreshedEntries);
      await refreshed.future;
      refreshSubscription.close();
      expect(loader.callCount, 2);
    },
  );

  test(
    'auto-disposed nested provider reuses Runtime data without reload',
    () async {
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
      final ControlledResourceLoader<List<CodeTreeNode>> loader =
          ControlledResourceLoader<List<CodeTreeNode>>();
      final DirectoryResourceSpecFactory factory = _factory(loader);
      final List<CodeTreeNode> entries = <CodeTreeNode>[];

      final ProviderContainer firstContainer = _container(
        runtime: runtime,
        factory: factory,
      );
      final provider = directoryProvider(_nestedKey);
      final ProviderSubscription<AsyncValue<List<CodeTreeNode>>>
      firstSubscription = firstContainer.listen(
        provider,
        (final _, final __) {},
      );
      await loader.waitForCalls(1);
      loader.succeed(0, entries);
      final List<CodeTreeNode> first = await firstContainer.read(
        provider.future,
      );
      expect(identical(first, entries), isTrue);
      firstSubscription.close();
      firstContainer.dispose();

      final ProviderContainer secondContainer = _container(
        runtime: runtime,
        factory: factory,
      );
      final ProviderSubscription<AsyncValue<List<CodeTreeNode>>>
      secondSubscription = secondContainer.listen(
        provider,
        (final _, final __) {},
      );
      final List<CodeTreeNode> second = await secondContainer.read(
        provider.future,
      );

      expect(identical(second, entries), isTrue);
      expect(loader.callCount, 1);

      secondSubscription.close();
      secondContainer.dispose();
      runtime.dispose();
    },
  );

  test(
    'file invalidation is exact to scope, repository, branch, and parent',
    () async {
      const ResourceScope otherScope = ResourceScope(
        serverId: 'github.com',
        principal: 'account-2',
      );
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
      final ControlledResourceLoader<List<CodeTreeNode>> mainLoader =
          ControlledResourceLoader<List<CodeTreeNode>>();
      final ControlledResourceLoader<List<CodeTreeNode>> branchLoader =
          ControlledResourceLoader<List<CodeTreeNode>>();
      final ControlledResourceLoader<List<CodeTreeNode>> scopeLoader =
          ControlledResourceLoader<List<CodeTreeNode>>();
      final ControlledResourceLoader<List<CodeTreeNode>> nestedLoader =
          ControlledResourceLoader<List<CodeTreeNode>>();
      final ResourceLease<List<CodeTreeNode>> mainLease = runtime.acquire(
        _factory(mainLoader)(key: _rootKey, scope: _scope),
      );
      final ResourceLease<List<CodeTreeNode>> branchLease = runtime.acquire(
        _factory(branchLoader)(
          key: (repo: _repo, branch: 'develop', path: ''),
          scope: _scope,
        ),
      );
      final ResourceLease<List<CodeTreeNode>> scopeLease = runtime.acquire(
        _factory(scopeLoader)(key: _rootKey, scope: otherScope),
      );
      final ResourceLease<List<CodeTreeNode>> nestedLease = runtime.acquire(
        _factory(nestedLoader)(key: _nestedKey, scope: _scope),
      );
      await Future.wait(<Future<void>>[
        mainLoader.waitForCalls(1),
        branchLoader.waitForCalls(1),
        scopeLoader.waitForCalls(1),
        nestedLoader.waitForCalls(1),
      ]);
      final Future<ResourceData<List<CodeTreeNode>>> mainData = waitForData(
        mainLease,
      );
      final Future<ResourceData<List<CodeTreeNode>>> branchData = waitForData(
        branchLease,
      );
      final Future<ResourceData<List<CodeTreeNode>>> scopeData = waitForData(
        scopeLease,
      );
      final Future<ResourceData<List<CodeTreeNode>>> nestedData = waitForData(
        nestedLease,
      );
      mainLoader.succeed(0, <CodeTreeNode>[]);
      branchLoader.succeed(0, <CodeTreeNode>[]);
      scopeLoader.succeed(0, <CodeTreeNode>[]);
      nestedLoader.succeed(0, <CodeTreeNode>[]);
      await Future.wait(<Future<ResourceData<List<CodeTreeNode>>>>[
        mainData,
        branchData,
        scopeData,
        nestedData,
      ]);

      invalidateRepositoryDirectoriesForFiles(
        runtime: runtime,
        scope: _scope,
        repo: _repo,
        branch: 'main',
        filePaths: <String>['README.md', 'lib/src/file.dart'],
      );
      await Future.wait(<Future<void>>[
        mainLoader.waitForCalls(2),
        nestedLoader.waitForCalls(2),
      ]);

      expect(repositoryFileParentPath('README.md'), '');
      expect(repositoryFileParentPath('lib/src/file.dart'), 'lib/src');
      expect(branchLoader.callCount, 1);
      expect(scopeLoader.callCount, 1);
      runtime.dispose();
    },
  );
}

DirectoryResourceSpecFactory _factory(
  final ControlledResourceLoader<List<CodeTreeNode>> loader,
) =>
    ({required final DirectoryKey key, required final ResourceScope scope}) =>
        ResourceSpec<List<CodeTreeNode>>(
          id: ResourceId<List<CodeTreeNode>>(
            kind: 'repository-code-directory',
            version: 1,
            scope: scope,
            key: '${key.repo.owner}/${key.repo.name}/${key.branch}/${key.path}',
          ),
          policy: repositoryDirectoryResourcePolicy,
          tags: repositoryDirectoryInvalidationTags(
            repo: key.repo,
            branch: key.branch,
            path: key.path,
          ),
          load: loader.call,
          contract: 'test-directory-loader-v1',
        );

ProviderContainer _container({
  required final ResourceRuntime runtime,
  required final DirectoryResourceSpecFactory factory,
}) => ProviderContainer(
  overrides: <Override>[
    activeResourceScopeProvider.overrideWithValue(_scope),
    resourceRuntimeProvider.overrideWithValue(runtime),
    directoryResourceSpecFactoryProvider.overrideWithValue(factory),
  ],
);
