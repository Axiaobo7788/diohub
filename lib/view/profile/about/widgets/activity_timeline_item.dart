import 'package:diohub/common/timeline/unified_timeline_item.dart';
import 'package:diohub/common/timeline_content/timeline_commit_content.dart';
import 'package:diohub/common/timeline_content/timeline_issue_content.dart';
import 'package:diohub/common/timeline_content/timeline_pull_request_content.dart';
import 'package:diohub/common/timeline_content/timeline_repository_content.dart';
import 'package:diohub/common/utils/contribution_utils.dart';
import 'package:diohub/common/utils/github_visual_styles.dart';
import 'package:diohub_models/models/visual_state.dart';
import 'package:diohub_models/models/activity/activity_timeline_event.dart';
import 'package:flutter/material.dart';

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
  Widget build(final BuildContext context) {
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
          );
          eventDate = event.commitData!.date;
          actionText = 'pushed';
          const GitHubActionVisual visual = GitHubVisualStyles.push;
          iconData = visual.icon;
          iconColor = visual.color;
        } else {
          return const SizedBox.shrink();
        }
      case ActivityEventType.issue:
        if (event.issueData != null) {
          card = TimelineIssueContent(
            issueData: event.issueData!,
          );
          eventDate = event.issueData!.createdAt;
          // Determine state based on event date vs createdAt/closedAt
          final IssueVisualState issueState = getIssueActionState(
            issue: event.issueData!,
            occurredAt: event.date,
          );
          actionText = issueState.actionText;
          // State-aware icon for issues
          final GitHubActionVisual visual =
              GitHubVisualStyles.fromIssueVisualState(issueState);
          iconData = visual.icon;
          iconColor = visual.color;
        } else {
          return const SizedBox.shrink();
        }
      case ActivityEventType.pullRequest:
        if (event.pullRequestData != null) {
          // Note: from/to refs not available in pullInfoTimeline fragment
          // Only available in REST API events, not GraphQL activity timeline
          card = TimelinePullRequestContent(
            prData: event.pullRequestData!,
          );
          eventDate = event.pullRequestData!.createdAt;
          // Determine state based on event date vs createdAt/mergedAt/closedAt
          final PrVisualState prState = getPullRequestActionState(
            pr: event.pullRequestData!,
            occurredAt: event.date,
          );
          actionText = prState.actionText;
          // State-aware icon and color for PRs
          final GitHubActionVisual visual =
              GitHubVisualStyles.fromPrVisualState(prState);
          iconData = visual.icon;
          iconColor = visual.color;
        } else {
          return const SizedBox.shrink();
        }
      case ActivityEventType.repositoryCreated:
        if (event.repositoryCardFields != null) {
          card = TimelineRepositoryContent(
            repoCardFields: event.repositoryCardFields!,
          );
          eventDate = event.date;
          actionText = 'created';
          const GitHubActionVisual visual = GitHubVisualStyles.repository;
          iconData = visual.icon;
          iconColor = visual.color;
        } else {
          return const SizedBox.shrink();
        }
      case ActivityEventType.review:
        if (event.pullRequestData != null) {
          // Reviews use the same PR card as pull requests
          card = TimelinePullRequestContent(
            prData: event.pullRequestData!,
          );
          eventDate = event.date;
          actionText = 'reviewed';
          // Determine color based on PR state at review time
          final PrVisualState prState = getPullRequestActionState(
            pr: event.pullRequestData!,
            occurredAt: event.date,
          );
          // Use PR color based on state, but icon is always review icon
          final GitHubActionVisual prVisual =
              GitHubVisualStyles.fromPrVisualState(prState);
          iconColor = prVisual.color;
          iconData = GitHubVisualStyles.review.icon;
        } else {
          return const SizedBox.shrink();
        }
    }

    return UnifiedTimelineItem(
      eventIcon: iconData,
      eventIconColor: iconColor,
      actionText: actionText,
      date: eventDate,
      isFirst: isFirst,
      isLast: isLast,
      child: card,
    );
  }
}
