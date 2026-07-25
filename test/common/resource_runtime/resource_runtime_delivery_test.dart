import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:test/test.dart';

import 'resource_runtime_test_support.dart';

void main() {
  group('ResourceRuntime delivery and consistency', () {
    late ManualResourceClock clock;
    late InMemoryResourceRuntime runtime;

    setUp(() {
      clock = ManualResourceClock();
      runtime = InMemoryResourceRuntime(clock: clock);
    });

    tearDown(() {
      runtime.dispose();
    });

    test('ten concurrent acquires execute one loader', () async {
      final ControlledResourceLoader<int> loader =
          ControlledResourceLoader<int>();
      final ResourceSpec<int> spec = testResourceSpec<int>(
        key: 'single-flight',
        load: loader.call,
      );

      final List<ResourceLease<int>> leases = List<ResourceLease<int>>.generate(
        10,
        (_) => runtime.acquire(spec),
      );
      await loader.waitForCalls(1);
      expect(loader.callCount, 1);

      final Future<ResourceData<int>> delivered = waitForData(leases.first);
      loader.succeed(0, 7);
      expect((await delivered).data, 7);
      expect(loader.callCount, 1);
      expect(
        runtime.telemetry.count(ResourceMetricKind.singleFlightJoin),
        greaterThanOrEqualTo(9),
      );
    });

    test(
      'leases are independent and one release does not affect another',
      () async {
        final ControlledResourceLoader<int> loader =
            ControlledResourceLoader<int>();
        final ResourceSpec<int> spec = testResourceSpec<int>(
          key: 'leases',
          load: loader.call,
        );
        final ResourceLease<int> first = runtime.acquire(spec);
        final ResourceLease<int> second = runtime.acquire(spec);
        await loader.waitForCalls(1);
        final Future<ResourceData<int>> delivered = waitForData(second);
        loader.succeed(0, 1);
        await delivered;

        first.release();
        clock.advance(const Duration(minutes: 6));
        second.setPresence(ResourcePresence.visible);
        await loader.waitForCalls(2);
        expect(loader.callCount, 2);
      },
    );

    test('fresh cache hit does not load again', () async {
      final ControlledResourceLoader<int> loader =
          ControlledResourceLoader<int>();
      final ResourceSpec<int> spec = testResourceSpec<int>(
        key: 'fresh',
        load: loader.call,
      );
      final ResourceLease<int> first = runtime.acquire(spec);
      await loader.waitForCalls(1);
      final Future<ResourceData<int>> delivered = waitForData(first);
      loader.succeed(0, 11);
      await delivered;

      final ResourceLease<int> second = runtime.acquire(spec);
      expect((second.value as ResourceData<int>).data, 11);
      expect(loader.callCount, 1);
      expect(runtime.telemetry.count(ResourceMetricKind.freshCacheHit), 1);
    });

    test('stale visible data is delivered before one refresh', () async {
      final ControlledResourceLoader<int> loader =
          ControlledResourceLoader<int>();
      final ResourceSpec<int> spec = testResourceSpec<int>(
        key: 'stale-visible',
        load: loader.call,
      );
      final ResourceLease<int> first = runtime.acquire(spec);
      await loader.waitForCalls(1);
      final Future<ResourceData<int>> initial = waitForData(first);
      loader.succeed(0, 1);
      await initial;
      first.release();
      clock.advance(const Duration(minutes: 6));

      final ResourceLease<int> second = runtime.acquire(spec);
      final ResourceData<int> stale = second.value as ResourceData<int>;
      expect(stale.data, 1);
      expect(stale.freshness, ResourceFreshness.stale);
      expect(stale.isRefreshing, isTrue);
      await loader.waitForCalls(2);
      expect(loader.callCount, 2);

      final Future<ResourceData<int>> refreshed = waitForData(second);
      loader.succeed(1, 2);
      expect((await refreshed).data, 2);
    });

    test('stale retained data does not refresh automatically', () async {
      final ControlledResourceLoader<int> loader =
          ControlledResourceLoader<int>();
      final ResourceSpec<int> spec = testResourceSpec<int>(
        key: 'stale-retained',
        load: loader.call,
      );
      final ResourceLease<int> first = runtime.acquire(spec);
      await loader.waitForCalls(1);
      final Future<ResourceData<int>> initial = waitForData(first);
      loader.succeed(0, 1);
      await initial;
      first.release();
      clock.advance(const Duration(minutes: 6));

      final ResourceLease<int> retained = runtime.acquire(
        spec,
        presence: ResourcePresence.retained,
      );
      expect(
        (retained.value as ResourceData<int>).freshness,
        ResourceFreshness.stale,
      );
      expect(loader.callCount, 1);
    });

    test(
      'prefetch is promoted and claimed without a duplicate request',
      () async {
        final ControlledResourceLoader<int> loader =
            ControlledResourceLoader<int>();
        final ResourceSpec<int> spec = testResourceSpec<int>(
          key: 'prefetch-claim',
          load: loader.call,
        );

        final PrefetchTicket ticket = runtime.prefetch(spec);
        final ResourceLease<int> lease = runtime.acquire(spec);
        expect(ticket.isClaimed, isTrue);
        await loader.waitForCalls(1);
        expect(loader.callCount, 1);

        final Future<ResourceData<int>> delivered = waitForData(lease);
        loader.succeed(0, 9);
        expect((await delivered).data, 9);
        await ticket.done;
        expect(runtime.telemetry.count(ResourceMetricKind.prefetchClaimed), 1);
        expect(runtime.telemetry.count(ResourceMetricKind.prefetchPromoted), 1);
      },
    );

    test('old generation cannot overwrite invalidated data', () async {
      final ControlledResourceLoader<int> loader =
          ControlledResourceLoader<int>();
      final ResourceSpec<int> spec = testResourceSpec<int>(
        key: 'generation',
        load: loader.call,
      );
      final ResourceLease<int> lease = runtime.acquire(spec);
      await loader.waitForCalls(1);
      runtime.invalidate(ResourceSelector.forId(spec.id));

      loader.succeed(0, 1);
      await loader.waitForCalls(2);
      final Future<ResourceData<int>> delivered = waitForData(lease);
      loader.succeed(1, 2);
      expect((await delivered).data, 2);
      expect(
        runtime.telemetry.count(ResourceMetricKind.staleCompletionDropped),
        1,
      );
    });

    test(
      'multiple invalidations in flight schedule one revalidation',
      () async {
        final ControlledResourceLoader<int> loader =
            ControlledResourceLoader<int>();
        final ResourceSpec<int> spec = testResourceSpec<int>(
          key: 'pending-revalidate',
          load: loader.call,
        );
        final ResourceLease<int> lease = runtime.acquire(spec);
        await loader.waitForCalls(1);
        runtime
          ..invalidate(ResourceSelector.forId(spec.id))
          ..invalidate(ResourceSelector.forId(spec.id))
          ..invalidate(ResourceSelector.forId(spec.id));

        loader.succeed(0, 1);
        await loader.waitForCalls(2);
        final Future<ResourceData<int>> delivered = waitForData(lease);
        loader.succeed(1, 2);
        await delivered;
        expect(loader.callCount, 2);
      },
    );

    test(
      'retained invalidated initial load restarts when it becomes visible',
      () async {
        final ControlledResourceLoader<int> loader =
            ControlledResourceLoader<int>();
        final ResourceSpec<int> spec = testResourceSpec<int>(
          key: 'retained-invalidated-loading',
          load: loader.call,
        );
        final ResourceLease<int> lease = runtime.acquire(spec);
        await loader.waitForCalls(1);
        final Future<void> inFlight = lease.refresh();
        lease.setPresence(ResourcePresence.retained);
        runtime.invalidate(ResourceSelector.forId(spec.id));
        loader.succeed(0, 1);
        await inFlight;

        expect(lease.value, isA<ResourceLoading<int>>());
        lease.setPresence(ResourcePresence.visible);
        await loader.waitForCalls(2);
        final Future<ResourceData<int>> delivered = waitForData(lease);
        loader.succeed(1, 2);
        expect((await delivered).data, 2);
      },
    );

    test('first load failure is delivered as ResourceFailure', () async {
      final ControlledResourceLoader<int> loader =
          ControlledResourceLoader<int>();
      final ResourceSpec<int> spec = testResourceSpec<int>(
        key: 'initial-failure',
        load: loader.call,
      );
      final ResourceLease<int> lease = runtime.acquire(spec);
      await loader.waitForCalls(1);
      final Future<ResourceFailure<int>> failed = waitForFailure(lease);
      loader.fail(0, StateError('offline'));
      expect((await failed).error, isA<StateError>());
    });

    test('refresh failure retains data and exposes the error', () async {
      final ControlledResourceLoader<int> loader =
          ControlledResourceLoader<int>();
      final ResourceSpec<int> spec = testResourceSpec<int>(
        key: 'refresh-failure',
        load: loader.call,
      );
      final ResourceLease<int> lease = runtime.acquire(spec);
      await loader.waitForCalls(1);
      final Future<ResourceData<int>> initial = waitForData(lease);
      loader.succeed(0, 3);
      await initial;

      final Future<void> refresh = lease.refresh();
      await loader.waitForCalls(2);
      final Future<ResourceData<int>> failedRefresh = waitForRefreshError(
        lease,
      );
      loader.fail(1, StateError('timeout'));
      await refresh;
      final ResourceData<int> data = await failedRefresh;
      expect(data.data, 3);
      expect(data.lastRefreshError, isA<StateError>());
      expect(
        runtime.telemetry.count(ResourceMetricKind.refreshFailureRetainedData),
        1,
      );
    });
  });
}
