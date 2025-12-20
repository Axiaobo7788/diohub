import 'package:diohub/graphql/queries/issues_pulls/__generated__/issue_pull_info.data.gql.dart';
import 'package:diohub/models/issues/issue_model.dart';
import 'package:diohub/models/repositories/repo_card_data_model.dart';
import 'package:diohub/models/users/user_info_model.dart';

/// Unified data model for IssueCard that works with both REST and GraphQL
class IssueCardDataModel {
  const IssueCardDataModel({
    required this.title,
    required this.number,
    required this.state,
    required this.url,
    required this.repositoryOwner,
    required this.repositoryName,
    required this.repositoryUrl,
    this.body,
    this.bodyHtml,
    this.commentCount = 0,
    this.createdAt,
    this.updatedAt,
    this.closedAt,
    this.author,
    this.labels,
    this.assignees,
    required this.repositoryData,
  });

  final String title;
  final int number;
  final String state; // OPEN, CLOSED
  final String url;
  final String repositoryOwner;
  final String repositoryName;
  final String repositoryUrl;
  final String? body;
  final String? bodyHtml; // HTML body from GraphQL
  final int commentCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? closedAt;
  final UserInfoModel? author; // Author from GraphQL
  final List<Label>? labels; // Labels from GraphQL
  final List<UserInfoModel>? assignees; // Assignees from GraphQL
  final RepoCardDataModel
      repositoryData; // Full repository metadata from GraphQL

  /// Construct from REST IssueModel
  factory IssueCardDataModel.fromIssueModel(IssueModel issue) {
    // Extract repo from URL
    String repoOwner = '';
    String repoName = '';
    String repoUrl = '';

    if (issue.url != null) {
      final parts =
          issue.url!.replaceAll('https://api.github.com/repos/', '').split('/');
      if (parts.length >= 2) {
        repoOwner = parts[0];
        repoName = parts[1];
        repoUrl = 'https://github.com/$repoOwner/$repoName';
      }
    }

    // Extract repository data if available
    final repositoryData = issue.repository != null
        ? RepoCardDataModel.fromRepositoryModel(issue.repository!)
        : RepoCardDataModel(
            name: repoName,
            url: repoUrl,
            description: null,
            language: null,
          );

    return IssueCardDataModel(
      title: issue.title ?? '',
      number: issue.number ?? 0,
      state: issue.state == IssueState.OPEN ? 'OPEN' : 'CLOSED',
      url: issue.htmlUrl ?? issue.url ?? '',
      repositoryOwner: repoOwner,
      repositoryName: repoName,
      repositoryUrl: repoUrl,
      body: issue.body,
      bodyHtml: issue.bodyHtml, // Preserve HTML body
      commentCount: issue.comments ?? 0,
      createdAt: issue.createdAt,
      updatedAt: issue.updatedAt,
      closedAt: issue.closedAt, // Preserve closedAt
      author: issue.user, // Preserve author
      labels: issue.labels, // Preserve labels
      assignees: issue.assignees, // Preserve assignees
      repositoryData: repositoryData, // Preserve repository data
    );
  }

  /// Construct from GraphQL timeline issue type (uses issueInfoTimeline fragment)
  /// Lightweight version without bodyHTML, labels, assignees, author for activity timeline
  factory IssueCardDataModel.fromGraphQLTimeline(
    GissueInfoTimeline issue,
  ) {
    return _fromGraphQLTimeline(issue);
  }

  /// Construct from GraphQL detail issue type (uses issueInfo fragment)
  /// Full version with bodyHTML, labels, assignees, author for detail views
  factory IssueCardDataModel.fromGraphQLDetail(
    GissueInfo issue,
  ) {
    return _fromGraphQLDetail(issue);
  }

  /// Implementation for timeline fragment (minimal fields)
  static IssueCardDataModel _fromGraphQLTimeline(GissueInfoTimeline issue) {
    return IssueCardDataModel(
      title: issue.title,
      number: issue.number,
      state: issue.state.name,
      url: issue.url.toString(),
      repositoryOwner: issue.repository.owner.login,
      repositoryName: issue.repository.name,
      repositoryUrl: issue.repository.url.toString(),
      body: issue.body,
      bodyHtml: null, // Not in timeline fragment
      commentCount: issue.comments.totalCount,
      createdAt: issue.createdAt,
      updatedAt: null, // Not in timeline fragment
      closedAt: null, // Not in timeline fragment
      author: null, // Not in timeline fragment
      labels: null, // Not in timeline fragment
      assignees: null, // Not in timeline fragment
      repositoryData: RepoCardDataModel(
        name: issue.repository.name,
        url: issue.repository.url.toString(),
        description: null,
        language: null,
      ),
    );
  }

  /// Implementation for detail fragment (all fields)
  static IssueCardDataModel _fromGraphQLDetail(GissueInfo issue) {
    // Extract author
    UserInfoModel? author;
    if (issue.author != null) {
      author = UserInfoModel(
        login: issue.author!.login,
        avatarUrl: issue.author!.avatarUrl.toString(),
      );
    }

    // Extract labels
    List<Label>? labels;
    if (issue.labels?.nodes != null) {
      final nodes = issue.labels!.nodes?.whereType();
      labels = nodes
          ?.map((label) => Label(
                name: label?.name ?? '',
                color: label?.color,
              ))
          .toList();
    }

    // Extract assignees
    List<UserInfoModel>? assignees;
    if (issue.assignees.edges != null) {
      final edges = issue.assignees.edges?.whereType();
      assignees = edges
          ?.map((edge) => edge?.node)
          .whereType()
          .map((user) => UserInfoModel(
                login: user.login,
                avatarUrl: user.avatarUrl?.toString(),
              ))
          .toList();
    }

    return IssueCardDataModel(
      title: issue.title,
      number: issue.number,
      state: issue.state.name,
      url: issue.url.toString(),
      repositoryOwner: issue.repository.owner.login,
      repositoryName: issue.repository.name,
      repositoryUrl: issue.repository.url.toString(),
      body: issue.body,
      bodyHtml: issue.bodyHTML,
      commentCount: issue.comments.totalCount,
      createdAt: issue.createdAt,
      updatedAt: issue.updatedAt,
      closedAt: issue.closedAt,
      author: author,
      labels: labels,
      assignees: assignees,
      repositoryData: RepoCardDataModel(
        name: issue.repository.name,
        url: issue.repository.url.toString(),
        description: null,
        language: null,
      ),
    );
  }
}
