import 'package:diohub/common/timeline/unified_timeline_item.dart';
import 'package:diohub/common/timeline_content/timeline_commit_content.dart';
import 'package:diohub/common/timeline_content/timeline_issue_content.dart';
import 'package:diohub/common/timeline_content/timeline_pull_request_content.dart';
import 'package:diohub/common/timeline_content/timeline_repository_content.dart';
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
          final state =
              event.issueData!.state == 'CLOSED' ? 'closed' : 'opened';
          actionText = state;
          // State-aware icon for issues
          if (event.issueData!.state == 'CLOSED') {
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
          actionText = event.pullRequestData!.action;
          // State-aware icon and color for PRs
          if (event.pullRequestData!.merged) {
            iconData = Octicons.git_merge;
            iconColor = Colors.deepPurple; // Purple for merged
          } else if (event.pullRequestData!.state == 'CLOSED') {
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
