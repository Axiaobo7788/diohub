import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:test/test.dart';

import 'resource_runtime_test_support.dart';

void main() {
  group('ResourceRuntime lifecycle, scope, and memory', () {
    test('rejected prefetches do not create empty cache entries', () async {
      final ManualResourceClock clock = ManualResourceClock();
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime(
        clock: clock,
      );
      addTearDown(runtime.dispose);
      final ControlledResourceLoader<int> loader =
          ControlledResourceLoader<int>();

      runtime.updateEnvironment(
        const ResourceEnvironment(appState: ResourceAppState.hidden),
      );
      for (int index = 0; index < 3; index++) {
        await runtime
            .prefetch(
              testResourceSpec<int>(key: 'hidden-$index', load: loader.call),
            )
            .done;
      }
      runtime.updateEnvironment(const ResourceEnvironment());
      await runtime
          .prefetch(
            testResourceSpec<int>(
              key: 'prefetch-disabled',
              load: loader.call,
              allowPrefetch: false,
            ),
          )
          .done;

      expect(loader.callCount, 0);
      expect(runtime.telemetry.stats.entryCount, 0);
      expect(runtime.telemetry.stats.estimatedWeight, 0);
      expect(runtime.telemetry.count(ResourceMetricKind.prefetchCanceled), 4);
    });

    test('ticket cancellation is not also counted as wasted', () async {
      final ResourceExecutorPool executors = _singleNonInteractiveExecutors();
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime(
        executors: executors,
      );
      addTearDown(executors.dispose);
      addTearDown(runtime.dispose);
      final ControlledResourceLoader<int> blockerLoader =
          ControlledResourceLoader<int>();
      final ControlledResourceLoader<int> queuedLoader =
          ControlledResourceLoader<int>();
      final PrefetchTicket blocker = runtime.prefetch(
        testResourceSpec<int>(key: 'cancel-blocker', load: blockerLoader.call),
      );
      await blockerLoader.waitForCalls(1);
      final PrefetchTicket queued = runtime.prefetch(
        testResourceSpec<int>(key: 'cancel-queued', load: queuedLoader.call),
      );

      expect(queued.cancel(), isTrue);
      await queued.done;
      expect(queuedLoader.callCount, 0);
      expect(runtime.telemetry.count(ResourceMetricKind.prefetchCanceled), 1);
      expect(runtime.telemetry.count(ResourceMetricKind.prefetchWasted), 0);

      blockerLoader.succeed(0, 1);
      await blocker.done;
    });

    test('entering background cancels only queued prefetches', () async {
      final ResourceExecutorPool executors = _singleNonInteractiveExecutors();
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime(
        executors: executors,
      );
      addTearDown(executors.dispose);
      addTearDown(runtime.dispose);
      final ControlledResourceLoader<int> activeLoader =
          ControlledResourceLoader<int>();
      final ControlledResourceLoader<int> queuedLoader =
          ControlledResourceLoader<int>();
      final PrefetchTicket active = runtime.prefetch(
        testResourceSpec<int>(
          key: 'background-active',
          load: activeLoader.call,
        ),
      );
      await activeLoader.waitForCalls(1);
      final PrefetchTicket queued = runtime.prefetch(
        testResourceSpec<int>(
          key: 'background-queued',
          load: queuedLoader.call,
        ),
      );

      runtime.updateEnvironment(
        const ResourceEnvironment(appState: ResourceAppState.hidden),
      );
      await queued.done;
      expect(queuedLoader.callCount, 0);
      expect(activeLoader.callCount, 1);
      expect(runtime.telemetry.count(ResourceMetricKind.prefetchCanceled), 1);
      expect(runtime.telemetry.count(ResourceMetricKind.prefetchWasted), 0);

      activeLoader.succeed(0, 1);
      await active.done;
    });

    test('prefetch admission immediately enforces the entry budget', () async {
      final ResourceExecutorPool executors = _singleNonInteractiveExecutors();
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime(
        executors: executors,
        cacheConfig: const ResourceCacheConfig(
          maxEntries: 2,
          maxEstimatedWeight: 2,
          trimTargetEntries: 1,
          trimTargetWeight: 1,
        ),
      );
      addTearDown(executors.dispose);
      addTearDown(runtime.dispose);
      final ControlledResourceLoader<int> activeLoader =
          ControlledResourceLoader<int>();
      final ControlledResourceLoader<int> secondLoader =
          ControlledResourceLoader<int>();
      final ControlledResourceLoader<int> thirdLoader =
          ControlledResourceLoader<int>();
      final PrefetchTicket active = runtime.prefetch(
        testResourceSpec<int>(key: 'budget-active', load: activeLoader.call),
      );
      await activeLoader.waitForCalls(1);
      final PrefetchTicket second = runtime.prefetch(
        testResourceSpec<int>(key: 'budget-second', load: secondLoader.call),
      );
      final PrefetchTicket third = runtime.prefetch(
        testResourceSpec<int>(key: 'budget-third', load: thirdLoader.call),
      );

      expect(runtime.telemetry.stats.entryCount, 2);
      expect(runtime.telemetry.stats.overEntryBudget, isFalse);
      expect(runtime.telemetry.count(ResourceMetricKind.prefetchWasted), 1);

      runtime.updateEnvironment(
        const ResourceEnvironment(appState: ResourceAppState.hidden),
      );
      await Future.wait(<Future<void>>[second.done, third.done]);
      activeLoader.succeed(0, 1);
      await active.done;

      expect(secondLoader.callCount, 0);
      expect(thirdLoader.callCount, 0);
      expect(runtime.telemetry.stats.entryCount, lessThanOrEqualTo(1));
    });

    test('resume refreshes only visible stale resources', () async {
      final ManualResourceClock clock = ManualResourceClock();
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime(
        clock: clock,
      );
      addTearDown(runtime.dispose);
      final ControlledResourceLoader<int> visibleLoader =
          ControlledResourceLoader<int>();
      final ControlledResourceLoader<int> retainedLoader =
          ControlledResourceLoader<int>();
      final ResourceLease<int> visible = runtime.acquire(
        testResourceSpec<int>(key: 'visible', load: visibleLoader.call),
      );
      final ResourceLease<int> retained = runtime.acquire(
        testResourceSpec<int>(key: 'retained', load: retainedLoader.call),
      );
      await Future.wait(<Future<void>>[
        visibleLoader.waitForCalls(1),
        retainedLoader.waitForCalls(1),
      ]);
      final Future<ResourceData<int>> visibleInitial = waitForData(visible);
      final Future<ResourceData<int>> retainedInitial = waitForData(retained);
      visibleLoader.succeed(0, 1);
      retainedLoader.succeed(0, 1);
      await Future.wait(<Future<ResourceData<int>>>[
        visibleInitial,
        retainedInitial,
      ]);
      retained.setPresence(ResourcePresence.retained);
      clock.advance(const Duration(minutes: 6));

      runtime
        ..updateEnvironment(
          const ResourceEnvironment(appState: ResourceAppState.hidden),
        )
        ..updateEnvironment(const ResourceEnvironment());
      await visibleLoader.waitForCalls(2);
      expect(retainedLoader.callCount, 1);
    });

    test('server, public, and account scopes are isolated', () async {
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
      addTearDown(runtime.dispose);
      final List<ResourceScope> scopes = <ResourceScope>[
        const ResourceScope(serverId: 'github.com', principal: 'public'),
        const ResourceScope(serverId: 'github.com', principal: 'account-a'),
        const ResourceScope(serverId: 'github.com', principal: 'account-b'),
        const ResourceScope(
          serverId: 'github.enterprise',
          principal: 'account-a',
        ),
      ];
      final List<ControlledResourceLoader<int>> loaders =
          List<ControlledResourceLoader<int>>.generate(
            scopes.length,
            (_) => ControlledResourceLoader<int>(),
          );
      final List<ResourceLease<int>> leases = <ResourceLease<int>>[];
      for (var index = 0; index < scopes.length; index++) {
        leases.add(
          runtime.acquire(
            testResourceSpec<int>(
              key: 'same-key',
              scope: scopes[index],
              load: loaders[index].call,
            ),
          ),
        );
      }
      await Future.wait(
        loaders.map(
          (final ControlledResourceLoader<int> l) => l.waitForCalls(1),
        ),
      );
      expect(loaders.map((final l) => l.callCount), everyElement(1));
    });

    test(
      'scope eviction prevents an old request from reviving an entry',
      () async {
        const ResourceScope scope = ResourceScope(
          serverId: 'github.com',
          principal: 'old-account',
        );
        final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
        addTearDown(runtime.dispose);
        final ControlledResourceLoader<int> loader =
            ControlledResourceLoader<int>();
        final ResourceSpec<int> spec = testResourceSpec<int>(
          key: 'evicted',
          scope: scope,
          load: loader.call,
        );
        final ResourceLease<int> oldLease = runtime.acquire(spec);
        await loader.waitForCalls(1);
        runtime.evictScope(scope);
        expect(oldLease.value, isA<ResourceFailure<int>>());
        loader.succeed(0, 1);

        final ResourceLease<int> newLease = runtime.acquire(spec);
        await loader.waitForCalls(2);
        final Future<ResourceData<int>> delivered = waitForData(newLease);
        loader.succeed(1, 2);
        expect((await delivered).data, 2);
      },
    );

    test('ordinary LRU keeps a lease and drops speculative work', () async {
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime(
        cacheConfig: const ResourceCacheConfig(
          maxEntries: 1,
          maxEstimatedWeight: 1,
          trimTargetEntries: 1,
          trimTargetWeight: 1,
        ),
      );
      addTearDown(runtime.dispose);
      final ControlledResourceLoader<int> firstLoader =
          ControlledResourceLoader<int>();
      final ControlledResourceLoader<int> secondLoader =
          ControlledResourceLoader<int>();
      final ResourceSpec<int> firstSpec = testResourceSpec<int>(
        key: 'leased',
        load: firstLoader.call,
      );
      final ResourceLease<int> first = runtime.acquire(firstSpec);
      await firstLoader.waitForCalls(1);
      final Future<ResourceData<int>> firstData = waitForData(first);
      firstLoader.succeed(0, 1);
      await firstData;

      final PrefetchTicket second = runtime.prefetch(
        testResourceSpec<int>(key: 'prefetched', load: secondLoader.call),
      );
      await second.done;
      expect(runtime.telemetry.stats.entryCount, 1);
      expect(secondLoader.callCount, 0);
      expect(runtime.telemetry.count(ResourceMetricKind.prefetchWasted), 1);

      final ResourceLease<int> again = runtime.acquire(firstSpec);
      expect((again.value as ResourceData<int>).data, 1);
      expect(firstLoader.callCount, 1);
    });

    test(
      'telemetry exposes a leased resource that keeps cache over budget',
      () async {
        final InMemoryResourceRuntime runtime = InMemoryResourceRuntime(
          cacheConfig: const ResourceCacheConfig(
            maxEntries: 1,
            maxEstimatedWeight: 1,
            trimTargetEntries: 1,
            trimTargetWeight: 1,
          ),
        );
        addTearDown(runtime.dispose);
        final ControlledResourceLoader<int> loader =
            ControlledResourceLoader<int>();
        final ResourceLease<int> lease = runtime.acquire(
          testResourceSpec<int>(key: 'heavy-leased', load: loader.call),
        );
        await loader.waitForCalls(1);
        final Future<ResourceData<int>> data = waitForData(lease);
        loader.succeed(0, 1, estimatedWeight: 2);
        await data;

        expect(runtime.telemetry.stats.overWeightBudget, isTrue);
        expect(runtime.telemetry.stats.estimatedBytes, 8192);

        lease.release();
        expect(runtime.telemetry.stats.overWeightBudget, isFalse);
        expect(runtime.telemetry.stats.entryCount, 0);
      },
    );

    test('a leased derived resource pins its dependency chain', () async {
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime(
        cacheConfig: const ResourceCacheConfig(
          maxEntries: 2,
          maxEstimatedWeight: 2,
          trimTargetEntries: 1,
          trimTargetWeight: 1,
        ),
        worker: const InlineResourceWorker(),
      );
      addTearDown(runtime.dispose);
      int sourceLoads = 0;
      final ResourceSpec<int> source = testResourceSpec<int>(
        key: 'dependency-source',
        load: (final _) async {
          sourceLoads++;
          return const ResourceLoadResult<int>(data: 1, estimatedWeight: 2);
        },
      );
      final ResourceSpec<int> derived = testResourceSpec<int>(
        key: 'leased-derived',
        workKind: ResourceWorkKind.compute,
        dependencies: <ResourceId<dynamic>>{source.id},
        load: (final ResourceLoadContext context) async {
          final ResourceLoadResult<int> input = await context.require(source);
          return ResourceLoadResult<int>(
            data: input.data + 1,
            origin: ResourceOrigin.derived,
          );
        },
      );

      final ResourceLease<int> derivedLease = runtime.acquire(derived);
      expect((await waitForData(derivedLease)).data, 2);
      expect(runtime.telemetry.stats.entryCount, 2);
      expect(runtime.telemetry.stats.overWeightBudget, isTrue);

      final ResourceLease<int> sourceLease = runtime.acquire(source);
      expect((await waitForData(sourceLease)).data, 1);
      expect(sourceLoads, 1);
      sourceLease.release();

      derivedLease.release();
      expect(runtime.telemetry.stats.overWeightBudget, isFalse);
      expect(runtime.telemetry.stats.entryCount, 1);
    });

    test('trimMemory preserves a transitive leased dependency chain', () async {
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime(
        cacheConfig: const ResourceCacheConfig(
          maxEntries: 3,
          maxEstimatedWeight: 3,
          trimTargetEntries: 1,
          trimTargetWeight: 1,
        ),
        worker: const InlineResourceWorker(),
      );
      addTearDown(runtime.dispose);
      int sourceLoads = 0;
      final ResourceSpec<int> source = testResourceSpec<int>(
        key: 'transitive-source',
        load: (final _) async {
          sourceLoads++;
          return const ResourceLoadResult<int>(data: 1, estimatedWeight: 2);
        },
      );
      final ResourceSpec<int> middle = testResourceSpec<int>(
        key: 'transitive-middle',
        workKind: ResourceWorkKind.compute,
        dependencies: <ResourceId<dynamic>>{source.id},
        load: (final ResourceLoadContext context) async {
          final ResourceLoadResult<int> input = await context.require(source);
          return ResourceLoadResult<int>(
            data: input.data + 1,
            origin: ResourceOrigin.derived,
          );
        },
      );
      final ResourceSpec<int> top = testResourceSpec<int>(
        key: 'transitive-top',
        workKind: ResourceWorkKind.decode,
        dependencies: <ResourceId<dynamic>>{middle.id},
        load: (final ResourceLoadContext context) async {
          final ResourceLoadResult<int> input = await context.require(middle);
          return ResourceLoadResult<int>(
            data: input.data + 1,
            origin: ResourceOrigin.derived,
          );
        },
      );

      final ResourceLease<int> topLease = runtime.acquire(top);
      expect((await waitForData(topLease)).data, 3);
      runtime.trimMemory();

      expect(runtime.telemetry.stats.entryCount, 3);
      expect(runtime.telemetry.stats.overWeightBudget, isTrue);
      final ResourceLease<int> sourceLease = runtime.acquire(source);
      expect((await waitForData(sourceLease)).data, 1);
      expect(sourceLoads, 1);
      sourceLease.release();

      topLease.release();
      runtime.trimMemory();
      expect(runtime.telemetry.stats.entryCount, lessThanOrEqualTo(1));
      expect(runtime.telemetry.stats.estimatedWeight, lessThanOrEqualTo(1));
    });

    test('trimMemory prioritizes an unused prefetch result', () async {
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime(
        cacheConfig: const ResourceCacheConfig(
          maxEntries: 4,
          maxEstimatedWeight: 4,
          trimTargetEntries: 1,
          trimTargetWeight: 1,
        ),
      );
      addTearDown(runtime.dispose);
      final ControlledResourceLoader<int> normalLoader =
          ControlledResourceLoader<int>();
      final ControlledResourceLoader<int> prefetchLoader =
          ControlledResourceLoader<int>();
      final ResourceSpec<int> normalSpec = testResourceSpec<int>(
        key: 'normal',
        load: normalLoader.call,
      );
      final ResourceSpec<int> prefetchSpec = testResourceSpec<int>(
        key: 'prefetch',
        load: prefetchLoader.call,
      );
      final ResourceLease<int> normal = runtime.acquire(normalSpec);
      await normalLoader.waitForCalls(1);
      final Future<ResourceData<int>> normalData = waitForData(normal);
      normalLoader.succeed(0, 1);
      await normalData;
      normal.release();
      final PrefetchTicket ticket = runtime.prefetch(prefetchSpec);
      await prefetchLoader.waitForCalls(1);
      prefetchLoader.succeed(0, 2);
      await ticket.done;

      runtime.trimMemory();
      final ResourceLease<int> normalAgain = runtime.acquire(normalSpec);
      expect((normalAgain.value as ResourceData<int>).data, 1);
      expect(normalLoader.callCount, 1);
      runtime.acquire(prefetchSpec);
      await prefetchLoader.waitForCalls(2);
      expect(prefetchLoader.callCount, 2);
    });

    test('release is idempotent', () async {
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
      addTearDown(runtime.dispose);
      final ControlledResourceLoader<int> loader =
          ControlledResourceLoader<int>();
      final ResourceLease<int> lease = runtime.acquire(
        testResourceSpec<int>(key: 'idempotent', load: loader.call),
      );
      await loader.waitForCalls(1);
      final Future<ResourceData<int>> data = waitForData(lease);
      loader.succeed(0, 1);
      await data;

      expect(() {
        lease
          ..release()
          ..release()
          ..setPresence(ResourcePresence.visible);
      }, returnsNormally);
    });

    test('conflicting type or policy for one id fails fast', () {
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
      addTearDown(runtime.dispose);
      final ControlledResourceLoader<int> intLoader =
          ControlledResourceLoader<int>();
      final ResourceSpec<int> intSpec = testResourceSpec<int>(
        key: 'conflict',
        load: intLoader.call,
      );
      runtime.acquire(intSpec);

      expect(
        () => runtime.acquire(
          testResourceSpec<String>(
            key: 'conflict',
            load: ControlledResourceLoader<String>().call,
          ),
        ),
        throwsA(isA<ResourceContractConflict>()),
      );
      expect(
        () => runtime.acquire(
          testResourceSpec<int>(
            key: 'conflict',
            freshFor: const Duration(seconds: 1),
            load: intLoader.call,
          ),
        ),
        throwsA(isA<ResourceContractConflict>()),
      );
    });
  });
}

ResourceExecutorPool _singleNonInteractiveExecutors() => ResourceExecutorPool(
  network: ResourceScheduler(
    config: const ResourceSchedulerConfig(
      maxConcurrent: 2,
      reservedInteractive: 1,
    ),
  ),
);
