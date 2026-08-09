import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/common/pagination/pagination_phase.dart';
import 'package:diohub/common/pagination/pagination_state.dart';
import 'package:diohub/common/pagination/runtime_forward_page_source.dart';
import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/models/global_repository_browse_query.dart';
import 'package:diohub/providers/search/global_search_page_resource.dart';
import 'package:diohub/providers/search/global_search_session_provider.dart';
import 'package:diohub_graphql/queries/users/user_repositories_list.graphql.dart';
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:flutter_test/flutter_test.dart';

const ResourceScope _scope = ResourceScope(
  serverId: 'github.com',
  principal: 'account-1',
);

void main() {
  test(
    'retains recent query controllers without repeating first pages',
    () async {
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
      final _SearchPageBackend backend = _SearchPageBackend();
      final BoundedGlobalSearchSessionPool<String> pool =
          BoundedGlobalSearchSessionPool<String>(
            runtime: runtime,
            scope: _scope,
            kind: 'test',
            specFactory: backend.specFactory,
            idOf: (final String item) => item,
            capacity: 2,
          );
      addTearDown(() {
        pool.dispose();
        runtime.dispose();
      });

      final PaginationController<String, String> open = pool.controllerFor(
        'is:open',
      );
      await _waitForIdle(open);
      final PaginationController<String, String> closed = pool.controllerFor(
        'is:closed',
      );
      await _waitForIdle(closed);

      expect(pool.controllerFor('is:open'), same(open));
      expect(backend.calls, <String>['is:open', 'is:closed']);
      expect(open.state.value.items, <String>['is:open-result']);
      expect(closed.state.value.items, <String>['is:closed-result']);
    },
  );

  test(
    'evicts only the least-recent controller and keeps Runtime pages',
    () async {
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
      final _SearchPageBackend backend = _SearchPageBackend();
      final BoundedGlobalSearchSessionPool<String> pool =
          BoundedGlobalSearchSessionPool<String>(
            runtime: runtime,
            scope: _scope,
            kind: 'test',
            specFactory: backend.specFactory,
            idOf: (final String item) => item,
            capacity: 2,
          );
      addTearDown(() {
        pool.dispose();
        runtime.dispose();
      });

      final PaginationController<String, String> first = pool.controllerFor(
        'a',
      );
      await _waitForIdle(first);
      await _waitForIdle(pool.controllerFor('b'));
      await _waitForIdle(pool.controllerFor('c'));

      final PaginationController<String, String> returned = pool.controllerFor(
        'a',
      );
      await _waitForIdle(returned);

      expect(returned, isNot(same(first)));
      expect(
        backend.calls.where((final String query) => query == 'a').length,
        1,
        reason: 'the fresh immutable page survives query-session LRU eviction',
      );
    },
  );

  test('repository text projections reuse affiliated Runtime pages', () async {
    final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
    final _RepositoryPageBackend backend = _RepositoryPageBackend();
    final BoundedGlobalRepositorySessionPool pool =
        BoundedGlobalRepositorySessionPool(
          runtime: runtime,
          scope: _scope,
          specFactory: backend.specFactory,
        );
    addTearDown(() {
      pool.dispose();
      runtime.dispose();
    });

    final PaginationController<UserRepoEdge, UserRepoEdge> flutter = pool
        .controllerFor(
          const GlobalRepositoryBrowseQuery(login: 'octocat', text: 'flutter'),
        );
    await _waitForRepositoryIdle(flutter);
    expect(
      flutter.state.value.items.single.node?.nameWithOwner,
      'octocat/flutter',
    );

    final PaginationController<UserRepoEdge, UserRepoEdge> missing = pool
        .controllerFor(
          const GlobalRepositoryBrowseQuery(login: 'octocat', text: 'missing'),
        );
    await _waitForRepositoryIdle(missing);

    expect(missing.state.value.items, isEmpty);
    expect(
      backend.calls,
      1,
      reason:
          'local search must not fragment the immutable affiliated page cache',
    );
  });
}

