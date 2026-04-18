import 'dart:convert';

import 'package:diohub/common/cards/issue_pull_card.dart';
import 'package:diohub/common/cards/issue_pull_card_data.dart';
import 'package:diohub/common/context_dock/context_dock.dart';
import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/nav_center/models/tab_body.dart';
import 'package:diohub/common/nav_center/settings/nav_center_settings.dart';
import 'package:diohub/common/nav_center/shell/tab_body_page.dart';
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';

import 'package:diohub_models/models/database_types.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/database_providers.dart'
    show apiClientProvider;
import 'package:diohub_models/models/entity_snapshot_factories.dart';
import 'package:diohub/providers/dock/inline_search_query_provider.dart';
import 'package:diohub/providers/entity_store_providers.dart';
import 'package:diohub/providers/issue_pulls/issue_providers.dart';
import 'package:diohub/routes/entity_ref_routes.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/view/common/entity_logs_position.dart';
import 'package:diohub/view/issues_pulls/participants/participants_position.dart';
import 'package:diohub/view/issues_pulls/widgets/config/issue_settings_and_actions.dart';
import 'package:diohub/view/issues_pulls/widgets/config/shared_tab_builders.dart';
import 'package:diohub/view/issues_pulls/widgets/discussion_content_slivers.dart';
import 'package:diohub/view/issues_pulls/widgets/discussion_detail_payload.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

