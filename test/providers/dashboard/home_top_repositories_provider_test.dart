import 'package:diohub/models/home_repository_item.dart';
import 'package:diohub/providers/dashboard/home_top_repositories_provider.dart';
import 'package:diohub/services/dashboard/home_top_repositories_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:gql_exec/gql_exec.dart';

void main() {
  test('provider requests a cache refresh for the active login', () async {
    late bool receivedRefreshCache;
    final HomeTopRepositoriesService service =
        HomeTopRepositoriesService.withHandlers(
          query:
              ({
                required final DocumentNode document,
                required final Map<String, dynamic> variables,
                required final bool refreshCache,
              }) async {
                receivedRefreshCache = refreshCache;
                return const Response(
                  response: <String, dynamic>{},
                  data: <String, dynamic>{
                    'viewer': <String, dynamic>{
                      'topRepositories': <String, dynamic>{
                        'nodes': <Map<String, dynamic>>[],
                      },
                    },
                  },
                );
              },
          fallback:
              ({
                required final String login,
                required final bool refreshCache,
              }) async => const <HomeRepositoryItem>[],
        );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        homeTopRepositoriesServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    final List<HomeRepositoryItem> repositories = await container.read(
      homeTopRepositoriesProvider((
        accountKey: 'github.com/MDQ6VXNlcjE=',
        login: 'octocat',
      )).future,
    );

    expect(receivedRefreshCache, isTrue);
    expect(repositories, isEmpty);
  });

  test('same login on different servers has an isolated cache key', () async {
    int queryCalls = 0;
    final HomeTopRepositoriesService service =
        HomeTopRepositoriesService.withHandlers(
          query:
              ({
                required final DocumentNode document,
                required final Map<String, dynamic> variables,
                required final bool refreshCache,
              }) async {
                queryCalls += 1;
                return const Response(
                  response: <String, dynamic>{},
                  data: <String, dynamic>{
                    'viewer': <String, dynamic>{
                      'topRepositories': <String, dynamic>{
                        'nodes': <Map<String, dynamic>>[],
                      },
                    },
                  },
                );
              },
          fallback:
              ({
                required final String login,
                required final bool refreshCache,
              }) async => const <HomeRepositoryItem>[],
        );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        homeTopRepositoriesServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    await container.read(
      homeTopRepositoriesProvider((
        accountKey: 'github.com/user-1',
        login: 'octocat',
      )).future,
    );
    await container.read(
      homeTopRepositoriesProvider((
        accountKey: 'enterprise.example/user-2',
        login: 'octocat',
      )).future,
    );

    expect(queryCalls, 2);
  });
}