Future<void> _waitForIdle(
  final PaginationController<String, String> controller,
) async {
  for (int attempt = 0; attempt < 100; attempt++) {
    final PaginationState<String> state = controller.state.value;
    if (state.items.isNotEmpty && state.phase is Idle) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('Pagination controller did not settle');
}

Future<void> _waitForRepositoryIdle(
  final PaginationController<UserRepoEdge, UserRepoEdge> controller,
) async {
  for (int attempt = 0; attempt < 100; attempt++) {
    if (controller.state.value.phase is Idle &&
        !controller.state.value.hasMoreForward) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('Repository pagination controller did not settle');
}

final class _SearchPageBackend {
  final List<String> calls = <String>[];

  RuntimePageResourceSpecFactory<String, GlobalSearchPageKey> specFactory(
    final String query,
  ) =>
      ({
        required final GlobalSearchPageKey pageKey,
        required final int pageSize,
      }) => ResourceSpec<PaginatedResourcePage<String, GlobalSearchPageKey>>(
        id: ResourceId<PaginatedResourcePage<String, GlobalSearchPageKey>>(
          kind: 'test-global-search-page',
          version: 1,
          scope: _scope,
          key: '$query/${pageKey.identity}/$pageSize',
        ),
        policy: globalSearchPagePolicy,
        tags: <ResourceTag>{globalSearchQueryTag(kind: 'test', query: query)},
        contract: 'test-global-search-page-v1',
        load: (final ResourceLoadContext _) async {
          calls.add(query);
          return ResourceLoadResult<
            PaginatedResourcePage<String, GlobalSearchPageKey>
          >(
            data: PaginatedResourcePage<String, GlobalSearchPageKey>(
              items: <String>['$query-result'],
              hasNextPage: false,
              totalCount: 1,
            ),
          );
        },
      );
}

final class _RepositoryPageBackend {
  int calls = 0;

  ResourceSpec<PaginatedResourcePage<UserRepoEdge, GlobalSearchPageKey>>
  specFactory({
    required final ResourceScope scope,
    required final GlobalRepositoryBrowseQuery query,
    required final GlobalSearchPageKey pageKey,
    required final int pageSize,
  }) => ResourceSpec<PaginatedResourcePage<UserRepoEdge, GlobalSearchPageKey>>(
    id: ResourceId<PaginatedResourcePage<UserRepoEdge, GlobalSearchPageKey>>(
      kind: 'test-affiliated-repository-page',
      version: 1,
      scope: scope,
      key: '${query.remoteIdentity}/${pageKey.identity}/$pageSize',
    ),
    policy: globalSearchPagePolicy,
    tags: <ResourceTag>{globalRepositoryQueryTag(query)},
    contract: 'test-affiliated-repository-page-v1',
    load: (final ResourceLoadContext _) async {
      calls += 1;
      return ResourceLoadResult<
        PaginatedResourcePage<UserRepoEdge, GlobalSearchPageKey>
      >(
        data: PaginatedResourcePage<UserRepoEdge, GlobalSearchPageKey>(
          items: <UserRepoEdge>[
            _repositoryEdge(
              id: 'repo-1',
              name: 'flutter',
              description: 'Flutter framework',
            ),
            _repositoryEdge(
              id: 'repo-2',
              name: 'engine-fork',
              description: 'A fork',
              isFork: true,
            ),
          ],
          hasNextPage: false,
        ),
      );
    },
  );
}

UserRepoEdge _repositoryEdge({
  required final String id,
  required final String name,
  required final String description,
  final bool isFork = false,
}) => UserRepoEdge(
  cursor: 'cursor-$id',
  node: Query$getUserRepositories$user$repositories$edges$node(
    id: id,
    name: name,
    nameWithOwner: 'octocat/$name',
    description: description,
    url: Uri.parse('https://github.com/octocat/$name'),
    isPrivate: false,
    isFork: isFork,
    stargazerCount: 1,
    updatedAt: DateTime.utc(2026),
    createdAt: DateTime.utc(2025),
    owner: Query$getUserRepositories$user$repositories$edges$node$owner(
      login: 'octocat',
      avatarUrl: Uri.parse('https://avatars.githubusercontent.com/u/1'),
      $__typename: 'User',
    ),
  ),
);
