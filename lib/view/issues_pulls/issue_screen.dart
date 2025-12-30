// NOTE: After updating GraphQL fragments, run: flutter pub run build_runner build
// to regenerate types with new repository fields (stargazerCount, forkCount, watchers, etc.)

import 'package:diohub/common/misc/info_card.dart';
import 'package:diohub/graphql/__generated__/schema.schema.gql.dart';
import 'package:diohub/graphql/queries/issues_pulls/__generated__/issue_pull_info.data.gql.dart';
import 'package:diohub/graphql/queries/issues_pulls/__generated__/timeline.data.gql.dart';
import 'package:diohub/view/issues_pulls/issue_pull_info_template.dart';
import 'package:diohub/view/issues_pulls/models/issue_pull_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class IssueScreen extends StatefulWidget {
  const IssueScreen(
    this.issueInfo, {
    required this.onRefresh,
    this.initialIndex = 0,
    this.commentsSince,
    super.key,
  });

  final GissueInfo issueInfo;
  final DateTime? commentsSince;
  final int initialIndex;
  final Future<void> Function() onRefresh;

  @override
  IssueScreenState createState() => IssueScreenState();
}

class IssueScreenState extends State<IssueScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(final BuildContext context) {
    final GissueInfo data = widget.issueInfo;
    final repo = data.repository;

    return IssuePullInfoTemplate(
      number: data.number,
      isPinned: data.isPinned ?? false,
      title: data.titleHTML,
      reactionGroups: data.reactionGroups!.toList(),
      viewerCanReact: data.viewerCanReact,
      commentCount: data.comments.totalCount,
      repoInfo: repo,
      state: IssuePullState(data.state),
      bodyHTML: data.bodyHTML,
      assigneesInfo: data.assignees,
      body: data.body,
      labels: data.labels!.nodes!.toList(),
      createdAt: data.createdAt,
      createdBy: data.author,
      onRefresh: widget.onRefresh,
      participantsInfo: UnfinishedList<Gactor>(
        limitedAvailableList: data.participants.nodes!
            .map((final GissueInfo_participants_nodes? e) => e!)
            .toList(),
        totalCount: data.participants.totalCount,
      ),
      uri: data.url,
      linkedIssues: data.trackedIssues,
      linkedIssuesTrackedIn: data.trackedInIssues,
      viewerCanUpdate: data.viewerCanUpdate ?? false,
      actionButtons: _buildActionButtons(context, data),
    );
  }

  List<Widget> _buildActionButtons(
    final BuildContext context,
    final GissueInfo data,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isOpen = data.state == GIssueState.OPEN;
    final isLocked = data.locked ?? false;
    final isPinned = data.isPinned ?? false;

    return [
      // Close/Reopen button
      if (data.viewerCanUpdate ?? false)
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Implement close/reopen action
          },
          icon: Icon(
            isOpen ? Octicons.issue_closed : Octicons.issue_reopened,
            size: 16,
          ),
          label: Text(isOpen ? 'Close' : 'Reopen'),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isOpen ? colorScheme.error : colorScheme.primaryContainer,
            foregroundColor:
                isOpen ? colorScheme.onError : colorScheme.onPrimaryContainer,
          ),
        ),
      // Pin/Unpin button
      if (data.viewerCanUpdate ?? false)
        OutlinedButton.icon(
          onPressed: () {
            // TODO: Implement pin/unpin action
          },
          icon: Icon(
            Octicons.pin,
            size: 16,
            color:
                isPinned ? colorScheme.tertiary : colorScheme.onSurfaceVariant,
          ),
          label: Text(isPinned ? 'Unpin' : 'Pin'),
          style: OutlinedButton.styleFrom(
            foregroundColor:
                isPinned ? colorScheme.tertiary : colorScheme.onSurfaceVariant,
          ),
        ),
      // Lock/Unlock button
      if (data.viewerCanUpdate ?? false)
        OutlinedButton.icon(
          onPressed: () {
            // TODO: Implement lock/unlock action
          },
          icon: Icon(
            Octicons.lock,
            size: 16,
            color: isLocked ? colorScheme.error : colorScheme.onSurfaceVariant,
          ),
          label: Text(isLocked ? 'Unlock' : 'Lock'),
          style: OutlinedButton.styleFrom(
            foregroundColor:
                isLocked ? colorScheme.error : colorScheme.onSurfaceVariant,
          ),
        ),
    ];
  }

  Widget? getIcon(final GIssueState state, final double size) {
    switch (state) {
      case GIssueState.CLOSED:
        return Icon(
          Octicons.issue_closed,
          color: Colors.red,
          size: size,
        );
      case GIssueState.OPEN:
        return Icon(
          Octicons.issue_opened,
          color: Colors.green,
          size: size,
        );
    }
    return null;
  }
}
