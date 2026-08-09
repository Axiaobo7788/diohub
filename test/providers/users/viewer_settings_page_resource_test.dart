import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/common/pagination/pagination_phase.dart';
import 'package:diohub/common/pagination/pagination_state.dart';
import 'package:diohub/common/pagination/runtime_forward_page_source.dart';
import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/providers/users/viewer_settings_page_resource.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:flutter_test/flutter_test.dart';

const ResourceScope _scope = ResourceScope(
  serverId: 'github.com',
  principal: 'account-1',
);

void main() {
  test(
    'REST settings pages retain explicit identity and fresh Runtime data',
    () async {
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
      final List<int> calls = <int>[];

      PaginationController<String, String> createController() =>
          PaginationController<String, String>(
            source: RuntimeForwardPageSource<String, ViewerSettingsRestPageKey>(
              runtime: runtime,
              firstPageKey: const ViewerSettingsRestPageKey(1),
              specFactory:
                  ({
                    required final ViewerSettingsRestPageKey pageKey,
                    required final int pageSize,
                  }) => viewerSettingsRestPageSpec<String>(
                    scope: _scope,
                    collection: 'test-emails',
                    pageKey: pageKey,
                    pageSize: pageSize,
                    loadPage:
                        ({
                          required final int page,
                          required final int perPage,
                        }) async {
                          calls.add(page);
                          return PaginatedResult<String>(
                            items: <String>['page-$page'],
                            hasNextPage: page == 1,
                          );
                        },
                  ),
              refreshSelector: viewerSettingsCollectionSelector(
                scope: _scope,
                collection: 'test-emails',
              ),
            ),
            idOf: (final String item) => item,
            pageSize: 30,
          );

      final PaginationController<String, String> first = createController();
      await _waitForItems(first, 1);
      await first.fetchForward();
      await _waitForItems(first, 2);
      expect(first.state.value.items, <String>['page-1', 'page-2']);
      expect(calls, <int>[1, 2]);
      first.dispose();

      final PaginationController<String, String> returned = createController();
      addTearDown(() {
        returned.dispose();
        runtime.dispose();
      });
      await _waitForItems(returned, 1);
      expect(returned.state.value.items, <String>['page-1']);
      expect(
        calls,
        <int>[1, 2],
        reason:
            'a returned settings destination must reuse its fresh first page',
      );
    },
  );

  test('refresh invalidates only the selected settings collection', () async {
    final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
    int calls = 0;
    final PaginationController<String, String> controller =
        PaginationController<String, String>(
          source: RuntimeForwardPageSource<String, ViewerSettingsRestPageKey>(
            runtime: runtime,
            firstPageKey: const ViewerSettingsRestPageKey(1),
            specFactory:
                ({
                  required final ViewerSettingsRestPageKey pageKey,
                  required final int pageSize,
                }) => viewerSettingsRestPageSpec<String>(
                  scope: _scope,
                  collection: 'test-keys',
                  pageKey: pageKey,
                  pageSize: pageSize,
                  loadPage:
                      ({
                        required final int page,
                        required final int perPage,
                      }) async {
                        calls++;
                        return PaginatedResult<String>(
                          items: <String>['generation-$calls'],
                          hasNextPage: false,
                        );
                      },
                ),
            refreshSelector: viewerSettingsCollectionSelector(
              scope: _scope,
              collection: 'test-keys',
            ),
          ),
          idOf: (final String item) => item,
        );
    addTearDown(() {
      controller.dispose();
      runtime.dispose();
    });

    await _waitForItems(controller, 1);
    expect(controller.state.value.items.single, 'generation-1');
    await controller.refresh();
    await _waitForIdle(controller);

    expect(calls, 2);
    expect(controller.state.value.items.single, 'generation-2');
  });
}

Future<void> _waitForItems(
  final PaginationController<String, String> controller,
  final int count,
) async {
  for (int attempt = 0; attempt < 100; attempt++) {
    final PaginationState<String> state = controller.state.value;
    if (state.items.length == count && state.phase is Idle) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('Pagination controller did not settle with $count items');
}

Future<void> _waitForIdle(
  final PaginationController<String, String> controller,
) async {
  for (int attempt = 0; attempt < 100; attempt++) {
    if (controller.state.value.phase is Idle) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('Pagination controller did not settle');
}
