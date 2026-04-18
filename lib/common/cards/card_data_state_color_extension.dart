import 'package:diohub/common/utils/github_visual_styles.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_models/models/visual_state.dart';
import 'package:flutter/material.dart';

/// Extension to compute state color for IssueCardData (GraphQL fragment).
extension IssueCardDataStateColor on IssueCardData {
  Color? computeStateColor() {
    final state = IssueVisualState.fromNames(
      issueState.name,
      reasonName: stateReason?.name,
    );
    return GitHubVisualStyles.fromIssueVisualState(state).color;
  }
}

/// Extension to compute state color for PullCardData (GraphQL fragment).
extension PullCardDataStateColor on PullCardData {
  Color? computeStateColor() {
    final state = PrVisualState.fromNames(
      pullRequestState.name,
      isDraft: isDraft,
    );
    return GitHubVisualStyles.fromPrVisualState(state).color;
  }
}
