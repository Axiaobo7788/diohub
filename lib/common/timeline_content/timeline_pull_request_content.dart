import 'package:diohub/common/pulls/simple_pull_card.dart';
import 'package:diohub/models/pull_requests/pull_request_card_data_model.dart';
import 'package:flutter/material.dart';

/// Unified content for pull request events in timeline
class TimelinePullRequestContent extends StatelessWidget {
  const TimelinePullRequestContent({
    required this.prUrl,
    this.from,
    this.to,
    this.prData, // Optional: if provided, use SimplePullCard instead of loading
    super.key,
  });

  final String prUrl; // PR URL to fetch full data via SimplePullLoadingCard
  final String? from; // Head branch ref (source branch)
  final String? to; // Base branch ref (target branch)
  final PullRequestCardDataModel? prData; // Optional PR data (from GraphQL)

  @override
  Widget build(BuildContext context) {
    // If prData is provided (from GraphQL), use it directly
    // Otherwise fetch via SimplePullLoadingCard (for REST API events)
    if (prData != null) {
      return SimplePullCard(
        prData!,
        showRepoName: true,
        showDescription: true,
        from: from,
        to: to,
      );
    } else {
      // Fallback: fetch if data is missing (REST API events)
      return SimplePullLoadingCard(
        prUrl,
        showRepoName: true,
        showDescription: true,
        from: from,
        to: to,
      );
    }
  }
}
