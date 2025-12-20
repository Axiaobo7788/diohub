import 'package:diohub/graphql/queries/issues_pulls/__generated__/issue_pull_info.data.gql.dart';
import 'package:diohub/models/issues/issue_model.dart';
import 'package:diohub/models/pull_requests/pull_request_model.dart';
import 'package:diohub/models/repositories/repo_card_data_model.dart';
import 'package:diohub/models/users/user_info_model.dart';

/// Unified data model for PullRequestCard that works with both REST and GraphQL
class PullRequestCardDataModel {
  const PullRequestCardDataModel({
    required this.title,
    required this.number,
    required this.state,
    required this.url,
    required this.repositoryOwner,
    required this.repositoryName,
    required this.repositoryUrl,
    this.body,
    this.bodyHtml,
    this.merged = false,
    this.mergedAt,
    this.createdAt,
    this.updatedAt,
    this.closedAt,
    this.author,
    this.labels,
    this.assignees,
    this.additions = 0,
    this.deletions = 0,
    this.changedFiles = 0,
    required this.repositoryData,
  });

  final String title;
  final int number;
  final String state; // OPEN, CLOSED, MERGED
  final String url;
  final String repositoryOwner;
  final String repositoryName;
  final String repositoryUrl;
  final String? body;
  final String? bodyHtml; // HTML body from GraphQL
  final bool merged;
  final DateTime? mergedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? closedAt;
  final UserInfoModel? author; // Author from GraphQL
  final List<Label>? labels; // Labels from GraphQL
  final List<UserInfoModel>? assignees; // Assignees from GraphQL
  final int additions; // Lines added from GraphQL
  final int deletions; // Lines deleted from GraphQL
  final int changedFiles; // Files changed from GraphQL
  final RepoCardDataModel
      repositoryData; // Full repository metadata from GraphQL

  /// Get action string for display
  String get action {
    if (merged) return 'merged';
    if (state == 'CLOSED') return 'closed';
    return 'opened';
  }

  /// Construct from REST PullRequestModel
  factory PullRequestCardDataModel.fromPullRequestModel(
    PullRequestModel pr,
  ) {
    // Extract repo from URL
    String repoOwner = '';
    String repoName = '';
    String repoUrl = '';

    if (pr.url != null) {
      final parts =
          pr.url!.replaceAll('https://api.github.com/repos/', '').split('/');
      if (parts.length >= 2) {
        repoOwner = parts[0];
        repoName = parts[1];
        repoUrl = 'https://github.com/$repoOwner/$repoName';
      }
    }

    // Extract repository data if available
    final repositoryData = RepoCardDataModel(
      name: repoName,
      url: repoUrl,
      description: null, // Not available in PullRequestModel
      language: null, // Not available in PullRequestModel
    );

    return PullRequestCardDataModel(
      title: pr.title ?? '',
      number: pr.number ?? 0,
      state: pr.state == IssueState.OPEN
          ? 'OPEN'
          : (pr.merged == true ? 'MERGED' : 'CLOSED'),
      url: pr.htmlUrl ?? pr.url ?? '',
      repositoryOwner: repoOwner,
      repositoryName: repoName,
      repositoryUrl: repoUrl,
      body: pr.body,
      bodyHtml: pr.bodyHtml, // Preserve HTML body
      merged: pr.merged ?? false,
      mergedAt: pr.mergedAt,
      createdAt: pr.createdAt,
      updatedAt: pr.updatedAt,
      closedAt: pr.closedAt, // Preserve closedAt
      author: pr.user, // Preserve author
      labels: pr.labels, // Preserve labels
      assignees: pr.assignees, // Preserve assignees
      additions: pr.additions ?? 0, // Preserve additions
      deletions: pr.deletions ?? 0, // Preserve deletions
      changedFiles: pr.changedFiles ?? 0, // Preserve changedFiles
      repositoryData: repositoryData, // Preserve repository data
    );
  }

  /// Construct from GraphQL timeline PR type (uses pullInfoTimeline fragment)
  /// Lightweight version without bodyHTML, labels, assignees, author for activity timeline
  factory PullRequestCardDataModel.fromGraphQLTimeline(
    GpullInfoTimeline pr,
  ) {
    return _fromGraphQLTimeline(pr);
  }

  /// Construct from GraphQL detail PR type (uses pullInfo fragment)
  /// Full version with bodyHTML, labels, assignees, author for detail views
  factory PullRequestCardDataModel.fromGraphQLDetail(
    GpullInfo pr,
  ) {
    return _fromGraphQLDetail(pr);
  }

  /// Implementation for timeline fragment (minimal fields)
  static PullRequestCardDataModel _fromGraphQLTimeline(GpullInfoTimeline pr) {
    return PullRequestCardDataModel(
      title: pr.title,
      number: pr.number,
      state: pr.state.name,
      url: pr.url.toString(),
      repositoryOwner: pr.repository.owner.login,
      repositoryName: pr.repository.name,
      repositoryUrl: pr.repository.url.toString(),
      body: pr.body,
      bodyHtml: null, // Not in timeline fragment
      merged: pr.merged,
      mergedAt: pr.mergedAt,
      createdAt: pr.createdAt,
      updatedAt: null, // Not in timeline fragment
      closedAt: null, // Not in timeline fragment
      author: null, // Not in timeline fragment
      labels: null, // Not in timeline fragment
      assignees: null, // Not in timeline fragment
      additions: 0, // Not in timeline fragment
      deletions: 0, // Not in timeline fragment
      changedFiles: 0, // Not in timeline fragment
      repositoryData: RepoCardDataModel(
        name: pr.repository.name,
        url: pr.repository.url.toString(),
        description: null,
        language: null,
      ),
    );
  }

  /// Implementation for detail fragment (all fields)
  static PullRequestCardDataModel _fromGraphQLDetail(GpullInfo pr) {
    // Extract author
    UserInfoModel? author;
    if (pr.author != null) {
      author = UserInfoModel(
        login: pr.author!.login,
        avatarUrl: pr.author!.avatarUrl.toString(),
      );
    }

    // Extract labels
    List<Label>? labels;
    if (pr.labels?.nodes != null) {
      final nodes = pr.labels!.nodes?.whereType();
      labels = nodes
          ?.map((label) => Label(
                name: label?.name ?? '',
                color: label?.color,
              ))
          .toList();
    }

    // Extract assignees
    List<UserInfoModel>? assignees;
    if (pr.assignees.edges != null) {
      final edges = pr.assignees.edges?.whereType();
      assignees = edges
          ?.map((edge) => edge?.node)
          .whereType()
          .map((user) => UserInfoModel(
                login: user.login,
                avatarUrl: user.avatarUrl?.toString(),
              ))
          .toList();
    }

    return PullRequestCardDataModel(
      title: pr.title,
      number: pr.number,
      state: pr.state.name,
      url: pr.url.toString(),
      repositoryOwner: pr.repository.owner.login,
      repositoryName: pr.repository.name,
      repositoryUrl: pr.repository.url.toString(),
      body: pr.body,
      bodyHtml: pr.bodyHTML,
      merged: pr.merged,
      mergedAt: pr.mergedAt,
      createdAt: pr.createdAt,
      updatedAt: pr.updatedAt,
      closedAt: pr.closedAt,
      author: author,
      labels: labels,
      assignees: assignees,
      additions: pr.additions,
      deletions: pr.deletions,
      changedFiles: pr.changedFiles,
      repositoryData: RepoCardDataModel(
        name: pr.repository.name,
        url: pr.repository.url.toString(),
        description: null,
        language: null,
      ),
    );
  }
}
