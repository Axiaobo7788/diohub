import 'package:built_collection/src/list.dart';
import 'package:diohub/app/api_handler/dio.dart' show GQLResponse;
import 'package:diohub/services/base/base_service.dart' show ApiClient;
import 'package:diohub_graphql/queries/users/contribution_fragments.graphql.dart';
import 'package:diohub_graphql/queries/users/user_issue_contributions.graphql.dart';
import 'package:diohub_graphql/queries/users/user_pull_request_contributions.graphql.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart' show RepoCardData, RepositoryFields;
import 'package:diohub_graphql/queries/users/user_repository_contributions.graphql.dart';
import 'package:diohub_graphql/queries/users/user_review_contributions.graphql.dart';
import 'package:diohub/models/contributions/chip_detail_models.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';

/// Service for fetching chip-specific contribution details with pagination.
/// Use from providers via [chipDetailsServiceProvider].
class ChipDetailsService {
  ChipDetailsService(this.apiClient);

  final ApiClient apiClient;

  /// Fetch issue contributions with pagination
  Future<IssueChipPage> fetchIssueContributions({
    required final String userName,
    required final DateTime from,
    required final DateTime to,
    final String? after,
    final int first = 50,
  }) async {
    final variables = Variables$Query$userIssueContributions(
      user: userName,
      from: from,
      to: to,
      after: after,
      first: first,
    );
    final GQLResponse response = await apiClient.gql.query(
          documentNodeQueryuserIssueContributions,
          variables.toJson(),
        );

    final data = Query$userIssueContributions.fromJson(response.data!);
    final collection = data.user!.contributionsCollection;

    // Flatten all issue contributions from all repositories
    final List<IssueChipItem> allIssues = <IssueChipItem>[];
    for (final repoContrib in collection.issueContributionsByRepository) {
      final repo = repoContrib.repository;
      final contributions = repoContrib.contributions;
      final nodes = contributions.nodes;

      if (nodes == null) continue;

      for (final node in nodes.whereType<Query$userIssueContributions$user$contributionsCollection$issueContributionsByRepository$contributions$nodes>()) {
        allIssues.add(
          IssueChipItem(
            issue: node.issue,
            repository: repo,
            occurredAt: node.occurredAt,
          ),
        );
      }
    }

    // Sort by occurredAt descending
    allIssues.sort((final IssueChipItem a, final IssueChipItem b) =>
        b.occurredAt.compareTo(a.occurredAt));

    // For pagination, use the pageInfo from the first repository's contributions
    final Query$userIssueContributions$user$contributionsCollection$issueContributionsByRepository?
        firstRepoContrib = collection.issueContributionsByRepository.isNotEmpty
            ? collection.issueContributionsByRepository.first
            : null;
    final Query$userIssueContributions$user$contributionsCollection$issueContributionsByRepository$contributions$pageInfo?
        pageInfo = firstRepoContrib?.contributions.pageInfo;

    return IssueChipPage(
      issues: allIssues,
      hasNextPage: pageInfo?.hasNextPage ?? false,
      endCursor: pageInfo?.endCursor,
      totalCount: collection.totalIssueContributions,
    );
  }

  /// Fetch pull request contributions with pagination
  Future<PullRequestChipPage> fetchPullRequestContributions({
    required final String userName,
    required final DateTime from,
    required final DateTime to,
    final String? after,
    final int first = 50,
  }) async {
    final variables = Variables$Query$userPullRequestContributions(
      user: userName,
      from: from,
      to: to,
      after: after,
      first: first,
    );
    final GQLResponse response = await apiClient.gql.query(
          documentNodeQueryuserPullRequestContributions,
          variables.toJson(),
        );

    final data = Query$userPullRequestContributions.fromJson(response.data!);
    final collection = data.user!.contributionsCollection;

    // Flatten all PR contributions from all repositories
    final List<PullRequestChipItem> allPRs = <PullRequestChipItem>[];
    for (final repoContrib in collection.pullRequestContributionsByRepository) {
      final repo = repoContrib.repository;
      final contributions = repoContrib.contributions;
      final nodes = contributions.nodes;

      if (nodes == null) continue;

      for (final node in nodes.whereType<Query$userPullRequestContributions$user$contributionsCollection$pullRequestContributionsByRepository$contributions$nodes>()) {
        allPRs.add(
          PullRequestChipItem(
            pullRequest: node.pullRequest,
            repository: repo,
            occurredAt: node.occurredAt,
          ),
        );
      }
    }

    // Sort by occurredAt descending
    allPRs.sort((final PullRequestChipItem a, final PullRequestChipItem b) =>
        b.occurredAt.compareTo(a.occurredAt));

    // For pagination, use the pageInfo from the first repository's contributions
    final firstRepoContrib = collection.pullRequestContributionsByRepository.isNotEmpty
            ? collection.pullRequestContributionsByRepository.first
            : null;
    final pageInfo = firstRepoContrib?.contributions.pageInfo;

    return PullRequestChipPage(
      pullRequests: allPRs,
      hasNextPage: pageInfo?.hasNextPage ?? false,
      endCursor: pageInfo?.endCursor,
      totalCount: collection.totalPullRequestContributions,
    );
  }

