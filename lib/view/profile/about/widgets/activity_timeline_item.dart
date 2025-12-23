import 'package:diohub/common/timeline/unified_timeline_item.dart';
import 'package:diohub/common/timeline_content/timeline_commit_content.dart';
import 'package:diohub/common/timeline_content/timeline_issue_content.dart';
import 'package:diohub/common/timeline_content/timeline_pull_request_content.dart';
import 'package:diohub/common/timeline_content/timeline_repository_content.dart';
import 'package:diohub/common/utils/contribution_utils.dart';
import 'package:diohub/view/profile/about/widgets/activity_timeline_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Widget that displays a single activity timeline event using unified card widgets
/// Includes TimelineTile for visual timeline with icons and connecting lines
class ActivityTimelineItem extends StatelessWidget {
  const ActivityTimelineItem({
    required this.event,
    required this.userLogin,
    required this.userAvatarUrl,
    this.isFirst = false,
    this.isLast = false,
    super.key,
  });

  final ActivityTimelineEvent event;
  final String userLogin;
  final String? userAvatarUrl;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    Widget card;
    String actionText;
    DateTime? eventDate;
    IconData? iconData;
    Color? iconColor;

    switch (event.type) {
      case ActivityEventType.commit:
        if (event.commitData != null) {
          card = TimelineCommitContent(
            commitData: event.commitData!,
            userLogin: userLogin,
            userEmail: null,
          );
          eventDate = event.commitData!.date;
          actionText = 'pushed';
          iconData = Octicons.git_commit;
          iconColor = const Color(0xFF2196F3); // Blue
        } else {
          return const SizedBox.shrink();
        }
        break;
      case ActivityEventType.issue:
        if (event.issueData != null) {
          card = TimelineIssueContent(
            issueData: event.issueData!,
          );
          eventDate = event.issueData!.createdAt;
          // Determine action based on event date vs createdAt/closedAt
          actionText = getIssueAction(
            issue: event.issueData!,
            occurredAt: event.date,
          );
          // State-aware icon for issues based on action
          if (actionText == 'closed') {
            iconData = Octicons.issue_closed;
            iconColor = Colors.red; // Red for closed
          } else {
            iconData = Octicons.issue_opened;
            iconColor = Colors.green; // Green for open
          }
        } else {
          return const SizedBox.shrink();
        }
        break;
      case ActivityEventType.pullRequest:
        if (event.pullRequestData != null) {
          // Note: from/to refs not available in pullInfoTimeline fragment
          // Only available in REST API events, not GraphQL activity timeline
          // Pass prData to skip loading card - we already have the data
          card = TimelinePullRequestContent(
            prUrl: event.pullRequestData!.url,
            from: null,
            to: null,
            prData: event.pullRequestData!, // Pass data to skip loading
          );
          eventDate = event.pullRequestData!.createdAt;
          // Determine action based on event date vs createdAt/mergedAt/closedAt
          actionText = getPullRequestAction(
            pr: event.pullRequestData!,
            occurredAt: event.date,
          );
          // State-aware icon and color for PRs based on action
          if (actionText == 'merged') {
            iconData = Octicons.git_merge;
            iconColor = Colors.deepPurple; // Purple for merged
          } else if (actionText == 'closed') {
            iconData = Octicons.git_pull_request_closed;
            iconColor = Colors.red; // Red for closed
          } else {
            iconData = Octicons.git_pull_request;
            iconColor = Colors.green; // Green for open
          }
        } else {
          return const SizedBox.shrink();
        }
        break;
      case ActivityEventType.repositoryCreated:
        if (event.repositoryData != null) {
          card = TimelineRepositoryContent(
            repoData: event.repositoryData!,
          );
          eventDate = event.date;
          actionText = 'created';
          iconData = Octicons.repo;
          iconColor = const Color(0xFF009688); // Teal
        } else {
          return const SizedBox.shrink();
        }
        break;
      case ActivityEventType.review:
        if (event.pullRequestData != null) {
          // Reviews use the same PR card as pull requests
          card = TimelinePullRequestContent(
            prUrl: event.pullRequestData!.url,
            from: null,
            to: null,
            prData: event.pullRequestData!,
          );
          eventDate = event.date;
          actionText = 'reviewed';
          // Determine color based on PR action at review time
          final prAction = getPullRequestAction(
            pr: event.pullRequestData!,
            occurredAt: event.date,
          );
          // Use PR color based on action, but icon is always review icon
          if (prAction == 'merged') {
            iconColor = Colors.deepPurple; // Purple for merged
          } else if (prAction == 'closed') {
            iconColor = Colors.red; // Red for closed
          } else {
            iconColor = Colors.green; // Green for open
          }
          iconData = Octicons.eye; // Review icon
        } else {
          return const SizedBox.shrink();
        }
        break;
    }

    return UnifiedTimelineItem(
      eventIcon: iconData,
      eventIconColor: iconColor,
      actionText: actionText,
      highlighted: true,
      date: eventDate,
      isFirst: isFirst,
      isLast: isLast,
      child: card,
    );
  }
}
