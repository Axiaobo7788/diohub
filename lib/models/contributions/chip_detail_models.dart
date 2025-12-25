import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';

/// Result for issue chip details with pagination
class IssueChipDetails {
  const IssueChipDetails({
    required this.issues,
    required this.hasNextPage,
    required this.endCursor,
    required this.totalCount,
  });

  final List<IssueChipItem> issues;
  final bool hasNextPage;
  final String? endCursor;
  final int totalCount;
}

/// Individual issue item for chip bottom sheet
class IssueChipItem {
  const IssueChipItem({
    required this.issue,
    required this.repository,
    required this.occurredAt,
  });

  final dynamic issue; // GissueInfoTimeline type from generated code
  final GrepositoryFields repository;
  final DateTime occurredAt;
}

/// Result for pull request chip details with pagination
class PullRequestChipDetails {
  const PullRequestChipDetails({
    required this.pullRequests,
    required this.hasNextPage,
    required this.endCursor,
    required this.totalCount,
  });

  final List<PullRequestChipItem> pullRequests;
  final bool hasNextPage;
  final String? endCursor;
  final int totalCount;
}

/// Individual pull request item for chip bottom sheet
class PullRequestChipItem {
  const PullRequestChipItem({
    required this.pullRequest,
    required this.repository,
    required this.occurredAt,
  });

  final dynamic pullRequest; // GpullInfoTimeline type from generated code
  final GrepositoryFields repository;
  final DateTime occurredAt;
}

/// Result for review chip details with pagination
class ReviewChipDetails {
  const ReviewChipDetails({
    required this.reviews,
    required this.hasNextPage,
    required this.endCursor,
    required this.totalCount,
  });

  final List<ReviewChipItem> reviews;
  final bool hasNextPage;
  final String? endCursor;
  final int totalCount;
}

/// Individual review item for chip bottom sheet
class ReviewChipItem {
  const ReviewChipItem({
    required this.pullRequest,
    required this.repository,
    required this.occurredAt,
  });

  final dynamic pullRequest; // GpullInfoTimeline type from generated code
  final GrepositoryFields repository;
  final DateTime occurredAt;
}

/// Result for created repos chip details with pagination
class CreatedRepoChipDetails {
  const CreatedRepoChipDetails({
    required this.repositories,
    required this.hasNextPage,
    required this.endCursor,
    required this.totalCount,
  });

  final List<CreatedRepoChipItem> repositories;
  final bool hasNextPage;
  final String? endCursor;
  final int totalCount;
}

/// Individual created repo item for chip bottom sheet
class CreatedRepoChipItem {
  const CreatedRepoChipItem({
    required this.repository,
    required this.occurredAt,
  });

  final GrepositoryFields repository;
  final DateTime occurredAt;
}

/// Result for commits chip (repos only, not individual commits)
class CommitChipDetails {
  const CommitChipDetails({
    required this.repositories,
    required this.totalCount,
  });

  final List<CommitRepoItem> repositories;
  final int totalCount;
}

/// Repository with commit count for commits chip
class CommitRepoItem {
  const CommitRepoItem({
    required this.repository,
    required this.commitCount,
  });

  final GrepositoryFields repository;
  final int commitCount;
}










