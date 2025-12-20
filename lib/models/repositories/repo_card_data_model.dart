import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';
import 'package:diohub/models/repositories/repository_model.dart';

/// A unified data model for RepositoryCard that can be constructed from
/// either RepositoryModel or GraphQL repository types
class RepoCardDataModel {
  const RepoCardDataModel({
    required this.name,
    required this.url,
    this.description,
    this.language,
    this.stargazersCount = 0,
    this.private = false,
    this.fork = false,
    this.contributionCount,
  });

  final String name;
  final String url;
  final String? description;
  final String? language;
  final int stargazersCount;
  final bool private;
  final bool fork;
  final int? contributionCount;

  /// Construct from RepositoryModel
  factory RepoCardDataModel.fromRepositoryModel(RepositoryModel repo) {
    return RepoCardDataModel(
      name: repo.name ?? '',
      url: repo.url ?? '',
      description: repo.description,
      language: repo.language,
      stargazersCount: repo.stargazersCount ?? 0,
      private: repo.private ?? false,
      fork: repo.fork ?? false,
    );
  }

  /// Construct from GraphQL repository type (uses repositoryFields fragment)
  /// Works with any repository type that implements GrepositoryFields
  factory RepoCardDataModel.fromGraphQL(GrepositoryFields repo) {
    return _fromGraphQLCommon(repo);
  }

  /// Common implementation for repository types
  /// Uses dynamic to work with any repository fragment type
  static RepoCardDataModel _fromGraphQLCommon(dynamic repo) {
    String? language;
    if (repo.languages?.edges?.isNotEmpty ?? false) {
      final firstEdge = repo.languages!.edges!.first;
      language = firstEdge?.node?.name;
    }

    return RepoCardDataModel(
      name: repo.name,
      url: repo.url.toString(),
      description: repo.description,
      language: language,
      stargazersCount: repo.stargazerCount,
      private: repo.isPrivate,
      fork: repo.isFork,
    );
  }
}
