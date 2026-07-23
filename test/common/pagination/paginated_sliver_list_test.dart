import 'dart:async';

import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/pagination/paginated_sliver_list.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('each visible forward sentinel fetches the next page once', (
    final WidgetTester tester,
  ) async {
    final List<Completer<PageSlice<int>>> responses =
        <Completer<PageSlice<int>>>[
          Completer<PageSlice<int>>(),
          Completer<PageSlice<int>>(),
        ];
    int fetchCalls = 0;
    final PaginationController<int, int> controller =
        PaginationController<int, int>(
          source: SliceForwardSource<int>(
            fetch: (final int count) {
              final Completer<PageSlice<int>> response = responses[fetchCalls];
              fetchCalls += 1;
              return response.future;
            },
            resetState: () {},
          ),
          idOf: (final int item) => '$item',
          autoFetch: false,
        );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: CustomScrollView(
          slivers: <Widget>[
            PaginatedSliverList<int>(
              controller: controller,
              itemBuilder: (_, final int item, __) => Text('$item'),
              loadingBuilder: (_) => const SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(fetchCalls, 1);

    responses.first.complete(
      const PageSlice<int>(items: <int>[1], hasNextPage: true, totalCount: 37),
    );
    await tester.pump();
    await tester.pump();

    expect(fetchCalls, 2);
    expect(find.text('1'), findsOneWidget);
    expect(controller.state.value.totalCount, 37);

    responses.last.complete(
      const PageSlice<int>(items: <int>[2], hasNextPage: false, totalCount: 37),
    );
    await tester.pump();
    await tester.pump();

    expect(fetchCalls, 2);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(controller.state.value.totalCount, 37);
  });

  testWidgets(
    'refresh keeps committed rows visible through failure and retry',
    (final WidgetTester tester) async {
      final List<Completer<PageSlice<int>>> responses =
          <Completer<PageSlice<int>>>[
            Completer<PageSlice<int>>(),
            Completer<PageSlice<int>>(),
            Completer<PageSlice<int>>(),
          ];
      int fetchCalls = 0;
      final PaginationController<int, int> controller =
          PaginationController<int, int>(
            source: SliceForwardSource<int>(
              fetch: (final int count) => responses[fetchCalls++].future,
              resetState: () {},
            ),
            idOf: (final int item) => '$item',
            autoFetch: false,
          );
      addTearDown(controller.dispose);

      final Future<void> initialLoad = controller.fetchForward();
      responses[0].complete(
        const PageSlice<int>(
          items: <int>[1],
          hasNextPage: false,
          totalCount: 1,
        ),
      );
      await initialLoad;

      await tester.pumpWidget(
        MaterialApp(
          home: CustomScrollView(
            slivers: <Widget>[
              PaginatedSliverList<int>(
                controller: controller,
                itemBuilder: (_, final int item, __) => Text('row $item'),
                loadingBuilder: (_) => const SizedBox(
                  key: ValueKey<String>('refresh-tail-progress'),
                  height: 24,
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      final Future<void> refresh = controller.refresh();
      await tester.pump();
      expect(find.text('row 1'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('refresh-tail-progress')),
        findsOneWidget,
      );

      responses[1].completeError(
        StateError('refresh failed'),
        StackTrace.current,
      );
      await refresh;
      await tester.pump();

      expect(find.text('row 1'), findsOneWidget);
      expect(find.textContaining('refresh failed'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(fetchCalls, 3);
      expect(find.text('row 1'), findsOneWidget);

      responses[2].complete(
        const PageSlice<int>(
          items: <int>[2],
          hasNextPage: false,
          totalCount: 1,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('row 1'), findsNothing);
      expect(find.text('row 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
