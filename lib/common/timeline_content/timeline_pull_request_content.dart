import 'package:diohub/common/pulls/simple_pull_card.dart';
import 'package:flutter/material.dart';

/// Unified content for pull request events in timeline
class TimelinePullRequestContent extends StatelessWidget {
  const TimelinePullRequestContent({
    required this.prUrl,
    this.from,
    this.to,
    super.key,
  });

  final String prUrl; // PR URL to fetch full data via SimplePullLoadingCard
  final String? from; // Head branch ref (source branch)
  final String? to; // Base branch ref (target branch)

  @override
  Widget build(BuildContext context) {
    // PR card - use SimplePullLoadingCard to fetch full PR data
    // from and to refs are displayed in the card itself
    return SimplePullLoadingCard(
      prUrl,
      showRepoName: true,
      showDescription: false,
      from: from,
      to: to,
    );
  }
}
