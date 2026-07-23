import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/models/home_repository_item.dart';
import 'package:diohub/services/users/user_info_service.dart';
import 'package:diohub_graphql/queries/users/user_repositories_list.graphql.dart';
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub_graphql/schema.graphql.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:gql_exec/gql_exec.dart' show GraphQLError;

typedef HomeTopRepositoriesQuery =
    Future<GQLResponse> Function({
      required DocumentNode document,
      required Map<String, dynamic> variables,
      required bool refreshCache,
    });

typedef HomeTopRepositoriesFallback =
    Future<List<HomeRepositoryItem>> Function({
      required String login,
      required bool refreshCache,
    });

/// Loads the repositories GitHub considers most relevant to the viewer.
///
/// GitHub's `topRepositories` field selects repositories the viewer has
/// contributed to, plus repositories they created. If that field is not
/// available (for example on an older GitHub Enterprise schema), the service
/// falls back to DioHub's existing affiliation-based repository query.
class HomeTopRepositoriesService {
  HomeTopRepositoriesService({
    required final GraphqlHandler graphql,
    required final UserInfoService userInfoService,
  }) : this.withHandlers(
         query:
             ({
               required final DocumentNode document,
               required final Map<String, dynamic> variables,
               required final bool refreshCache,
             }) =>
                 graphql.query(document, variables, refreshCache: refreshCache),
         fallback:
             ({
               required final String login,
               required final bool refreshCache,
             }) async {
               final UserRepositories repositories = await userInfoService
                   .getUserRepositories(
                     login,
                     pageSize,
                     refresh: refreshCache,
                     orderField: Enum$RepositoryOrderField.PUSHED_AT,
                     orderDirection: Enum$OrderDirection.DESC,
                   );
               return _mapAffiliatedRepositories(repositories);
             },
       );

  const HomeTopRepositoriesService.withHandlers({
    required this.query,
    required this.fallback,
  });

  static const int pageSize = 12;
  static const Duration interactionWindow = Duration(days: 365);

  static final DocumentNode _document = parseString(r'''
query HomeTopRepositories($since: DateTime!) {
  viewer {
    topRepositories(
      first: 12
      since: $since
      orderBy: {field: PUSHED_AT, direction: DESC}
    ) {
      nodes {
        id
        name
        nameWithOwner
        isPrivate
        defaultBranchRef {
          name
        }
        owner {
          login
          avatarUrl
        }
      }
    }
  }
}
''');

  final HomeTopRepositoriesQuery query;
  final HomeTopRepositoriesFallback fallback;

  Future<List<HomeRepositoryItem>> fetch({
    required final String login,
    required final bool refreshCache,
    final DateTime? now,
  }) async {
    final DateTime since = (now ?? DateTime.now()).toUtc().subtract(
      interactionWindow,
    );
    final GQLResponse response = await query(
      document: _document,
      variables: <String, dynamic>{'since': since.toIso8601String()},
      refreshCache: refreshCache,
    );
    try {
      return _parseTopRepositories(response);
    } on _TopRepositoriesUnavailable {
      return fallback(login: login, refreshCache: refreshCache);
    } on FormatException {
      return fallback(login: login, refreshCache: refreshCache);
    }
  }

  static List<HomeRepositoryItem> _parseTopRepositories(
    final GQLResponse response,
  ) {
    final List<String> errors = <String>[
      for (final GraphQLError error
          in response.errors?.whereType<GraphQLError>() ??
              const <GraphQLError>[])
        error.message,
    ];
    if (errors.isNotEmpty) {
      if (errors.any(_isUnsupportedFieldError)) {
        throw const _TopRepositoriesUnavailable();
      }
      throw StateError(
        'GitHub returned errors for top repositories: ${errors.join(' | ')}',
      );
    }
    final Map<String, dynamic>? data = response.data;
    final Object? viewerValue = data?['viewer'];
    if (viewerValue is! Map<String, dynamic>) {
      throw const FormatException(
        'GitHub returned an invalid top repositories viewer.',
      );
    }
    final Object? connectionValue = viewerValue['topRepositories'];
    if (connectionValue is! Map<String, dynamic>) {
      throw const FormatException(
        'GitHub returned an invalid top repositories connection.',
      );
    }
    final Object? nodesValue = connectionValue['nodes'];
    if (nodesValue is! List<dynamic>) {
      throw const FormatException(
        'GitHub returned invalid top repository nodes.',
      );
    }

    return nodesValue
        .whereType<Map<String, dynamic>>()
        .map(_itemFromJson)
        .toList(growable: false);
  }

  static bool _isUnsupportedFieldError(final String message) {
    final String normalized = message.toLowerCase();
    return normalized.contains('toprepositories') &&
        (normalized.contains('cannot query field') ||
            normalized.contains("doesn't exist") ||
            normalized.contains('unknown field') ||
            normalized.contains('undefined field'));
  }

  static HomeRepositoryItem _itemFromJson(
    final Map<String, dynamic> repository,
  ) {
    final Object? ownerValue = repository['owner'];
    if (ownerValue is! Map<String, dynamic>) {
      throw const FormatException('Top repository owner is missing.');
    }
    final Object? name = repository['name'];
    final Object? fullName = repository['nameWithOwner'];
    final Object? owner = ownerValue['login'];
    final Object? isPrivate = repository['isPrivate'];
    if (name is! String ||
        fullName is! String ||
        owner is! String ||
        isPrivate is! bool) {
      throw const FormatException('Top repository fields are invalid.');
    }
    final Object? avatarUrl = ownerValue['avatarUrl'];
    final Object? defaultBranchValue = repository['defaultBranchRef'];
    final String? defaultBranch = defaultBranchValue is Map<String, dynamic>
        ? defaultBranchValue['name'] as String?
        : null;
    return HomeRepositoryItem(
      fullName: fullName,
      name: name,
      owner: owner,
      ownerAvatarUrl: avatarUrl?.toString(),
      isPrivate: isPrivate,
      nodeId: repository['id']?.toString(),
      defaultBranch: defaultBranch,
    );
  }

  static List<HomeRepositoryItem> _mapAffiliatedRepositories(
    final UserRepositories repositories,
  ) => <HomeRepositoryItem>[
    for (final UserRepoEdge edge
        in repositories.edges?.whereType<UserRepoEdge>() ??
            const <UserRepoEdge>[])
      if (edge.node
          case final Query$getUserRepositories$user$repositories$edges$node
              node?)
        HomeRepositoryItem(
          fullName: node.nameWithOwner,
          name: node.name,
          owner: node.owner.login,
          ownerAvatarUrl: node.owner.avatarUrl.toString(),
          isPrivate: node.isPrivate,
          nodeId: node.id,
        ),
  ];
}

final class _TopRepositoriesUnavailable implements Exception {
  const _TopRepositoriesUnavailable();
}
