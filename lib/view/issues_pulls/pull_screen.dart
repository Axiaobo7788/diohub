// NOTE: After updating GraphQL fragments, run: flutter pub run build_runner build
// to regenerate types with new repository fields (stargazerCount, forkCount, watchers, etc.)

import 'package:diohub/common/misc/detail_tile.dart';
import 'package:diohub/common/misc/detail_tile_content.dart';
import 'package:diohub/common/misc/info_card.dart';
import 'package:diohub/graphql/__generated__/schema.schema.gql.dart';
import 'package:diohub/graphql/queries/issues_pulls/__generated__/issue_pull_info.data.gql.dart';
import 'package:diohub/graphql/queries/issues_pulls/__generated__/timeline.data.gql.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/view/issues_pulls/issue_pull_info_template.dart';
import 'package:diohub/view/issues_pulls/models/issue_pull_state.dart';
import 'package:diohub/view/issues_pulls/widgets/pull_changed_files_list.dart';
import 'package:diohub/view/issues_pulls/widgets/pulls_commits_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dynamic_tabs/flutter_dynamic_tabs.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class PullScreen extends StatefulWidget {
  const PullScreen(
    this.pullInfo, {
    this.initialIndex = 0,
    this.commentsSince,
    super.key,
    required this.onRefresh,
  });

  final GpullInfo pullInfo;
  final DateTime? commentsSince;
  final int initialIndex;
  final Future<void> Function() onRefresh;

  @override
  PullScreenState createState() => PullScreenState();
}

class PullScreenState extends State<PullScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    tabController = TabController(
      length: 4,
      initialIndex: widget.initialIndex,
      vsync: this,
    );
    super.initState();
  }

  final GlobalKey<IssuePullInfoTemplateState> _templateKey =
      GlobalKey<IssuePullInfoTemplateState>();

  @override
  Widget build(final BuildContext context) {
    final GpullInfo data = widget.pullInfo;
    final repo = data.repository;

    return IssuePullInfoTemplate(
      key: _templateKey,
      number: data.number,
      isPinned: false,
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
      participantsInfo: UnfinishedList<Gactor>(
        limitedAvailableList: data.participants.nodes!
            .map((final GpullInfo_participants_nodes? e) => e!)
            .toList(),
        totalCount: data.participants.totalCount,
      ),
      dynamicTabs: <DynamicTab>[
        DynamicTab(
          identifier: 'files_changed',
          tabViewBuilder: (final BuildContext context) =>
              const PullChangedFilesList(),
        ),
        DynamicTab(
          identifier: 'commits',
          tabViewBuilder: (final BuildContext context) =>
              const PullsCommitsList(),
        ),
      ],
      uri: data.url,
      onRefresh: widget.onRefresh,
      linkedPullRequests: data.closingIssuesReferences,
      additionalDetailTiles: [
        // Commits
        DetailTile(
          title: 'Commits',
          actionType: DetailTileActionType.tab,
          onTap: () {
            _templateKey.currentState?.dynamicTabsController.openTab('commits');
          },
          child: DetailTileCount(
            data.commits.totalCount,
            'commit',
            'commits',
          ),
        ),
        // Files changed
        DetailTile(
          title: 'Files changed',
          actionType: DetailTileActionType.tab,
          onTap: () {
            _templateKey.currentState?.dynamicTabsController
                .openTab('files_changed');
          },
          child: DetailTileCount(
            data.changedFiles,
            'file',
            'files',
          ),
        ),
        // Merged date (if merged)
        if (data.merged)
          DetailTile(
            title: 'Merged',
            actionType: DetailTileActionType.none,
            child: DetailTileText(
              getDate(data.mergedAt.toString(), shorten: false),
              color: Colors.deepPurple,
            ),
          ),
      ],
      viewerCanUpdate: data.viewerCanUpdate ?? false,
      actionButtons: _buildActionButtons(context, data),
    );
  }

  List<Widget> _buildActionButtons(
    final BuildContext context,
    final GpullInfo data,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isOpen = data.state == GPullRequestState.OPEN;
    final isLocked = data.locked ?? false;

    return [
      // Close/Reopen button
      if (data.viewerCanUpdate ?? false)
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Implement close/reopen action
          },
          icon: Icon(
            isOpen ? Octicons.git_pull_request_closed : Octicons.issue_reopened,
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
}
