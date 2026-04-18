import 'package:diohub_models/models/app_config.dart';
import 'package:diohub/common/context_dock/context_dock.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/nav_center/models/sort_binding.dart';
import 'package:diohub/common/nav_center/models/tab_action.dart';
import 'package:diohub/common/nav_center/models/tab_body.dart';
import 'package:diohub/common/nav_center/models/tab_controls.dart';
import 'package:diohub/common/nav_center/shell/tab_body_page.dart';
import 'package:diohub/common/search_overlay/threads_filter_adapter.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/entity_snapshot_factories.dart';
import 'package:diohub_models/models/search/sort_spec.dart';
import 'package:diohub/providers/dock/inline_search_query_provider.dart';
import 'package:diohub/providers/issue_pulls/pull_files_providers.dart';
import 'package:diohub/routes/entity_ref_routes.dart';
import 'package:diohub/providers/issue_pulls/issue_providers.dart';
import 'package:diohub/view/issues_pulls/participants/participants_position.dart';
import 'package:diohub/view/issues_pulls/pull_request/files_changed/files_changed_position.dart'
    show buildFilesChangedSlivers;
import 'package:diohub/view/issues_pulls/widgets/config/pull_settings_and_actions.dart';
import 'package:diohub/view/issues_pulls/widgets/config/shared_tab_builders.dart';
import 'package:diohub/view/issues_pulls/widgets/discussion_content_slivers.dart';
import 'package:diohub/view/issues_pulls/widgets/discussion_detail_payload.dart';
import 'package:diohub/view/issues_pulls/widgets/pull_commits_view.dart';
import 'package:diohub/view/issues_pulls/widgets/pull_threads_view.dart'
    show buildPullThreadsSlivers;
import 'package:diohub/view/issues_pulls/widgets/pr_insights_slivers.dart'
    show buildPRInsightsSlivers;
import 'package:diohub/view/common/entity_logs_position.dart';
import 'package:diohub_models/models/database_types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';

