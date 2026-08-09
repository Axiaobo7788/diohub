import 'dart:async';

import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/common/pagination/pagination_phase.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'refresh during forward load discards stale page and resets its cursor',
    () async {
      final _CursorHarness harness = _CursorHarness();
      final PaginationController<int, int> controller =
          PaginationController<int, int>(
            source: CursorForwardSource<int>(fetch: harness.fetch),
            idOf: (final int item) => '$item',
            autoFetch: false,
          );
      addTearDown(controller.dispose);

      final Future<void> initialLoad = controller.fetchForward();
      expect(harness.requests.single.after, isNull);
      harness.complete(
        0,
        items: const <int>[1],
        endCursor: 'cursor-1',
        totalCount: 10,
      );
      await initialLoad;
      expect(controller.state.value.items, const <int>[1]);
      expect(controller.state.value.totalCount, 10);

      final Future<void> staleForward = controller.fetchForward();
      expect(harness.requests[1].after, 'cursor-1');

      final Future<void> refresh = controller.refresh();
      expect(controller.state.value.phase, isA<Refreshing>());
      expect(controller.state.value.items, const <int>[1]);
      expect(controller.state.value.totalCount, 10);
      expect(harness.requests, hasLength(2));

      harness.complete(
        1,
        items: const <int>[2],
        endCursor: 'stale-cursor-2',
        totalCount: 10,
      );
      await staleForward;
      await _drainMicrotasks();

      expect(harness.requests, hasLength(3));
      expect(
        harness.requests[2].after,
        isNull,
        reason: 'the replacement request must start from the first page',
      );
      expect(controller.state.value.items, const <int>[1]);
      expect(controller.state.value.totalCount, 10);

      harness.complete(
        2,
        items: const <int>[10],
        endCursor: 'fresh-cursor-1',
        totalCount: 20,
      );
      await refresh;

      expect(controller.state.value.phase, isA<Idle>());
      expect(controller.state.value.items, const <int>[10]);
      expect(controller.state.value.totalCount, 20);

      final Future<void> nextPage = controller.fetchForward();
      expect(
        harness.requests[3].after,
        'fresh-cursor-1',
        reason: 'the stale response must not remain as the source cursor',
      );
      harness.complete(
        3,
        items: const <int>[11],
        endCursor: 'fresh-cursor-2',
        hasNextPage: false,
        totalCount: 20,
      );
      await nextPage;

      expect(controller.state.value.items, const <int>[10, 11]);
      expect(harness.maxActiveRequests, 1);
    },
  );

  test(
    'consecutive refresh calls coalesce and the newest result wins',
    () async {
      final _CursorHarness harness = _CursorHarness();
      final PaginationController<int, int> controller =
          PaginationController<int, int>(
            source: CursorForwardSource<int>(fetch: harness.fetch),
            idOf: (final int item) => '$item',
            autoFetch: false,
          );
      addTearDown(controller.dispose);

      final Future<void> initialLoad = controller.fetchForward();
      harness.complete(
        0,
        items: const <int>[1],
        endCursor: 'cursor-1',
        totalCount: 5,
      );
      await initialLoad;

      final Future<void> firstRefresh = controller.refresh();
      await _drainMicrotasks();
      expect(harness.requests, hasLength(2));
      expect(harness.requests[1].after, isNull);

      final Future<void> secondRefresh = controller.refresh();
      final Future<void> thirdRefresh = controller.refresh();
      expect(identical(firstRefresh, secondRefresh), isTrue);
      expect(identical(secondRefresh, thirdRefresh), isTrue);
      expect(harness.requests, hasLength(2));
      expect(controller.state.value.items, const <int>[1]);
      expect(controller.state.value.totalCount, 5);

      harness.complete(
        1,
        items: const <int>[100],
        endCursor: 'superseded-cursor',
        totalCount: 50,
      );
      await _drainMicrotasks();

      expect(harness.requests, hasLength(3));
      expect(harness.requests[2].after, isNull);
      expect(controller.state.value.items, const <int>[1]);
      expect(controller.state.value.totalCount, 5);

      harness.complete(
        2,
        items: const <int>[200],
        endCursor: 'final-cursor',
        hasNextPage: false,
        totalCount: 1,
      );
      await Future.wait(<Future<void>>[
        firstRefresh,
        secondRefresh,
        thirdRefresh,
      ]);

      expect(controller.state.value.phase, isA<Idle>());
      expect(controller.state.value.items, const <int>[200]);
      expect(controller.state.value.totalCount, 1);
      expect(harness.maxActiveRequests, 1);
    },
  );

  test(
    'failed refresh retains committed content and retries as refresh',
    () async {
      final _CursorHarness harness = _CursorHarness();
      final PaginationController<int, int> controller =
          PaginationController<int, int>(
            source: CursorForwardSource<int>(fetch: harness.fetch),
            idOf: (final int item) => '$item',
            autoFetch: false,
          );
      addTearDown(controller.dispose);

      final Future<void> initialLoad = controller.fetchForward();
      harness.complete(
        0,
        items: const <int>[1],
        endCursor: 'cursor-1',
        hasNextPage: false,
        totalCount: 1,
      );
      await initialLoad;

      final Future<void> refresh = controller.refresh();
      await _drainMicrotasks();
      expect(harness.requests[1].after, isNull);
      expect(controller.state.value.items, const <int>[1]);
      expect(controller.state.value.totalCount, 1);

      harness.fail(1, StateError('refresh failed'));
      await refresh;

      expect(controller.state.value.phase, isA<Failed>());
      expect(controller.state.value.items, const <int>[1]);
      expect(controller.state.value.totalCount, 1);

      final Future<void> retry = controller.retryForward();
      await _drainMicrotasks();
      expect(harness.requests, hasLength(3));
      expect(
        harness.requests[2].after,
        isNull,
        reason: 'retrying a failed refresh must not append to the old cursor',
      );

      harness.complete(
        2,
        items: const <int>[2],
        endCursor: 'fresh-cursor',
        hasNextPage: false,
        totalCount: 1,
      );
      await retry;

      expect(controller.state.value.phase, isA<Idle>());
      expect(controller.state.value.items, const <int>[2]);
      expect(controller.state.value.totalCount, 1);
    },
  );

  test('query-scoped refresh clears stale items before loading', () async {
    final _CursorHarness harness = _CursorHarness();
    final PaginationController<int, int> controller =
        PaginationController<int, int>(
          source: CursorForwardSource<int>(fetch: harness.fetch),
          idOf: (final int item) => '$item',
          autoFetch: false,
        );
    addTearDown(controller.dispose);

    final Future<void> initialLoad = controller.fetchForward();
    harness.complete(
      0,
      items: const <int>[1],
      endCursor: 'old-query-cursor',
      hasNextPage: false,
      totalCount: 1,
    );
    await initialLoad;

    final Future<void> refresh = controller.refresh(retainItems: false);
    expect(controller.state.value.phase, isA<Refreshing>());
    expect(controller.state.value.items, isEmpty);
    expect(controller.state.value.totalCount, isNull);

    await _drainMicrotasks();
    expect(harness.requests[1].after, isNull);
    harness.complete(
      1,
      items: const <int>[2],
      endCursor: 'new-query-cursor',
      hasNextPage: false,
      totalCount: 1,
    );
    await refresh;

    expect(controller.state.value.phase, isA<Idle>());
    expect(controller.state.value.items, const <int>[2]);
    expect(controller.state.value.totalCount, 1);
  });

  test('refilter restores items excluded by a previous projection', () async {
    final _CursorHarness harness = _CursorHarness();
    bool showEven = true;
    final PaginationController<int, int> controller =
        PaginationController<int, int>(
          source: CursorForwardSource<int>(fetch: harness.fetch),
          idOf: (final int item) => '$item',
          filter: (final List<int> items) => items
              .where((final int item) => showEven ? item.isEven : item.isOdd)
              .toList(growable: false),
          autoFetch: false,
        );
    addTearDown(controller.dispose);

    final Future<void> initialLoad = controller.fetchForward();
    harness.complete(
      0,
      items: const <int>[1, 2, 3, 4],
      endCursor: 'complete',
      hasNextPage: false,
      totalCount: 4,
    );
    await initialLoad;
    expect(controller.state.value.items, const <int>[2, 4]);

    showEven = false;
    controller.refilter();

    expect(
      controller.state.value.items,
      const <int>[1, 3],
      reason: 'a local projection must not destroy the retained query session',
    );
    expect(harness.requests, hasLength(1));
  });
}

