import 'dart:async';

import 'package:diohub/common/pagination/pagination.dart';
import 'package:diohub/common/pagination/runtime_forward_page_source.dart';
import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

import '../resource_runtime/resource_runtime_test_support.dart';

const ResourceScope _scope = ResourceScope(
  serverId: 'github.com',
  principal: 'account-1',
);
const ResourceTag _queryTag = ResourceTag(
  'repository-query',
  'octocat/hello-world\u0000type:issue is:open',
);

void main() {
  late InMemoryResourceRuntime runtime;

  setUp(() {
    runtime = InMemoryResourceRuntime();
  });

  tearDown(() {
    runtime.dispose();
  });

  test(
    'concurrent sources join one page load and a new source reuses it',
    () async {
      final ControlledResourceLoader<PaginatedResourcePage<String, String>>
      loader =
          ControlledResourceLoader<PaginatedResourcePage<String, String>>();
      final RuntimePageResourceSpecFactory<String, String> specFactory =
          _specFactory(loader);
      final RuntimeForwardPageSource<String, String> first =
          RuntimeForwardPageSource<String, String>(
            runtime: runtime,
            firstPageKey: 'start',
            specFactory: specFactory,
            refreshSelector: _selector,
          );
      final RuntimeForwardPageSource<String, String> second =
          RuntimeForwardPageSource<String, String>(
            runtime: runtime,
            firstPageKey: 'start',
            specFactory: specFactory,
            refreshSelector: _selector,
          );

      final Future<PageSlice<String>> firstResult = first.fetchForward(20);
      final Future<PageSlice<String>> secondResult = second.fetchForward(20);
      await loader.waitForCalls(1);

      expect(loader.callCount, 1);
      loader.succeed(
        0,
        const PaginatedResourcePage<String, String>(
          items: <String>['one'],
          hasNextPage: false,
        ),
      );

      expect((await firstResult).items, <String>['one']);
      expect((await secondResult).items, <String>['one']);

      final RuntimeForwardPageSource<String, String> returned =
          RuntimeForwardPageSource<String, String>(
            runtime: runtime,
            firstPageKey: 'start',
            specFactory: specFactory,
            refreshSelector: _selector,
          );
      expect((await returned.fetchForward(20)).items, <String>['one']);
      expect(
        loader.callCount,
        1,
        reason: 'a fresh page must survive the query controller instance',
      );
    },
  );

  test('the next page has its own identity and is reusable', () async {
    final ControlledResourceLoader<PaginatedResourcePage<String, String>>
    loader = ControlledResourceLoader<PaginatedResourcePage<String, String>>();
    final RuntimePageResourceSpecFactory<String, String> specFactory =
        _specFactory(loader);
    final RuntimeForwardPageSource<String, String> source =
        RuntimeForwardPageSource<String, String>(
          runtime: runtime,
          firstPageKey: 'start',
          specFactory: specFactory,
          refreshSelector: _selector,
        );

    final Future<PageSlice<String>> first = source.fetchForward(20);
    await loader.waitForCalls(1);
    loader.succeed(
      0,
      const PaginatedResourcePage<String, String>(
        items: <String>['one'],
        hasNextPage: true,
        nextPageKey: 'next',
      ),
    );
    expect((await first).items, <String>['one']);

    final Future<PageSlice<String>> next = source.fetchForward(20);
    await loader.waitForCalls(2);
    loader.succeed(
      1,
      const PaginatedResourcePage<String, String>(
        items: <String>['two'],
        hasNextPage: false,
      ),
    );
    expect((await next).items, <String>['two']);

    final RuntimeForwardPageSource<String, String> returned =
        RuntimeForwardPageSource<String, String>(
          runtime: runtime,
          firstPageKey: 'start',
          specFactory: specFactory,
          refreshSelector: _selector,
        );
    expect((await returned.fetchForward(20)).items, <String>['one']);
    expect((await returned.fetchForward(20)).items, <String>['two']);
    expect(loader.callCount, 2);
  });

  test(
    'reset invalidates cached pages and waits for one replacement load',
    () async {
      final ControlledResourceLoader<PaginatedResourcePage<String, String>>
      loader =
          ControlledResourceLoader<PaginatedResourcePage<String, String>>();
      final RuntimeForwardPageSource<String, String> source =
          RuntimeForwardPageSource<String, String>(
            runtime: runtime,
            firstPageKey: 'start',
            specFactory: _specFactory(loader),
            refreshSelector: _selector,
          );

      final Future<PageSlice<String>> initial = source.fetchForward(20);
      await loader.waitForCalls(1);
      loader.succeed(
        0,
        const PaginatedResourcePage<String, String>(
          items: <String>['old'],
          hasNextPage: false,
        ),
      );
      expect((await initial).items, <String>['old']);

      source.reset();
      final Future<PageSlice<String>> refreshed = source.fetchForward(20);
      await loader.waitForCalls(2);
      expect(loader.callCount, 2);
      loader.succeed(
        1,
        const PaginatedResourcePage<String, String>(
          items: <String>['new'],
          hasNextPage: false,
        ),
      );

      expect((await refreshed).items, <String>['new']);
      expect(loader.callCount, 2);
    },
  );

  test(
    'stale first page is immediate and background refresh replaces it',
    () async {
      runtime.dispose();
      final ManualResourceClock clock = ManualResourceClock();
      runtime = InMemoryResourceRuntime(clock: clock);
      final ControlledResourceLoader<PaginatedResourcePage<String, String>>
      loader =
          ControlledResourceLoader<PaginatedResourcePage<String, String>>();

      final RuntimeForwardPageSource<String, String> initialSource =
          RuntimeForwardPageSource<String, String>(
            runtime: runtime,
            firstPageKey: 'start',
            specFactory: _specFactory(loader),
            refreshSelector: _selector,
          );
      final Future<PageSlice<String>> initial = initialSource.fetchForward(20);
      await loader.waitForCalls(1);
      loader.succeed(
        0,
        const PaginatedResourcePage<String, String>(
          items: <String>['old'],
          hasNextPage: false,
        ),
      );
      expect((await initial).items, <String>['old']);
      initialSource.dispose();

      clock.advance(const Duration(minutes: 3));
      final PaginationController<String, String> controller =
          PaginationController<String, String>(
            source: RuntimeForwardPageSource<String, String>(
              runtime: runtime,
              firstPageKey: 'start',
              specFactory: _specFactory(loader),
              refreshSelector: _selector,
            ),
            idOf: (final String item) => item,
            pageSize: 20,
            autoFetch: false,
          );
      addTearDown(controller.dispose);

      final Future<void> returned = controller.fetchForward();
      await loader.waitForCalls(2);
      await returned;

      expect(
        controller.state.value.items,
        <String>['old'],
        reason: 'stale content must render without awaiting the network',
      );

      final Completer<void> replaced = Completer<void>();
      void onStateChanged() {
        final List<String> items = controller.state.value.items;
        if (items.length == 1 && items.single == 'new') {
          if (!replaced.isCompleted) {
            replaced.complete();
          }
        }
      }

      controller.state.addListener(onStateChanged);
      addTearDown(() => controller.state.removeListener(onStateChanged));
      loader.succeed(
        1,
        const PaginatedResourcePage<String, String>(
          items: <String>['new'],
          hasNextPage: false,
        ),
      );
      await replaced.future;

      expect(controller.state.value.items, <String>['new']);
      expect(loader.callCount, 2);
    },
  );

  test('PaginationController preserves old items when refresh fails', () async {
    final ControlledResourceLoader<PaginatedResourcePage<String, String>>
    loader = ControlledResourceLoader<PaginatedResourcePage<String, String>>();
    final PaginationController<String, String> controller =
        PaginationController<String, String>(
          source: RuntimeForwardPageSource<String, String>(
            runtime: runtime,
            firstPageKey: 'start',
            specFactory: _specFactory(loader),
            refreshSelector: _selector,
          ),
          idOf: (final String item) => item,
          pageSize: 20,
          autoFetch: false,
        );
    addTearDown(controller.dispose);

    final Future<void> initial = controller.fetchForward();
    await loader.waitForCalls(1);
    loader.succeed(
      0,
      const PaginatedResourcePage<String, String>(
        items: <String>['old'],
        hasNextPage: false,
      ),
    );
    await initial;

    final Future<void> refresh = controller.refresh();
    await loader.waitForCalls(2);
    loader.fail(1, StateError('offline'));
    await refresh;

    expect(controller.state.value.items, <String>['old']);
    expect(controller.state.value.phase, isA<Failed>());
  });
}

RuntimePageResourceSpecFactory<String, String> _specFactory(
  final ControlledResourceLoader<PaginatedResourcePage<String, String>> loader,
) {
  return ({required final String pageKey, required final int pageSize}) =>
      ResourceSpec<PaginatedResourcePage<String, String>>(
        id: ResourceId<PaginatedResourcePage<String, String>>(
          kind: 'test-pagination-page',
          version: 1,
          scope: _scope,
          key: '$pageKey/$pageSize',
        ),
        policy: const ResourcePolicy(
          freshFor: Duration(minutes: 2),
          retainFor: Duration(minutes: 5),
        ),
        tags: <ResourceTag>{_queryTag},
        contract: 'test-pagination-page-v1',
        load: loader.call,
      );
}

ResourceSelector get _selector =>
    ResourceSelector.forTags(<ResourceTag>{_queryTag}, scope: _scope);