List<TabConfig> buildTabs(
  BuildContext context,
  WidgetRef ref,
  PullRequestRef pullRef,
  PullInfo data, {
  List<Widget> Function(BuildContext)? checksSliverBuilder,
  List<Widget> Function(BuildContext)? linkedIssuesSliverBuilder,
  DateTime? commentsSince,
  String? scrollToCommentId,
}) {
  final List<TabConfig> tabs = <TabConfig>[];

  final int commentsCount = data.comments.totalCount;
  final PullRepository repo = data.repository;
  final DiscussionDetailPayload discussionPayload = DiscussionDetailPayload(
    title: data.titleHTMLAsString,
    bodyHTML: data.bodyHTML,
    reactionGroups: data.reactionGroups!.toList(),
    viewerCanReact: data.viewerCanReact,
    repo: RepoRef(owner: repo.owner.login, name: repo.name),
    number: data.number,
    isPull: true,
    nodeID: data.id,
    isLocked: data.locked,
    commentsSince: commentsSince,
    createdAt: data.createdAt,
    scrollToCommentId: scrollToCommentId,
  );
  tabs.add(
    buildDiscussionTab(
      label: 'Discussion',
      sliverBuilder: (_, ref) => [
        DiscussionContentSlivers(payload: discussionPayload),
      ],
      refreshFuture: () => ref.refresh(pullDetailProvider(pullRef).future),
      composeBar: (data.locked && !data.viewerCanUpdate)
          ? null
          : ComposeBarConfig(
              entityType: 'pull',
              entityId: data.id,
              positionKey: 'discussion',
              placeholder: 'Write a comment…',
              draftSubject: pullRef,
              draftScope: DraftScope.comment,
              onSubmit: (text) async {
                await ref
                    .read(pullDetailProvider(pullRef).notifier)
                    .addComment(text);
              },
              onExpand: (_) async {
                if (!context.mounted) return;
                await pullRef.navigateToComment(context);
              },
            ),
      dockActions: (ctx, ref) => [
        if (!data.locked || data.viewerCanUpdate)
          CommentDockPill(
            entityType: 'pull',
            entityId: data.id,
            submitComment: (r, text) async {
              await r
                  .read(pullDetailProvider(pullRef).notifier)
                  .addComment(text);
            },
          ),
      ],
      commentsCount: commentsCount,
      ambientIndicator: data.reviewDecision != null
          ? ReviewDecisionAmbient(data.reviewDecision!)
          : null,
    ),
  );

  final int participantsCount = data.participants.totalCount;
  final PullParticipantsPosition pullParticipants = PullParticipantsPosition(
    pullRef: pullRef,
    data: data,
  );
  final nodes = data.participants.nodes;
  final participantAvatarUrls = nodes != null
      ? (nodes as List<dynamic>)
            .whereType<PullParticipantNode>()
            .map((n) => n.avatarUrl.toString())
            .take(5)
            .toList()
      : <String>[];
  tabs.add(
    buildParticipantsTab(
      participantsQueryKey:
          'pull/${pullRef.repo.fullName}/${pullRef.number}/participants',
      refreshFuture: () => ref.refresh(pullDetailProvider(pullRef).future),
      buildSlivers: (ctx, ref) => pullParticipants.buildSlivers(ctx, ref),
      participantsCount: participantsCount,
      participantAvatarUrls: participantAvatarUrls,
      widgetRef: ref,
    ),
  );

  tabs.add(
    TabConfig(
      label: 'Insights',
      icon: Octicons.graph,
      category: TabCategory.content,
      body: TabBodyPage(
        body: SliverBuilderBody(
          sliverBuilder: (ctx, ref) =>
              buildPRInsightsSlivers(ctx, ref, pullRef, data),
          refreshFuture: () => ref.refresh(pullDetailProvider(pullRef).future),
        ),
      ),
      inlineControls: (ctx, ref) => [],
      dockActions: (ctx, ref) => [],
    ),
  );

  tabs.add(
    TabConfig(
      label: 'Files Changed',
      icon: Octicons.diff,
      category: TabCategory.content,
      keepAlive: true,
      body: TabBodyPage(
        body: SliverBuilderBody(
          sliverBuilder: (ctx, ref) =>
              buildFilesChangedSlivers(ctx, ref, pullRef),
        ),
      ),
      controls: TabControls.clientList(
        searchQuery: ref.read(
          inlineSearchQueryNotifierProvider(
            'pull/${pullRef.repo.owner}/${pullRef.repo.name}/${pullRef.number}/files',
          ),
        ),
        sort: SortBinding.typed<FilesChangedSortOrder>(
          spec: SortSpec(
            options: FilesChangedSortOrder.values,
            defaultValue: FilesChangedSortOrder.byPath,
            labelOf: (o) => switch (o) {
              FilesChangedSortOrder.byPath => 'Path',
              FilesChangedSortOrder.byChangeType => 'Change type',
              FilesChangedSortOrder.byDelta => 'Δ',
            },
          ),
          getValue: (r) => r.watch(pullFilesSortOrderProvider(pullRef)),
          onSelected: (r, order) {
            r.read(pullFilesSortOrderProvider(pullRef).notifier).state = order;
          },
        ),
      ),
      actions: [
        TabAction.custom(
          pill: BasicDockPill(
            iconData: Icons.download_rounded,
            label: 'Download .diff',
            onTapAction: (_) => launchUrl(Uri.parse('${data.url}.diff')),
          ),
        ),
      ],
      trailing: data.changedFiles > 0
          ? CountTrailing(() => data.changedFiles)
          : null,
      ambientIndicator: DiffStatAmbient(
        additions: data.additions,
        deletions: data.deletions,
        changedFiles: data.changedFiles,
      ),
    ),
  );

  tabs.add(
    TabConfig(
      label: 'Threads',
      icon: Octicons.comment_discussion,
      category: TabCategory.content,
      keepAlive: true,
      body: TabBodyPage(
        body: SliverBuilderBody(
          sliverBuilder: (ctx, ref) => buildPullThreadsSlivers(
            ctx,
            ref,
            pullRef,
            onThreadTap: ref
                .read(premiumTabsProvider)
                .reviewThreadScreenBuilder(ctx, ref),
          ),
          refreshFuture: () => ref.refresh(pullDetailProvider(pullRef).future),
        ),
      ),
      controls: TabControls.filterable(
        sections: ThreadsFilterAdapter(ref, pullRef).sections,
        stateNotifier: ThreadsFilterAdapter(ref, pullRef),
        activeFilterCount: () => ThreadsFilterAdapter(ref, pullRef).activeCount,
        adapter: ThreadsFilterAdapter(ref, pullRef),
        searchQuery: ref.read(
          inlineSearchQueryNotifierProvider(
            'pull/${pullRef.repo.owner}/${pullRef.repo.name}/${pullRef.number}/threads',
          ),
        ),
      ),
    ),
  );

  tabs.add(
    TabConfig(
      label: 'Commits',
      icon: Octicons.git_commit,
      category: TabCategory.content,
      keepAlive: true,
      body: TabBodyPage(body: createPullCommitsBody(pullRef)),
      trailing: data.commits.totalCount > 0
          ? CountTrailing(() => data.commits.totalCount)
          : null,
      ambientIndicator: data.headRef != null
          ? BranchAmbient(data.headRef!.name)
          : null,
      inlineControls: (ctx, ref) => [],
      dockActions: (ctx, ref) => [],
    ),
  );

  final refs = data.closingIssuesReferences;
  if (refs != null &&
      refs.totalCount > 0 &&
      linkedIssuesSliverBuilder != null) {
    tabs.add(
      TabConfig(
        label: 'Linked Issues',
        icon: Octicons.issue_opened,
        category: TabCategory.content,
        keepAlive: true,
        body: TabBodyPage(
          body: SliverBuilderBody(
            sliverBuilder: (ctx, ref) => linkedIssuesSliverBuilder!(ctx),
            refreshFuture: () =>
                ref.refresh(pullDetailProvider(pullRef).future),
          ),
        ),
        trailing: CountTrailing(() => refs.totalCount),
        inlineControls: (ctx, ref) => [],
        dockActions: (ctx, ref) => [],
      ),
    );
  }

  tabs.add(
    buildEntityLogsPosition(
      entityPath: pullRef.apiPath,
      emptyMessage: 'No logs for this PR',
    ),
  );

  tabs.add(
    TabConfig(
      label: 'Settings',
      icon: Octicons.gear,
      category: TabCategory.settings,
      keepAlive: false,
      visible: data.viewerCanUpdate || data.viewerCanSubscribe,
      body: TabBodyPage(
        body: SettingsBody(
          sections: pullSettingsSections(context, ref, pullRef, data),
        ),
      ),
      inlineControls: (ctx, ref) => [],
      dockActions: (ctx, ref) => [],
    ),
  );

  // Premium tabs injection
  final premiumDefs = ref
      .read(premiumTabsProvider)
      .pullRequestTabs(context, ref, pullRef: pullRef, data: data);
  for (final def in premiumDefs) {
    tabs.add(
      TabConfig(
        label: def.label,
        icon: def.icon,
        body: def.body,
        deeplinkPath: def.deeplinkPath,
        keepAlive: def.keepAlive,
      ),
    );
  }

  return tabs;
}

extension PullInfoTabs on PullInfo {
  List<TabConfig> tabs(
    BuildContext context,
    WidgetRef ref, {
    List<Widget> Function(BuildContext)? checksSliverBuilder,
    List<Widget> Function(BuildContext)? linkedIssuesSliverBuilder,
    DateTime? commentsSince,
    String? scrollToCommentId,
  }) => buildTabs(
    context,
    ref,
    toRef,
    this,
    checksSliverBuilder: checksSliverBuilder,
    linkedIssuesSliverBuilder: linkedIssuesSliverBuilder,
    commentsSince: commentsSince,
    scrollToCommentId: scrollToCommentId,
  );
}
