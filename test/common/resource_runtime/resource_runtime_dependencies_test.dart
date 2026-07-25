import 'dart:isolate';

import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:test/test.dart';

import 'resource_runtime_test_support.dart';

void main() {
  group('ResourceRuntime executors and dependencies', () {
    test('network work does not occupy the compute executor budget', () async {
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
      addTearDown(runtime.dispose);
      final ControlledResourceLoader<int> network =
          ControlledResourceLoader<int>();
      final ControlledResourceLoader<int> compute =
          ControlledResourceLoader<int>();

      runtime.acquire(
        testResourceSpec<int>(key: 'network', load: network.call),
      );
      runtime.acquire(
        testResourceSpec<int>(
          key: 'compute',
          load: compute.call,
          workKind: ResourceWorkKind.compute,
        ),
      );

      await Future.wait(<Future<void>>[
        network.waitForCalls(1),
        compute.waitForCalls(1),
      ]);
      expect(network.callCount, 1);
      expect(compute.callCount, 1);
    });

    test(
      'derived resources resolve one cached source through runtime',
      () async {
        final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
        addTearDown(runtime.dispose);
        final ControlledResourceLoader<String> sourceLoader =
            ControlledResourceLoader<String>();
        final ResourceSpec<String> source = testResourceSpec<String>(
          key: 'source',
          load: sourceLoader.call,
        );
        var transformCalls = 0;
        final ResourceSpec<int> derived = testResourceSpec<int>(
          key: 'derived',
          workKind: ResourceWorkKind.compute,
          dependencies: <ResourceId<dynamic>>{source.id},
          load: (final ResourceLoadContext context) async {
            transformCalls++;
            final ResourceLoadResult<String> value = await context.require(
              source,
            );
            return ResourceLoadResult<int>(
              data: value.data.length,
              origin: ResourceOrigin.derived,
            );
          },
        );

        final ResourceLease<int> first = runtime.acquire(derived);
        final ResourceLease<int> second = runtime.acquire(derived);
        await sourceLoader.waitForCalls(1);
        final Future<ResourceData<int>> firstData = waitForData(first);
        final Future<ResourceData<int>> secondData = waitForData(second);
        sourceLoader.succeed(0, 'runtime');

        expect((await firstData).data, 7);
        expect((await secondData).data, 7);
        expect(sourceLoader.callCount, 1);
        expect(transformCalls, 1);
        expect(runtime.telemetry.count(ResourceMetricKind.dependencyLoaded), 1);
      },
    );

    test(
      'invalidating a source cascades to its visible derived resource',
      () async {
        final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
        addTearDown(runtime.dispose);
        final ControlledResourceLoader<String> sourceLoader =
            ControlledResourceLoader<String>();
        final ResourceSpec<String> source = testResourceSpec<String>(
          key: 'cascade-source',
          load: sourceLoader.call,
        );
        var transformCalls = 0;
        final ResourceSpec<String> derived = testResourceSpec<String>(
          key: 'cascade-derived',
          workKind: ResourceWorkKind.compute,
          dependencies: <ResourceId<dynamic>>{source.id},
          load: (final ResourceLoadContext context) async {
            transformCalls++;
            final ResourceLoadResult<String> value = await context.require(
              source,
            );
            return ResourceLoadResult<String>(
              data: value.data.toUpperCase(),
              origin: ResourceOrigin.derived,
            );
          },
        );
        final ResourceLease<String> lease = runtime.acquire(derived);
        await sourceLoader.waitForCalls(1);
        final Future<ResourceData<String>> initial = waitForData(lease);
        sourceLoader.succeed(0, 'one');
        expect((await initial).data, 'ONE');

        runtime.invalidate(ResourceSelector.forId(source.id));
        await sourceLoader.waitForCalls(2);
        final Future<ResourceData<String>> refreshed = waitForData(lease);
        sourceLoader.succeed(1, 'two');

        expect((await refreshed).data, 'TWO');
        expect(sourceLoader.callCount, 2);
        expect(transformCalls, 2);
      },
    );

    test(
      'a naturally stale dependency makes a longer-lived artifact stale',
      () async {
        final ManualResourceClock clock = ManualResourceClock();
        final InMemoryResourceRuntime runtime = InMemoryResourceRuntime(
          clock: clock,
          worker: const InlineResourceWorker(),
        );
        addTearDown(runtime.dispose);
        final ControlledResourceLoader<String> sourceLoader =
            ControlledResourceLoader<String>();
        final ResourceSpec<String> source = testResourceSpec<String>(
          key: 'short-source',
          freshFor: const Duration(minutes: 1),
          load: sourceLoader.call,
        );
        var transformCalls = 0;
        final ResourceSpec<String> derived = testResourceSpec<String>(
          key: 'long-artifact',
          freshFor: const Duration(minutes: 5),
          workKind: ResourceWorkKind.compute,
          dependencies: <ResourceId<dynamic>>{source.id},
          load: (final ResourceLoadContext context) async {
            transformCalls++;
            final ResourceLoadResult<String> value = await context.require(
              source,
            );
            return ResourceLoadResult<String>(
              data: value.data.toUpperCase(),
              origin: ResourceOrigin.derived,
            );
          },
        );
        final ResourceLease<String> lease = runtime.acquire(derived);
        await sourceLoader.waitForCalls(1);
        final Future<ResourceData<String>> initial = waitForData(lease);
        sourceLoader.succeed(0, 'first');
        expect((await initial).data, 'FIRST');

        clock.advance(const Duration(minutes: 2));
        final ResourceLease<String> secondLease = runtime.acquire(derived);
        addTearDown(secondLease.release);
        await sourceLoader.waitForCalls(2);
        final Future<ResourceData<String>> refreshed = waitForData(lease);
        sourceLoader.succeed(1, 'second');

        expect((await refreshed).data, 'SECOND');
        expect(sourceLoader.callCount, 2);
        expect(transformCalls, 2);
      },
    );

    test('runInWorker executes on the configured worker isolate', () async {
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
      addTearDown(runtime.dispose);
      final ResourceSpec<String> spec = testResourceSpec<String>(
        key: 'worker-isolate',
        workKind: ResourceWorkKind.compute,
        load: (final ResourceLoadContext context) async =>
            ResourceLoadResult<String>(
              data: await context.runInWorker<String, String>(
                'parsed',
                _workerIdentity,
              ),
              origin: ResourceOrigin.derived,
            ),
      );

      final ResourceData<String> data = await waitForData(
        runtime.acquire(spec),
      );

      expect(data.data, 'diohub-resource-worker:parsed');
      expect(Isolate.current.debugName, isNot('diohub-resource-worker'));
    });

    test('cache weight uses one shared 4 KiB unit', () {
      expect(resourceWeightUnitBytes, 4096);
      expect(resourceWeightForBytes(0), 1);
      expect(resourceWeightForBytes(4096), 1);
      expect(resourceWeightForBytes(4097), 2);
    });

    test(
      'undeclared dependencies fail without starting their loader',
      () async {
        final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
        addTearDown(runtime.dispose);
        final ControlledResourceLoader<int> sourceLoader =
            ControlledResourceLoader<int>();
        final ResourceSpec<int> source = testResourceSpec<int>(
          key: 'undeclared-source',
          load: sourceLoader.call,
        );
        final ResourceSpec<int> derived = testResourceSpec<int>(
          key: 'undeclared-derived',
          workKind: ResourceWorkKind.compute,
          load: (final ResourceLoadContext context) async {
            final ResourceLoadResult<int> value = await context.require(source);
            return value;
          },
        );

        final ResourceFailure<int> failure = await waitForFailure(
          runtime.acquire(derived),
        );
        expect(failure.error, isA<ResourceUndeclaredDependency>());
        expect(sourceLoader.callCount, 0);
      },
    );

    test('same-executor dependencies fail instead of deadlocking', () async {
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
      addTearDown(runtime.dispose);
      final ResourceSpec<int> source = testResourceSpec<int>(
        key: 'same-executor-source',
        load: (final ResourceLoadContext _) async =>
            const ResourceLoadResult<int>(data: 1),
      );
      final ResourceSpec<int> derived = testResourceSpec<int>(
        key: 'same-executor-derived',
        dependencies: <ResourceId<dynamic>>{source.id},
        load: (final ResourceLoadContext context) async =>
            context.require(source),
      );

      final ResourceFailure<int> failure = await waitForFailure(
        runtime.acquire(derived),
      );
      expect(failure.error, isA<ResourceDependencyExecutorConflict>());
    });

    test('dependency cycles fail before either retained resource loads', () {
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
      addTearDown(runtime.dispose);
      const ResourceScope scope = ResourceScope(
        serverId: 'github.com',
        principal: 'account-1',
      );
      const ResourceId<int> firstId = ResourceId<int>(
        kind: 'cycle',
        version: 1,
        scope: scope,
        key: 'first',
      );
      const ResourceId<int> secondId = ResourceId<int>(
        kind: 'cycle',
        version: 1,
        scope: scope,
        key: 'second',
      );
      final ResourceSpec<int> first = ResourceSpec<int>(
        id: firstId,
        policy: const ResourcePolicy(
          freshFor: Duration(minutes: 1),
          retainFor: Duration(minutes: 1),
        ),
        tags: <ResourceTag>{const ResourceTag('cycle', 'test')},
        dependencies: <ResourceId<dynamic>>{secondId},
        contract: 'cycle-first-v1',
        load: (final ResourceLoadContext _) async =>
            const ResourceLoadResult<int>(data: 1),
      );
      final ResourceSpec<int> second = ResourceSpec<int>(
        id: secondId,
        policy: const ResourcePolicy(
          freshFor: Duration(minutes: 1),
          retainFor: Duration(minutes: 1),
        ),
        tags: <ResourceTag>{const ResourceTag('cycle', 'test')},
        dependencies: <ResourceId<dynamic>>{firstId},
        contract: 'cycle-second-v1',
        load: (final ResourceLoadContext _) async =>
            const ResourceLoadResult<int>(data: 2),
      );

      runtime.acquire(first, presence: ResourcePresence.retained);
      expect(
        () => runtime.acquire(second, presence: ResourcePresence.retained),
        throwsA(isA<ResourceDependencyCycle>()),
      );
    });
  });
}

String _workerIdentity(final String value) =>
    '${Isolate.current.debugName}:$value';