Future<void> _drainMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _CursorHarness {
  final List<_CursorRequest> requests = <_CursorRequest>[];
  int activeRequests = 0;
  int maxActiveRequests = 0;

  Future<CursorPage<int>> fetch({
    required final int first,
    final String? after,
  }) {
    final Completer<CursorPage<int>> completer = Completer<CursorPage<int>>();
    requests.add(
      _CursorRequest(after: after, requestedCount: first, completer: completer),
    );
    activeRequests += 1;
    if (activeRequests > maxActiveRequests) {
      maxActiveRequests = activeRequests;
    }
    return completer.future.whenComplete(() {
      activeRequests -= 1;
    });
  }

  void complete(
    final int index, {
    required final List<int> items,
    required final String endCursor,
    required final int totalCount,
    final bool hasNextPage = true,
  }) {
    requests[index].completer.complete(
      CursorPage<int>(
        items: items,
        hasNextPage: hasNextPage,
        endCursor: endCursor,
        totalCount: totalCount,
      ),
    );
  }

  void fail(final int index, final Object error) {
    requests[index].completer.completeError(error, StackTrace.current);
  }
}

class _CursorRequest {
  const _CursorRequest({
    required this.after,
    required this.requestedCount,
    required this.completer,
  });

  final String? after;
  final int requestedCount;
  final Completer<CursorPage<int>> completer;
}
