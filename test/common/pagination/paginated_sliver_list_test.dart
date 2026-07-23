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
}
