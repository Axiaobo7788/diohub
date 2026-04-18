import 'package:diohub/common/charts/contribution_calendar_widget.dart';
import 'package:diohub/common/utils/github_visual_styles.dart';
import 'package:diohub_graphql/schema_typedefs.dart' as gql;
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub/utils/hex_color.dart';
import 'package:diohub_models/models/contributions/contribution_day.dart';

import 'package:diohub_models/models/visual_state.dart';
import 'package:flutter/material.dart';

/// Shared utility functions for contribution data processing

/// Default GitHub contribution colors (for calendar/heatmap visualizations).
const List<Color> kDefaultContributionColors = <Color>[
  Color(0xFFEBEDF0), // lightest (no contributions)
  Color(0xFF9BE9A8), // light green
  Color(0xFF40C463), // medium green
  Color(0xFF30A14E), // dark green
  Color(0xFF216E39), // darkest green
];

/// Formats a DateTime to YYYY-MM-DD string format
String formatDateOnly(final DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// Parses hex color string to Color
///
/// Example: "#9be9a8" -> Color(0xFF9BE9A8)
/// Returns Colors.grey if parsing fails
Color parseContributionColor(final String hexColor) {
  return tryParseHexColor(hexColor, fallback: Colors.grey) ?? Colors.grey;
}

/// Parses list of hex color strings to Color list
List<Color> parseContributionColors(final List<String> colors) {
  if (colors.isEmpty) {
    return kDefaultContributionColors;
  }
  return colors.map(parseContributionColor).toList();
}

/// Converts GraphQL contribution level to ContributionLevel enum
ContributionLevel convertContributionLevel(final gql.ContributionLevel level) {
  switch (level) {
    case gql.ContributionLevel.NONE:
      return ContributionLevel.none;
    case gql.ContributionLevel.FIRST_QUARTILE:
      return ContributionLevel.firstQuartile;
    case gql.ContributionLevel.SECOND_QUARTILE:
      return ContributionLevel.secondQuartile;
    case gql.ContributionLevel.THIRD_QUARTILE:
      return ContributionLevel.thirdQuartile;
    case gql.ContributionLevel.FOURTH_QUARTILE:
      return ContributionLevel.fourthQuartile;
    default:
      return ContributionLevel.none;
  }
}

/// Determines the visual state that occurred based on occurredAt vs issue dates.
/// Returns [IssueVisualState.closed] or [IssueVisualState.open] based on which
/// date is closest to occurredAt.
IssueVisualState getIssueActionState({
  required final IssueCardData issue,
  required final DateTime occurredAt,
}) {
  // If closedAt is available, check if occurredAt is close to it
  if (issue.closedAt != null) {
    final int closedDiff = occurredAt.difference(issue.closedAt!).inHours.abs();
    final num createdDiff = occurredAt
        .difference(issue.createdAt)
        .inHours
        .abs();

    // If occurredAt is closer to closedAt than createdAt, it was closed
    if (closedDiff < createdDiff && closedDiff < 24) {
      return IssueVisualState.closed;
    }
  }

  // Default to opened (either createdAt is closer, or closedAt not available)
  final int createdDiff = occurredAt.difference(issue.createdAt).inHours.abs();
  if (createdDiff < 24) {
    return IssueVisualState.open;
  }

  // Fallback to current state if dates don't match
  return issue.issueState == gql.IssueState.CLOSED
      ? IssueVisualState.closed
      : IssueVisualState.open;
}

/// Determines the visual state that occurred based on occurredAt vs PR dates.
/// Returns [PrVisualState.merged], [PrVisualState.closed], or [PrVisualState.open]
/// based on which date is closest to occurredAt.
PrVisualState getPullRequestActionState({
  required final PullCardData pr,
  required final DateTime occurredAt,
}) {
  // Check mergedAt first (highest priority)
  if (pr.mergedAt != null) {
    final int mergedDiff = occurredAt.difference(pr.mergedAt!).inHours.abs();
    if (mergedDiff < 24) {
      return PrVisualState.merged;
    }
  }

  // Check closedAt
  if (pr.closedAt != null) {
    final int closedDiff = occurredAt.difference(pr.closedAt!).inHours.abs();
    final num createdDiff = occurredAt.difference(pr.createdAt).inHours.abs();

    // If occurredAt is closer to closedAt than createdAt, it was closed
    if (closedDiff < createdDiff && closedDiff < 24) {
      return PrVisualState.closed;
    }
  }

  // Default to opened (either createdAt is closer, or other dates not available)
  final int createdDiff = occurredAt.difference(pr.createdAt).inHours.abs();
  if (createdDiff < 24) {
    return PrVisualState.open;
  }

  // Fallback to current state if dates don't match
  if (pr.pullRequestState == gql.PullRequestState.MERGED)
    return PrVisualState.merged;
  if (pr.pullRequestState == gql.PullRequestState.CLOSED)
    return PrVisualState.closed;
  return PrVisualState.open;
}

/// Gets the border/icon color for an issue based on the action that occurred.
/// Uses occurredAt to determine the action, not current state.
Color getIssueActionColor({
  required final IssueCardData issue,
  required final DateTime occurredAt,
}) {
  final IssueVisualState state = getIssueActionState(
    issue: issue,
    occurredAt: occurredAt,
  );
  return GitHubVisualStyles.fromIssueVisualState(state).color;
}

/// Gets the border/icon color for a pull request based on the action that occurred.
/// Uses occurredAt to determine the action, not current state.
Color getPullRequestActionColor({
  required final PullCardData pr,
  required final DateTime occurredAt,
}) {
  final PrVisualState state = getPullRequestActionState(
    pr: pr,
    occurredAt: occurredAt,
  );
  return GitHubVisualStyles.fromPrVisualState(state).color;
}
