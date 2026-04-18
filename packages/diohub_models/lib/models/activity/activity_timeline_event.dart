import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';

import 'package:diohub_models/models/commits/commit_card_data_model.dart';

/// Timeline event types matching GitHub's contribution activity
enum ActivityEventType {
  commit,
  pullRequest,
  issue,
  repositoryCreated,
  review,
}

/// Wrapper class that holds event with timeline flags (avoids copying events)
class TimelineEventWithFlags {
  TimelineEventWithFlags({
    this.event,
    this.isFirst = false,
    this.isLast = false,
    this.isEmpty = false,
    this.emptyYear,
    this.emptyMonth,
  });
  final ActivityTimelineEvent? event;
  final bool isFirst;
  final bool isLast;
  final bool isEmpty;
  // Only used for empty month placeholders
  final int? emptyYear;
  final int? emptyMonth;
}

/// Represents a single activity event in the timeline
class ActivityTimelineEvent {
  ActivityTimelineEvent({
    required this.type,
    required this.date,
    this.title,
    this.repositoryOwner,
    this.repositoryName,
    this.repositoryUrl,
    this.pullRequestNode,
    this.issueNode,
    this.reviewPullRequestNode,
    this.issueData,
    this.pullRequestData,
    this.commitData,
    this.repositoryCardFields,
  });
  final ActivityEventType type;
  final DateTime date;
  final String? title;
  final String? repositoryOwner;
  final String? repositoryName;
  final String? repositoryUrl;

  // Full GraphQL node data (preserves all fields from API)
  final PullCardData? pullRequestNode;
  final IssueCardData? issueNode;
  // For reviews, we store the pull request node from the review contribution
  final PullCardData? reviewPullRequestNode;
  // For commits, we use commitData since it's aggregated from multiple repos

  // Unified data for card widgets (GQL fragment types)
  final IssueCardData? issueData;
  final PullCardData? pullRequestData;
  final CommitCardDataModel? commitData;
  final RepoCardData? repositoryCardFields;

  /// Get display title based on type and GraphQL data
  String get displayTitle {
    if (title != null) return title!;

    // Generate title based on type using GraphQL node data
    switch (type) {
      case ActivityEventType.commit:
        final int count = commitData?.count ?? 1;
        final int repoCount = commitData?.repositories.length ?? 1;
        if (repoCount > 1) {
          return 'Created $count commit${count > 1 ? 's' : ''} in $repoCount repositories';
        }
        return 'Created $count commit${count > 1 ? 's' : ''}';
      case ActivityEventType.pullRequest:
        final int? number = pullRequestNode?.number ?? pullRequestData?.number;
        if (number != null) {
          final String action = pullRequestData == null
              ? 'opened'
              : pullRequestData!.pullRequestState == PullRequestState.MERGED
                  ? 'merged'
                  : pullRequestData!.pullRequestState ==
                          PullRequestState.CLOSED
                      ? 'closed'
                      : 'opened';
          return '${_capitalize(action)} pull request #$number';
        }
        return 'Opened pull request';
      case ActivityEventType.issue:
        final int? number = issueNode?.number ?? issueData?.number;
        if (number != null) {
          final String action =
              issueData?.issueState == IssueState.CLOSED ? 'closed' : 'opened';
          return '${_capitalize(action)} issue #$number';
        }
        return 'Opened issue';
      case ActivityEventType.repositoryCreated:
        return 'Created 1 repository';
      case ActivityEventType.review:
        final int? reviewNumber = pullRequestNode?.number ??
            reviewPullRequestNode?.number ??
            pullRequestData?.number;
        if (reviewNumber != null) {
          return 'Reviewed pull request #$reviewNumber';
        }
        return 'Reviewed pull request';
    }
  }

  static String _capitalize(final String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