List<TabConfig> buildTabs(
  BuildContext context,
  WidgetRef ref,
  IssueRef issueRef,
  IssueInfo data, {
  List<Widget> Function(BuildContext)? linkedPRsSliverBuilder,
  DateTime? commentsSince,
  String? scrollToCommentId,
}) {
  final List<TabConfig> tabs = <TabConfig>[];

  final int commentsCount = data.comments.totalCount;
  final IssueRepository repo = data.repository;

  // Calculate sub-issues tab index (will be 2 if present: Content, Participants, Sub-Issues)
  final int? subIssuesTabIndex = data.subIssues.totalCount > 0 ? 2 : null;

  final DiscussionDetailPayload contentPayload = DiscussionDetailPayload(
    title: data.titleHTML,
    bodyHTML: data.bodyHTML,
    reactionGroups: data.reactionGroups!.toList(),
    viewerCanReact: data.viewerCanReact,
    repo: RepoRef(owner: repo.owner.login, name: repo.name),
    number: data.number,
    isPull: false,
    nodeID: data.id,
    isLocked: data.locked,
    commentsSince: commentsSince,
    createdAt: data.createdAt,
    scrollToCommentId: scrollToCommentId,
    subIssuesSummary: data.subIssuesSummary.total > 0
        ? (
            completed: data.subIssuesSummary.completed,
            total: data.subIssuesSummary.total,
            percentCompleted: data.subIssuesSummary.percentCompleted,
          )
        : null,
    subIssuesTabIndex: subIssuesTabIndex,
  );
  tabs.add(
    buildDiscussionTab(
      label: 'Content',
      sliverBuilder: (_, ref) => [
        DiscussionContentSlivers(payload: contentPayload),
      ],
      refreshFuture: () => ref.refresh(issueDetailProvider(issueRef).future),
      composeBar: (data.locked && !data.viewerCanUpdate)
          ? null
          : ComposeBarConfig(
              entityType: 'issue',
              entityId: data.id,
              positionKey: 'content',
              placeholder: 'Write a comment…',
              draftSubject: issueRef,
              draftScope: DraftScope.comment,
              onSubmit: (text) async {
                await ref
                    .read(issueDetailProvider(issueRef).notifier)
                    .addComment(text);
              },
              onExpand: (currentDraft) async {
                if (!context.mounted) return;
                await issueRef.navigateToComment(context);
              },
            ),
      dockActions: (ctx, ref) => [
        if (!data.locked || data.viewerCanUpdate)
          CommentDockPill(
            entityType: 'issue',
            entityId: data.id,
            submitComment: (r, text) async {
              await r
                  .read(issueDetailProvider(issueRef).notifier)
                  .addComment(text);
            },
          ),
      ],
      commentsCount: commentsCount,
      ambientIndicator: data.subIssuesSummary.total > 0
          ? ProgressAmbient(
              completed: data.subIssuesSummary.completed,
              total: data.subIssuesSummary.total,
            )
          : null,
    ),
  );

  final int participantsCount = data.participants.totalCount;
  final IssueParticipantsPosition issueParticipants = IssueParticipantsPosition(
    issueRef: issueRef,
    data: data,
  );
  final nodes = data.participants.nodes;
  final participantAvatarUrls = nodes != null
      ? (nodes as List<dynamic>)
            .whereType<IssueParticipantNode>()
            .map((n) => n?.avatarUrl.toString() ?? '')
            .take(5)
            .toList()
      : <String>[];
  tabs.add(
    buildParticipantsTab(
      participantsQueryKey:
          'issue/${issueRef.repo.fullName}/${issueRef.number}/participants',
      refreshFuture: () => ref.refresh(issueDetailProvider(issueRef).future),
      buildSlivers: (ctx, ref) => issueParticipants.buildSlivers(ctx, ref),
      participantsCount: participantsCount,
      participantAvatarUrls: participantAvatarUrls,
      widgetRef: ref,
    ),
  );

  if (data.subIssues.totalCount > 0) {
    tabs.add(
      TabConfig(
        label: 'Sub-Issues',
        icon: Octicons.tasklist,
        category: TabCategory.content,
        keepAlive: true,
        body: TabBodyPage(
          body: SliverListBody<SubIssueNode>(
            getCursor: (node) => node?.id,
            pageSize: 20,
            fetcher:
                ({String? after, int first = 20, bool refresh = false}) async {
                  return issueRef
                      .services(ref.read(apiClientProvider))
                      .fetchSubIssues(
                        first: first,
                        after: after,
                        refresh: refresh,
                      );
                },
            itemBuilder: (BuildContext context, SubIssueNode node) {
              final RepoRef subRepoRef = RepoRef(
                owner: node.repository.owner.login,
                name: node.repository.name,
              );
              final IssueRef subIssueRef = IssueRef(
                repo: subRepoRef,
                number: node.number,
              );
              final IssueCardData cardData = IssueCardData.fromGitHubGql(node);
              final Widget card = Padding(
                padding: EdgeInsets.only(bottom: context.spacing.itemSpacing),
                child: TapFeedback(
                  onTap: () => subIssueRef.navigate(context, ref),
                  child: IssueCard(cardData),
                ),
              );
              return card;
            },
          ),
        ),
        trailing: CountTrailing(() => data.subIssues.totalCount),
        ambientIndicator: data.subIssuesSummary.total > 0
            ? ProgressAmbient(
                completed: data.subIssuesSummary.completed,
                total: data.subIssuesSummary.total,
              )
            : null,
        inlineControls: (ctx, ref) => [],
        dockActions: (ctx, ref) => [],
      ),
    );
  }

  final refs = data.closedByPullRequestsReferences;
  if (refs != null && refs.totalCount > 0 && linkedPRsSliverBuilder != null) {
    tabs.add(
      TabConfig(
        label: 'Linked PRs',
        icon: Octicons.git_pull_request,
        category: TabCategory.content,
        keepAlive: true,
        body: TabBodyPage(
          body: SliverBuilderBody(
            sliverBuilder: (ctx, ref) => linkedPRsSliverBuilder(ctx),
            refreshFuture: () =>
                ref.refresh(issueDetailProvider(issueRef).future),
          ),
        ),
        trailing: CountTrailing(() => refs.totalCount),
        inlineControls: (ctx, ref) => [],
        dockActions: (ctx, ref) => [],
      ),
    );
  }

  // History: visits for this issue
  tabs.add(
    TabConfig(
      label: 'History',
      icon: Octicons.history,
      category: TabCategory.other,
      keepAlive: false,
      body: TabBodyPage(
        body: SliverBuilderBody(
          sliverBuilder: (ctx, r) {
            final entries =
                r
                    .watch(storeByEntityPathProvider(issueRef.apiPath))
                    .asData
                    ?.value ??
                [];
            final spacing = ctx.spacing;
            return [
              SliverPadding(
                padding: spacing.listInset,
                sliver: SliverList.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final item = entries[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: spacing.itemSpacing),
                      child: ListTile(
                        title: Text(
                          item.entity.snapshotTitle ?? item.visit.nodeId,
                        ),
                        subtitle: Text(item.visit.visitedAt.toRelativeDate()),
                        onTap: () => EntityRef.fromJson(
                          jsonDecode(item.entity.subjectJson)
                              as Map<String, dynamic>,
                        ).navigate(ctx, ref),
                      ),
                    );
                  },
                ),
              ),
            ];
          },
        ),
      ),
    ),
  );

  tabs.add(
    buildEntityLogsPosition(
      entityPath: issueRef.apiPath,
      emptyMessage: 'No logs for this issue',
    ),
  );

  tabs.add(
    TabConfig(
      label: 'Settings',
      icon: Octicons.gear,
      category: TabCategory.settings,
      keepAlive: false,
      visible:
          data.viewerCanUpdate ||
          data.viewerCanDelete == true ||
          data.viewerCanSubscribe,
      body: TabBodyPage(
        body: SettingsBody(
          sections: issueSettingsSections(context, ref, issueRef, data),
        ),
      ),
    ),
  );

  return tabs;
}

extension IssueInfoTabs on IssueInfo {
  List<TabConfig> tabs(
    BuildContext context,
    WidgetRef ref, {
    List<Widget> Function(BuildContext)? linkedPRsSliverBuilder,
    DateTime? commentsSince,
    String? scrollToCommentId,
  }) => buildTabs(
    context,
    ref,
    toRef,
    this,
    linkedPRsSliverBuilder: linkedPRsSliverBuilder,
    commentsSince: commentsSince,
    scrollToCommentId: scrollToCommentId,
  );
}
