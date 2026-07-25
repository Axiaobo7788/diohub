import 'package:diohub_models/models/entity_ref.dart';

/// Compact, transport-independent data required by Repository Issues/PR rows.
///
/// Detail-only fields intentionally stay out of this projection. Opening a row
/// continues to use the existing Issue/PR detail routes and their data sources.
class RepositoryIssuePullSummary {
  const RepositoryIssuePullSummary({
    required this.nodeId,
    required this.repo,
    required this.number,
    required this.title,
    required this.createdAt,
    required this.commentsCount,
    required this.state,
    required this.labels,
    required this.url,
    required this.isPullRequest,
    required this.isDraft,
    required this.isMerged,
    this.author,
    this.closedAt,
    this.mergedAt,
    this.stateReason,
  });

  final String nodeId;
  final RepoRef repo;
  final int number;
  final String title;
  final String? author;
  final DateTime createdAt;
  final DateTime? closedAt;
  final DateTime? mergedAt;
  final int commentsCount;
  final String state;
  final String? stateReason;
  final List<RepositoryIssuePullLabelSummary> labels;
  final Uri url;
  final bool isPullRequest;
  final bool isDraft;
  final bool isMerged;
}

class RepositoryIssuePullLabelSummary {
  const RepositoryIssuePullLabelSummary({
    required this.name,
    required this.color,
  });

  final String name;
  final String color;
}
