// ignore_for_file: avoid_classes_with_only_static_members

import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/app/global.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_issue_contributions.data.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_issue_contributions.req.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_pull_request_contributions.data.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_pull_request_contributions.req.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_repository_contributions.data.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_repository_contributions.req.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_review_contributions.data.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_review_contributions.req.gql.dart';
import 'package:diohub/models/contributions/chip_detail_models.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:flutter/foundation.dart';

/// Service for fetching chip-specific contribution details with pagination
class ChipDetailsService {
  static final GraphqlHandler _gqlHandler = GraphqlHandler();

  /// Fetch issue contributions with pagination
  static Future<IssueChipDetails> fetchIssueContributions({
    required String userName,
    required DateTime from,
    required DateTime to,
    String? after,
    int first = 50,
  }) async {
    try {
      final response = await _gqlHandler.query(
        GuserIssueContributionsReq(
          (b) => b
            ..vars.user = userName
            ..vars.from = from
            ..vars.to = to
            ..vars.after = after
            ..vars.first = first,
        ),
      );

      final data = GuserIssueContributionsData.fromJson(response.data!)!;
      final collection = data.user!.contributionsCollection;

      // Flatten all issue contributions from all repositories
      final allIssues = <IssueChipItem>[];
      for (final repoContrib in collection.issueContributionsByRepository) {
        final repo = repoContrib.repository as GrepositoryFields;
        final contributions = repoContrib.contributions;
        final nodes = contributions.nodes;

        if (nodes == null) continue;

        for (final node in nodes.whereType<
            GuserIssueContributionsData_user_contributionsCollection_issueContributionsByRepository_contributions_nodes>()) {
          allIssues.add(IssueChipItem(
            issue: node.issue,
            repository: repo,
            occurredAt: node.occurredAt,
          ));
        }
      }

      // Sort by occurredAt descending
      allIssues.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

      // For pagination, use the pageInfo from the first repository's contributions
      final firstRepoContrib =
          collection.issueContributionsByRepository.isNotEmpty
              ? collection.issueContributionsByRepository.first
              : null;
      final pageInfo = firstRepoContrib?.contributions.pageInfo;

      return IssueChipDetails(
        issues: allIssues,
        hasNextPage: pageInfo?.hasNextPage ?? false,
        endCursor: pageInfo?.endCursor,
        totalCount: collection.totalIssueContributions,
      );
    } catch (e, stackTrace) {      rethrow;
    }
  }

  /// Fetch pull request contributions with pagination
  static Future<PullRequestChipDetails> fetchPullRequestContributions({
    required String userName,
    required DateTime from,
    required DateTime to,
    String? after,
    int first = 50,
  }) async {
    try {
      final response = await _gqlHandler.query(
        GuserPullRequestContributionsReq(
          (b) => b
            ..vars.user = userName
            ..vars.from = from
            ..vars.to = to
            ..vars.after = after
            ..vars.first = first,
        ),
      );

      final data = GuserPullRequestContributionsData.fromJson(response.data!)!;
      final collection = data.user!.contributionsCollection;

      // Flatten all PR contributions from all repositories
      final allPRs = <PullRequestChipItem>[];
      for (final repoContrib
          in collection.pullRequestContributionsByRepository) {
        final repo = repoContrib.repository as GrepositoryFields;
        final contributions = repoContrib.contributions;
        final nodes = contributions.nodes;

        if (nodes == null) continue;

        for (final node in nodes.whereType<
            GuserPullRequestContributionsData_user_contributionsCollection_pullRequestContributionsByRepository_contributions_nodes>()) {
          allPRs.add(PullRequestChipItem(
            pullRequest: node.pullRequest,
            repository: repo,
            occurredAt: node.occurredAt,
          ));
        }
      }

      // Sort by occurredAt descending
      allPRs.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

      // For pagination, use the pageInfo from the first repository's contributions
      final firstRepoContrib =
          collection.pullRequestContributionsByRepository.isNotEmpty
              ? collection.pullRequestContributionsByRepository.first
              : null;
      final pageInfo = firstRepoContrib?.contributions.pageInfo;

      return PullRequestChipDetails(
        pullRequests: allPRs,
        hasNextPage: pageInfo?.hasNextPage ?? false,
        endCursor: pageInfo?.endCursor,
        totalCount: collection.totalPullRequestContributions,
      );
    } catch (e, stackTrace) {      rethrow;
    }
  }

