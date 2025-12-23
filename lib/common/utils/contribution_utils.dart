import 'package:diohub/common/charts/contribution_calendar_widget.dart';
import 'package:diohub/graphql/__generated__/schema.schema.gql.dart';
import 'package:diohub/models/issues/issue_card_data_model.dart';
import 'package:diohub/models/pull_requests/pull_request_card_data_model.dart';
import 'package:flutter/material.dart';

/// Shared utility functions for contribution data processing

/// Formats a DateTime to YYYY-MM-DD string format
String formatDateOnly(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Parses hex color string to Color
///
/// Example: "#9be9a8" -> Color(0xFF9BE9A8)
/// Returns Colors.grey if parsing fails
Color parseContributionColor(String hexColor) {
  try {
    // Remove # if present and ensure uppercase
    final hex = hexColor.replaceFirst('#', '').toUpperCase();
    // Parse as int with alpha channel (FF = fully opaque)
    final colorValue = int.parse('FF$hex', radix: 16);
    return Color(colorValue);
  } catch (e) {
    return Colors.grey;
  }
}

/// Parses list of hex color strings to Color list
List<Color> parseContributionColors(List<String> colors) {
  if (colors.isEmpty) {
    // Default GitHub colors
    return [
      Color(0xFFEBEDF0),
      Color(0xFF9BE9A8),
      Color(0xFF40C463),
      Color(0xFF30A14E),
      Color(0xFF216E39),
    ];
  }
  return colors.map(parseContributionColor).toList();
}

/// Converts GraphQL contribution level to ContributionLevel enum
ContributionLevel convertContributionLevel(GContributionLevel level) {
  switch (level) {
    case GContributionLevel.NONE:
      return ContributionLevel.none;
    case GContributionLevel.FIRST_QUARTILE:
      return ContributionLevel.firstQuartile;
    case GContributionLevel.SECOND_QUARTILE:
      return ContributionLevel.secondQuartile;
    case GContributionLevel.THIRD_QUARTILE:
      return ContributionLevel.thirdQuartile;
    case GContributionLevel.FOURTH_QUARTILE:
      return ContributionLevel.fourthQuartile;
    default:
      return ContributionLevel.none;
  }
}

/// Determines the action that occurred based on occurredAt vs issue dates
/// Returns 'opened' or 'closed' based on which date is closest to occurredAt
String getIssueAction({
  required IssueCardDataModel issue,
  required DateTime occurredAt,
}) {
  // If closedAt is available, check if occurredAt is close to it
  if (issue.closedAt != null) {
    final closedDiff = (occurredAt.difference(issue.closedAt!).inHours).abs();
    final createdDiff = issue.createdAt != null
        ? (occurredAt.difference(issue.createdAt!).inHours).abs()
        : double.infinity;
    
    // If occurredAt is closer to closedAt than createdAt, it was closed
    if (closedDiff < createdDiff && closedDiff < 24) {
      return 'closed';
    }
  }
  
  // Default to opened (either createdAt is closer, or closedAt not available)
  if (issue.createdAt != null) {
    final createdDiff = (occurredAt.difference(issue.createdAt!).inHours).abs();
    if (createdDiff < 24) {
      return 'opened';
    }
  }
  
  // Fallback to current state if dates don't match
  return issue.state == 'CLOSED' ? 'closed' : 'opened';
}

/// Determines the action that occurred based on occurredAt vs PR dates
/// Returns 'opened', 'closed', or 'merged' based on which date is closest to occurredAt
String getPullRequestAction({
  required PullRequestCardDataModel pr,
  required DateTime occurredAt,
}) {
  // Check mergedAt first (highest priority)
  if (pr.mergedAt != null) {
    final mergedDiff = (occurredAt.difference(pr.mergedAt!).inHours).abs();
    if (mergedDiff < 24) {
      return 'merged';
    }
  }
  
  // Check closedAt
  if (pr.closedAt != null) {
    final closedDiff = (occurredAt.difference(pr.closedAt!).inHours).abs();
    final createdDiff = pr.createdAt != null
        ? (occurredAt.difference(pr.createdAt!).inHours).abs()
        : double.infinity;
    
    // If occurredAt is closer to closedAt than createdAt, it was closed
    if (closedDiff < createdDiff && closedDiff < 24) {
      return 'closed';
    }
  }
  
  // Default to opened (either createdAt is closer, or other dates not available)
  if (pr.createdAt != null) {
    final createdDiff = (occurredAt.difference(pr.createdAt!).inHours).abs();
    if (createdDiff < 24) {
      return 'opened';
    }
  }
  
  // Fallback to current state if dates don't match
  if (pr.merged) return 'merged';
  if (pr.state == 'CLOSED') return 'closed';
  return 'opened';
}

/// Gets the border/icon color for an issue based on the action that occurred
/// Uses occurredAt to determine the action, not current state
Color getIssueActionColor({
  required IssueCardDataModel issue,
  required DateTime occurredAt,
}) {
  final action = getIssueAction(issue: issue, occurredAt: occurredAt);
  return action == 'closed' ? Colors.red : Colors.green;
}

/// Gets the border/icon color for a pull request based on the action that occurred
/// Uses occurredAt to determine the action, not current state
Color getPullRequestActionColor({
  required PullRequestCardDataModel pr,
  required DateTime occurredAt,
}) {
  final action = getPullRequestAction(pr: pr, occurredAt: occurredAt);
  switch (action) {
    case 'merged':
      return Colors.deepPurple;
    case 'closed':
      return Colors.red;
    case 'opened':
    default:
      return Colors.green;
  }
}

