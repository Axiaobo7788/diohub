import 'package:diohub_graphql/queries/users/contribution_fragments.graphql.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_graphql/fragments/issue_card_fields.graphql.dart';
import 'package:diohub_graphql/fragments/pull_card_fields.graphql.dart';

// Lightweight data classes for chip-detail contribution views.
// These hold GraphQL-returned objects with proper types from the generated
// GraphQL code. They are *not* REST models and do not need freezed/json.

// ---------------------------------------------------------------------------
// Item classes (one per contribution entry)
// ---------------------------------------------------------------------------

class IssueChipItem {
  const IssueChipItem({
    required this.issue,
    required this.repository,
    required this.occurredAt,
  });

  final Fragment$issueCardFields issue;
  final Fragment$repositoryFields repository;
  final DateTime occurredAt;
}

class PullRequestChipItem {
  const PullRequestChipItem({
    required this.pullRequest,
    required this.repository,
    required this.occurredAt,
  });

  final Fragment$pullCardFields pullRequest;
  final Fragment$repositoryFields repository;
  final DateTime occurredAt;
}

class ReviewChipItem {
  const ReviewChipItem({
    required this.pullRequest,
    required this.repository,
    required this.occurredAt,
  });

  final Fragment$pullCardFields pullRequest;
  final Fragment$repositoryFields repository;
  final DateTime occurredAt;
}

class CreatedRepoChipItem {
  const CreatedRepoChipItem({
    required this.repository,
    required this.occurredAt,
  });

  final RepoCardData repository;
  final DateTime occurredAt;
}

class CommitRepoItem {
  const CommitRepoItem({required this.repository, required this.commitCount});

  final RepoCardData repository;
  final int commitCount;
}

// ---------------------------------------------------------------------------
// Page types (one page from API; used by pagination source)
// ---------------------------------------------------------------------------

class IssueChipPage {
  const IssueChipPage({
    required this.issues,
    required this.hasNextPage,
    required this.totalCount,
    this.endCursor,
  });
  final List<IssueChipItem> issues;
  final bool hasNextPage;
  final String? endCursor;
  final int totalCount;
}

class PullRequestChipPage {
  const PullRequestChipPage({
    required this.pullRequests,
    required this.hasNextPage,
    required this.totalCount,
    this.endCursor,
  });
  final List<PullRequestChipItem> pullRequests;
  final bool hasNextPage;
  final String? endCursor;
  final int totalCount;
}

class ReviewChipPage {
  const ReviewChipPage({
    required this.reviews,
    required this.hasNextPage,
    required this.totalCount,
    this.endCursor,
  });
  final List<ReviewChipItem> reviews;
  final bool hasNextPage;
  final String? endCursor;
  final int totalCount;
}

class CreatedRepoChipPage {
  const CreatedRepoChipPage({
    required this.repositories,
    required this.hasNextPage,
    required this.totalCount,
    this.endCursor,
  });
  final List<CreatedRepoChipItem> repositories;
  final bool hasNextPage;
  final String? endCursor;
  final int totalCount;
}

// ---------------------------------------------------------------------------
// Detail classes (list + totalCount only; no cursor)
// ---------------------------------------------------------------------------

class IssueChipDetails {
  const IssueChipDetails({required this.issues, required this.totalCount});
  final List<IssueChipItem> issues;
  final int totalCount;
}

class PullRequestChipDetails {
  const PullRequestChipDetails({
    required this.pullRequests,
    required this.totalCount,
  });
  final List<PullRequestChipItem> pullRequests;
  final int totalCount;
}

class ReviewChipDetails {
  const ReviewChipDetails({required this.reviews, required this.totalCount});
  final List<ReviewChipItem> reviews;
  final int totalCount;
}

class CreatedRepoChipDetails {
  const CreatedRepoChipDetails({
    required this.repositories,
    required this.totalCount,
  });
  final List<CreatedRepoChipItem> repositories;
  final int totalCount;
}

class CommitChipDetails {
  const CommitChipDetails({
    required this.repositories,
    required this.totalCount,
  });

  final List<CommitRepoItem> repositories;
  final int totalCount;
}