  /// Fetch review contributions with pagination
  static Future<ReviewChipDetails> fetchReviewContributions({
    required String userName,
    required DateTime from,
    required DateTime to,
    String? after,
    int first = 50,
  }) async {
    try {
      final response = await _gqlHandler.query(
        GuserReviewContributionsReq(
          (b) => b
            ..vars.user = userName
            ..vars.from = from
            ..vars.to = to
            ..vars.after = after
            ..vars.first = first,
        ),
      );

      final data = GuserReviewContributionsData.fromJson(response.data!)!;
      final collection = data.user!.contributionsCollection;

      // Flatten all review contributions from all repositories
      final allReviews = <ReviewChipItem>[];
      for (final repoContrib
          in collection.pullRequestReviewContributionsByRepository) {
        final repo = repoContrib.repository as GrepositoryFields;
        final contributions = repoContrib.contributions;
        final nodes = contributions.nodes;

        if (nodes == null) continue;

        for (final node in nodes.whereType<
            GuserReviewContributionsData_user_contributionsCollection_pullRequestReviewContributionsByRepository_contributions_nodes>()) {
          allReviews.add(ReviewChipItem(
            pullRequest: node.pullRequest,
            repository: repo,
            occurredAt: node.occurredAt,
          ));
        }
      }

      // Sort by occurredAt descending
      allReviews.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

      // For pagination, use the pageInfo from the first repository's contributions
      final firstRepoContrib =
          collection.pullRequestReviewContributionsByRepository.isNotEmpty
              ? collection.pullRequestReviewContributionsByRepository.first
              : null;
      final pageInfo = firstRepoContrib?.contributions.pageInfo;

      return ReviewChipDetails(
        reviews: allReviews,
        hasNextPage: pageInfo?.hasNextPage ?? false,
        endCursor: pageInfo?.endCursor,
        totalCount: collection.totalPullRequestReviewContributions,
      );
    } catch (e, stackTrace) {      rethrow;
    }
  }

  /// Fetch created repository contributions with pagination
  static Future<CreatedRepoChipDetails> fetchCreatedRepoContributions({
    required String userName,
    required DateTime from,
    required DateTime to,
    String? after,
    int first = 50,
  }) async {
    try {
      final response = await _gqlHandler.query(
        GuserRepositoryContributionsReq(
          (b) => b
            ..vars.user = userName
            ..vars.from = from
            ..vars.to = to
            ..vars.after = after
            ..vars.first = first,
        ),
      );

      final data = GuserRepositoryContributionsData.fromJson(response.data!)!;
      final collection = data.user!.contributionsCollection;
      final repoContributions = collection.repositoryContributions;

      final repos = <CreatedRepoChipItem>[];
      final nodes = repoContributions.nodes;
      if (nodes != null) {
        for (final node in nodes.whereType<
            GuserRepositoryContributionsData_user_contributionsCollection_repositoryContributions_nodes>()) {
          final repo = node.repository as GrepositoryFields;
          repos.add(CreatedRepoChipItem(
            repository: repo,
            occurredAt: node.occurredAt,
          ));
        }
      }

      return CreatedRepoChipDetails(
        repositories: repos,
        hasNextPage: repoContributions.pageInfo.hasNextPage,
        endCursor: repoContributions.pageInfo.endCursor,
        totalCount: repoContributions.totalCount,
      );
    } catch (e, stackTrace) {      rethrow;
    }
  }

  /// Fetch commit contributions (repos only, not individual commits)
  /// Uses existing contribution data
  static Future<CommitChipDetails> fetchCommitContributions({
    required ContributionCollectionResult contributionResult,
  }) async {
    try {
      final repos = contributionResult.viewModel.commitContributionsByRepository
          .map((repo) => CommitRepoItem(
                repository: repo.graphQLRepository,
                commitCount: repo.commitCount ?? repo.contributionCount,
              ))
          .toList();

      return CommitChipDetails(
        repositories: repos,
        totalCount: contributionResult.viewModel.totalCommitContributions,
      );
    } catch (e, stackTrace) {      rethrow;
    }
  }
}
