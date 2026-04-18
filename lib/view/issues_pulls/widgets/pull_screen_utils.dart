import 'package:diohub/common/widgets/metadata_composites.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_graphql/fragments/pull_detail_fields.graphql.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/navigable.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Extracts CI check run rows from PR status check rollup for bottom sheet and Checks tab.
List<CICheckRunRowData> ciRunsFromStatusCheckRollup(
  PullStatusCheckRollup? rollup,
) {
  final List<
          PullStatusCheckNode?>
      nodes = rollup?.contexts.nodes?.toList() ??
          <PullStatusCheckNode?>[];
  final List<CICheckRunRowData> runs = <CICheckRunRowData>[];
  for (final n in nodes) {
    if (n == null) continue;
    final CICheckRunRowData? run = switch (n) {
      Fragment$pullDetailFields$statusCheckRollup$contexts$nodes$$CheckRun c => CICheckRunRowData(
        name: c.name,
        conclusion: c.conclusion?.name,
        status: c.status.name,
        detailsUrl: c.detailsUrl?.toString(),
        startedAt: c.startedAt?.toIso8601String(),
        completedAt: c.completedAt?.toIso8601String(),
        appName: c.checkSuite.app?.name,
        appLogoUrl: c.checkSuite.app?.logoUrl.toString(),
        checkSuiteDatabaseId: c.checkSuite.databaseId,
      ),
      Fragment$pullDetailFields$statusCheckRollup$contexts$nodes$$StatusContext s => CICheckRunRowData(
        name: s.context,
        conclusion: s.state.name,
        status: null,
        detailsUrl: s.targetUrl?.toString(),
      ),
      _ => null,
    };
    if (run != null) runs.add(run);
  }
  return runs;
}

/// Builds reviewer coverage rows for the reviewers bottom sheet.
List<ReviewCoverageRowData> reviewerCoverageFromPull(
  PullInfo data,
  BuildContext context,
  WidgetRef ref,
) {
  final List<ReviewCoverageRowData> rows = <ReviewCoverageRowData>[];
  final Set<String> seenLogins = <String>{};
  final List<PullLatestReviewNode?>
      reviews = data.latestReviews?.nodes?.toList() ??
          <PullLatestReviewNode?>[];
  for (final n in reviews) {
    if (n == null || n.author == null) continue;
    final String login = n.author!.login;
    if (seenLogins.contains(login)) continue;
    seenLogins.add(login);
    rows.add(
      ReviewCoverageRowData(
        login: login,
        avatarUrl: n.author!.avatarUrl.toString(),
        state: n.state.name,
        onTap: () => UserRef(login: login).navigate(context, ref),
      ),
    );
  }
  final List<PullReviewRequestNode?>
      requests = data.reviewRequests?.nodes?.toList() ??
          <PullReviewRequestNode?>[];
  for (final n in requests) {
    if (n == null) continue;
    final String? login = n.requestedReviewer == null ? null : switch (n.requestedReviewer!) {
      Fragment$pullDetailFields$reviewRequests$nodes$requestedReviewer$$User u => u.login,
      Fragment$pullDetailFields$reviewRequests$nodes$requestedReviewer$$Team t => t.name,
      _ => null,
    };
    if (login == null || seenLogins.contains(login)) continue;
    seenLogins.add(login);
    final String? avatarUrl = n.requestedReviewer == null ? null : switch (n.requestedReviewer!) {
      Fragment$pullDetailFields$reviewRequests$nodes$requestedReviewer$$User u => u.userAvatarUrl.toString(),
      Fragment$pullDetailFields$reviewRequests$nodes$requestedReviewer$$Team t => t.teamAvatarUrl?.toString(),
      _ => null,
    };
    rows.add(
      ReviewCoverageRowData(
        login: login,
        avatarUrl: avatarUrl ?? '',
        state: 'PENDING',
        onTap: () => UserRef(login: login).navigate(context, ref),
      ),
    );
  }
  return rows;
}
