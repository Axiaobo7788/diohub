import 'package:diohub/models/home_repository_item.dart';
import 'package:diohub/services/dashboard/home_top_repositories_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:gql_exec/gql_exec.dart';

void main() {
  group('HomeTopRepositoriesService', () {
    test('loads viewer top repositories from the last year', () async {
      late String documentSource;
      late Map<String, dynamic> capturedVariables;
      late bool receivedRefreshCache;
      int fallbackCalls = 0;
      final HomeTopRepositoriesService service =
          HomeTopRepositoriesService.withHandlers(
            query:
                ({
                  required final DocumentNode document,
                  required final Map<String, dynamic> variables,
                  required final bool refreshCache,
                }) async {
                  documentSource = printNode(document);
                  capturedVariables = variables;
                  receivedRefreshCache = refreshCache;
                  return const Response(
                    response: <String, dynamic>{},
                    data: <String, dynamic>{
                      'viewer': <String, dynamic>{
                        'topRepositories': <String, dynamic>{
                          'nodes': <Map<String, dynamic>>[
                            <String, dynamic>{
                              'id': 'R_1',
                              'name': 'concept',
                              'nameWithOwner': 'refetch-project/concept',
                              'isPrivate': false,
                              'defaultBranchRef': <String, dynamic>{
                                'name': 'develop',
                              },
                              'owner': <String, dynamic>{
                                'login': 'refetch-project',
                                'avatarUrl':
                                    'https://avatars.example/refetch.png',
                              },
                            },
                          ],
                        },
                      },
                    },
                  );
                },
            fallback:
                ({
                  required final String login,
                  required final bool refreshCache,
                }) async {
                  fallbackCalls += 1;
                  return const <HomeRepositoryItem>[];
                },
          );

      final List<HomeRepositoryItem> repositories = await service.fetch(
        login: 'octocat',
        refreshCache: true,
        now: DateTime.utc(2026, 7, 22, 12),
      );

      expect(documentSource, contains('viewer'));
      expect(documentSource, contains('topRepositories'));
      expect(documentSource, contains('first: 12'));
      expect(documentSource, contains('field: PUSHED_AT'));
      expect(documentSource, contains('direction: DESC'));
      expect(documentSource, contains('defaultBranchRef'));
      expect(capturedVariables, <String, dynamic>{
        'since': '2025-07-22T12:00:00.000Z',
      });
      expect(receivedRefreshCache, isTrue);
      expect(fallbackCalls, 0);
      expect(repositories, hasLength(1));
      expect(repositories.single.fullName, 'refetch-project/concept');
      expect(repositories.single.owner, 'refetch-project');
      expect(repositories.single.isPrivate, isFalse);
      expect(repositories.single.nodeId, 'R_1');
      expect(repositories.single.defaultBranch, 'develop');
    });

    test(
      'falls back to affiliated repositories when top query fails',
      () async {
        late String receivedLogin;
        late bool receivedRefreshCache;
        final HomeTopRepositoriesService
        service = HomeTopRepositoriesService.withHandlers(
          query:
              ({
                required final DocumentNode document,
                required final Map<String, dynamic> variables,
                required final bool refreshCache,
              }) async => const Response(
                response: <String, dynamic>{},
                errors: <GraphQLError>[
                  GraphQLError(
                    message:
                        'Cannot query field "topRepositories" on type "User".',
                  ),
                ],
              ),
          fallback:
              ({
                required final String login,
                required final bool refreshCache,
              }) async {
                receivedLogin = login;
                receivedRefreshCache = refreshCache;
                return const <HomeRepositoryItem>[
                  HomeRepositoryItem(
                    fullName: 'octocat/hello-world',
                    name: 'hello-world',
                    owner: 'octocat',
                    ownerAvatarUrl: null,
                    isPrivate: false,
                  ),
                ];
              },
        );

        final List<HomeRepositoryItem> repositories = await service.fetch(
          login: 'octocat',
          refreshCache: true,
        );

        expect(receivedLogin, 'octocat');
        expect(receivedRefreshCache, isTrue);
        expect(repositories.single.fullName, 'octocat/hello-world');
      },
    );

    test('does not mask ordinary GitHub errors with a fallback request', () {
      int fallbackCalls = 0;
      final HomeTopRepositoriesService service =
          HomeTopRepositoriesService.withHandlers(
            query:
                ({
                  required final DocumentNode document,
                  required final Map<String, dynamic> variables,
                  required final bool refreshCache,
                }) async => const Response(
                  response: <String, dynamic>{},
                  errors: <GraphQLError>[
                    GraphQLError(message: 'API rate limit exceeded'),
                  ],
                ),
            fallback:
                ({
                  required final String login,
                  required final bool refreshCache,
                }) async {
                  fallbackCalls += 1;
                  return const <HomeRepositoryItem>[];
                },
          );

      expect(
        service.fetch(login: 'octocat', refreshCache: true),
        throwsStateError,
      );
      expect(fallbackCalls, 0);
    });

    test('does not fall back for a valid empty top repository list', () async {
      int fallbackCalls = 0;
      final HomeTopRepositoriesService service =
          HomeTopRepositoriesService.withHandlers(
            query:
                ({
                  required final DocumentNode document,
                  required final Map<String, dynamic> variables,
                  required final bool refreshCache,
                }) async => const Response(
                  response: <String, dynamic>{},
                  data: <String, dynamic>{
                    'viewer': <String, dynamic>{
                      'topRepositories': <String, dynamic>{
                        'nodes': <Map<String, dynamic>>[],
                      },
                    },
                  },
                ),
            fallback:
                ({
                  required final String login,
                  required final bool refreshCache,
                }) async {
                  fallbackCalls += 1;
                  return const <HomeRepositoryItem>[];
                },
          );

      final List<HomeRepositoryItem> repositories = await service.fetch(
        login: 'octocat',
        refreshCache: false,
      );

      expect(repositories, isEmpty);
      expect(fallbackCalls, 0);
    });
  });
}
