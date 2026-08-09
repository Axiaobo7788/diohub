import 'dart:collection';

import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/common/pagination/runtime_forward_page_source.dart';
import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/models/global_list_destination.dart';
import 'package:diohub/models/global_repository_browse_query.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/providers/resource_runtime/resource_runtime_provider.dart';
import 'package:diohub/providers/search/global_search_page_resource.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/services/search/search_service.dart';
import 'package:diohub/services/users/user_info_service.dart';
import 'package:diohub_graphql/queries/users/user_repositories_list.graphql.dart';
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub_models/models/search/issue_or_pull.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

typedef GlobalSearchPoolKey = ({
  ResourceScope scope,
  GlobalListDestination destination,
});

typedef GlobalSearchControllerKey = ({
  ResourceScope scope,
  GlobalListDestination destination,
  String query,
});

typedef GlobalRepositoryControllerKey = ({
  ResourceScope scope,
  GlobalRepositoryBrowseQuery query,
});

abstract interface class GlobalSearchSessionPool<T> {
  PaginationController<T, T> controllerFor(final String query);
  void dispose();
}

/// Bounded query-session executor shared by global search-backed work lists.
///
/// It retains controllers, while Runtime retains immutable pages. Those are
/// separate lifecycles: returning to a recent query restores pagination and
/// scroll data without creating a second cache or hiding cursors in Widgets.
final class BoundedGlobalSearchSessionPool<T>
    implements GlobalSearchSessionPool<T> {
  BoundedGlobalSearchSessionPool({
    required this.runtime,
    required this.scope,
    required this.kind,
    required this.specFactory,
    required this.idOf,
    this.capacity = 4,
  });

  final ResourceRuntime runtime;
  final ResourceScope scope;
  final String kind;
  final RuntimePageResourceSpecFactory<T, GlobalSearchPageKey> Function(
    String query,
  )
  specFactory;
  final String Function(T item) idOf;
  final int capacity;

  final LinkedHashMap<String, PaginationController<T, T>> _controllers =
      LinkedHashMap<String, PaginationController<T, T>>();
  bool _disposed = false;

  @override
  PaginationController<T, T> controllerFor(final String query) {
    if (_disposed) {
      throw StateError('GlobalSearchSessionPool is disposed');
    }
    final PaginationController<T, T>? retained = _controllers.remove(query);
    if (retained != null) {
      _controllers[query] = retained;
      return retained;
    }
    final RuntimeForwardPageSource<T, GlobalSearchPageKey> source =
        RuntimeForwardPageSource<T, GlobalSearchPageKey>(
          runtime: runtime,
          firstPageKey: const GlobalSearchPageKey.first(),
          specFactory: specFactory(query),
          refreshSelector: globalSearchQuerySelector(
            scope: scope,
            kind: kind,
            query: query,
          ),
        );
    final PaginationController<T, T> controller = PaginationController<T, T>(
      source: source,
      idOf: idOf,
    );
    _controllers[query] = controller;
    while (_controllers.length > capacity) {
      _controllers.remove(_controllers.keys.first)?.dispose();
    }
    return controller;
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    for (final PaginationController<T, T> controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }
}

final Provider<GlobalIssuePullPageSpecFactory>
globalIssuePullPageSpecFactoryProvider =
    Provider<GlobalIssuePullPageSpecFactory>((final Ref ref) {
      final SearchService service = ref.watch(globalServicesProvider).search;
      return ({
        required final ResourceScope scope,
        required final String query,
        required final GlobalSearchPageKey pageKey,
        required final int pageSize,
      }) => globalIssuePullPageSpec(
        service: service,
        scope: scope,
        query: query,
        pageKey: pageKey,
        pageSize: pageSize,
      );
    });

final Provider<GlobalRepositoryPageSpecFactory>
globalRepositoryPageSpecFactoryProvider =
    Provider<GlobalRepositoryPageSpecFactory>((final Ref ref) {
      final UserInfoService service = ref.watch(userInfoServiceProvider);
      return ({
        required final ResourceScope scope,
        required final GlobalRepositoryBrowseQuery query,
        required final GlobalSearchPageKey pageKey,
        required final int pageSize,
      }) => globalRepositoryPageSpec(
        service: service,
        scope: scope,
        query: query,
        pageKey: pageKey,
        pageSize: pageSize,
      );
    });

final ProviderFamily<GlobalSearchSessionPool<IssueOrPull>, GlobalSearchPoolKey>
globalIssuePullSessionPoolProvider = Provider.autoDispose
    .family<GlobalSearchSessionPool<IssueOrPull>, GlobalSearchPoolKey>((
      final Ref ref,
      final GlobalSearchPoolKey key,
    ) {
      final GlobalIssuePullPageSpecFactory resourceSpecFactory = ref.watch(
        globalIssuePullPageSpecFactoryProvider,
      );
      final BoundedGlobalSearchSessionPool<IssueOrPull> pool =
          BoundedGlobalSearchSessionPool<IssueOrPull>(
            runtime: ref.watch(resourceRuntimeProvider),
            scope: key.scope,
            kind: 'issue-pull',
            specFactory: (final String query) =>
                ({
                  required final GlobalSearchPageKey pageKey,
                  required final int pageSize,
                }) => resourceSpecFactory(
                  scope: key.scope,
                  query: query,
                  pageKey: pageKey,
                  pageSize: pageSize,
                ),
            idOf: (final IssueOrPull item) => switch (item) {
              final IssueResult issue => issue.data.id,
              final PullResult pull => pull.data.id,
            },
          );
      ref.onDispose(pool.dispose);
      return pool;
    });

abstract interface class GlobalRepositorySessionPool {
  PaginationController<UserRepoEdge, UserRepoEdge> controllerFor(
    final GlobalRepositoryBrowseQuery query,
  );
  void dispose();
}

final class BoundedGlobalRepositorySessionPool
    implements GlobalRepositorySessionPool {
  BoundedGlobalRepositorySessionPool({
    required this.runtime,
    required this.scope,
    required this.specFactory,
    this.capacity = 6,
  });

  final ResourceRuntime runtime;
  final ResourceScope scope;
  final GlobalRepositoryPageSpecFactory specFactory;
  final int capacity;
  final LinkedHashMap<
    GlobalRepositoryBrowseQuery,
    PaginationController<UserRepoEdge, UserRepoEdge>
  >
  _controllers =
      LinkedHashMap<
        GlobalRepositoryBrowseQuery,
        PaginationController<UserRepoEdge, UserRepoEdge>
      >();
  bool _disposed = false;

  @override
  PaginationController<UserRepoEdge, UserRepoEdge> controllerFor(
    final GlobalRepositoryBrowseQuery query,
  ) {
    if (_disposed) {
      throw StateError('GlobalRepositorySessionPool is disposed');
    }
    final PaginationController<UserRepoEdge, UserRepoEdge>? retained =
        _controllers.remove(query);
    if (retained != null) {
      _controllers[query] = retained;
      return retained;
    }
    final RuntimeForwardPageSource<UserRepoEdge, GlobalSearchPageKey> source =
        RuntimeForwardPageSource<UserRepoEdge, GlobalSearchPageKey>(
          runtime: runtime,
          firstPageKey: const GlobalSearchPageKey.first(),
          specFactory:
              ({
                required final GlobalSearchPageKey pageKey,
                required final int pageSize,
              }) => specFactory(
                scope: scope,
                query: query,
                pageKey: pageKey,
                pageSize: pageSize,
              ),
          refreshSelector: globalRepositoryQuerySelector(
            scope: scope,
            query: query,
          ),
        );
    final PaginationController<UserRepoEdge, UserRepoEdge> controller =
        PaginationController<UserRepoEdge, UserRepoEdge>(
          source: source,
          idOf: (final UserRepoEdge item) => item.node?.id ?? item.cursor,
          filter: (final List<UserRepoEdge> items) => items
              .where((final UserRepoEdge edge) => _matches(edge, query))
              .toList(growable: false),
        );
    _controllers[query] = controller;
    while (_controllers.length > capacity) {
      _controllers.remove(_controllers.keys.first)?.dispose();
    }
    return controller;
  }

  bool _matches(
    final UserRepoEdge edge,
    final GlobalRepositoryBrowseQuery query,
  ) {
    final Query$getUserRepositories$user$repositories$edges$node? node =
        edge.node;
    if (node == null || (query.forksOnly && !node.isFork)) {
      return false;
    }
    final String needle = query.normalizedText;
    if (needle.isEmpty) {
      return true;
    }
    return node.nameWithOwner.toLowerCase().contains(needle) ||
        (node.description?.toLowerCase().contains(needle) ?? false);
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    for (final PaginationController<UserRepoEdge, UserRepoEdge> controller
        in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }
}

final ProviderFamily<GlobalRepositorySessionPool, ResourceScope>
globalRepositorySessionPoolProvider = Provider.autoDispose
    .family<GlobalRepositorySessionPool, ResourceScope>((
      final Ref ref,
      final ResourceScope scope,
    ) {
      final BoundedGlobalRepositorySessionPool pool =
          BoundedGlobalRepositorySessionPool(
            runtime: ref.watch(resourceRuntimeProvider),
            scope: scope,
            specFactory: ref.watch(globalRepositoryPageSpecFactoryProvider),
          );
      ref.onDispose(pool.dispose);
      return pool;
    });

final ProviderFamily<
  PaginationController<IssueOrPull, IssueOrPull>,
  GlobalSearchControllerKey
>
globalIssuePullControllerProvider = Provider.autoDispose
    .family<
      PaginationController<IssueOrPull, IssueOrPull>,
      GlobalSearchControllerKey
    >(
      (final Ref ref, final GlobalSearchControllerKey key) => ref
          .watch(
            globalIssuePullSessionPoolProvider((
              scope: key.scope,
              destination: key.destination,
            )),
          )
          .controllerFor(key.query),
    );

final ProviderFamily<
  PaginationController<UserRepoEdge, UserRepoEdge>,
  GlobalRepositoryControllerKey
>
globalRepositoryControllerProvider = Provider.autoDispose
    .family<
      PaginationController<UserRepoEdge, UserRepoEdge>,
      GlobalRepositoryControllerKey
    >(
      (final Ref ref, final GlobalRepositoryControllerKey key) => ref
          .watch(globalRepositorySessionPoolProvider(key.scope))
          .controllerFor(key.query),
    );