  /// Fetch review contributions with pagination
  Future<ReviewChipPage> fetchReviewContributions({
    required final String userName,
    required final DateTime from,
    required final DateTime to,
    final String? after,
    final int first = 50,
  }) async {
    final variables = Variables$Query$userReviewContributions(
      user: userName,
      from: from,
      to: to,
      after: after,
      first: first,
    );
    final GQLResponse response = await apiClient.gql.query(
          documentNodeQueryuserReviewContributions,
          variables.toJson(),
        );

    final data = Query$userReviewContributions.fromJson(response.data!);
    final collection = data.user!.contributionsCollection;

    // Flatten all review contributions from all repositories
    final List<ReviewChipItem> allReviews = <ReviewChipItem>[];
    for (final repoContrib in collection.pullRequestReviewContributionsByRepository) {
      final repo = repoContrib.repository;
      final contributions = repoContrib.contributions;
      final nodes = contributions.nodes;

      if (nodes == null) continue;

      for (final node in nodes.whereType<Query$userReviewContributions$user$contributionsCollection$pullRequestReviewContributionsByRepository$contributions$nodes>()) {
        allReviews.add(
          ReviewChipItem(
            pullRequest: node.pullRequest,
            repository: repo,
            occurredAt: node.occurredAt,
          ),
        );
      }
    }

    // Sort by occurredAt descending
    allReviews.sort((final ReviewChipItem a, final ReviewChipItem b) =>
        b.occurredAt.compareTo(a.occurredAt));

    // For pagination, use the pageInfo from the first repository's contributions
    final firstRepoContrib = collection.pullRequestReviewContributionsByRepository.isNotEmpty
            ? collection.pullRequestReviewContributionsByRepository.first
            : null;
    final pageInfo = firstRepoContrib?.contributions.pageInfo;

    return ReviewChipPage(
      reviews: allReviews,
      hasNextPage: pageInfo?.hasNextPage ?? false,
      endCursor: pageInfo?.endCursor,
      totalCount: collection.totalPullRequestReviewContributions,
    );
  }

  /// Fetch created repository contributions with pagination
  Future<CreatedRepoChipPage> fetchCreatedRepoContributions({
    required final String userName,
    required final DateTime from,
    required final DateTime to,
    final String? after,
    final int first = 50,
  }) async {
    final variables = Variables$Query$userRepositoryContributions(
      user: userName,
      from: from,
      to: to,
      after: after,
      first: first,
    );
    final GQLResponse response = await apiClient.gql.query(
          documentNodeQueryuserRepositoryContributions,
          variables.toJson(),
        );

    final data = Query$userRepositoryContributions.fromJson(response.data!);
    final collection = data.user!.contributionsCollection;
    final repoContributions = collection.repositoryContributions;

    final List<CreatedRepoChipItem> repos = <CreatedRepoChipItem>[];
    final nodes = repoContributions.nodes;
    if (nodes != null) {
      for (final node in nodes.whereType<Query$userRepositoryContributions$user$contributionsCollection$repositoryContributions$nodes>()) {
        final repo = node.repository;
        repos.add(
          CreatedRepoChipItem(
            repository: repo,
            occurredAt: node.occurredAt,
          ),
        );
      }
    }

    return CreatedRepoChipPage(
      repositories: repos,
      hasNextPage: repoContributions.pageInfo.hasNextPage,
      endCursor: repoContributions.pageInfo.endCursor,
      totalCount: repoContributions.totalCount,
    );
  }

  /// Fetch commit contributions (repos only, not individual commits)
  /// Uses existing contribution data
  Future<CommitChipDetails> fetchCommitContributions({
    required final ContributionCollectionResult contributionResult,
  }) async {
    final List<CommitRepoItem> repos =
        contributionResult.viewModel.commitContributionsByRepository
            .map(
              (final ContributedRepository repo) => CommitRepoItem(
                repository: repo.graphQLRepository,
                commitCount: repo.commitCount ?? repo.contributionCount,
              ),
            )
            .toList();

    return CommitChipDetails(
      repositories: repos,
      totalCount: contributionResult.viewModel.totalCommitContributions,
    );
  }
}
