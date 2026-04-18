import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub/common/clipboard/clipboard_service.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/file_tree_view.dart';
import 'package:diohub/common/misc/async_error_widgets.dart';
import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub/common/widgets/log_entry_card.dart';
import 'package:diohub/providers/logging/log_providers.dart';
import 'package:diohub/view/common/entity_logs_position.dart';
import 'package:diohub/view/logs/log_detail_sheet.dart';
import 'package:diohub/common/context_dock/context_dock.dart';
import 'package:diohub/common/context_dock/models/dock_pill.dart';
import 'package:diohub/common/nav_center/dock/bookmark_dock_pill.dart';
import 'package:diohub/common/markdown_view/trimmable_markdown_content.dart';
import 'package:diohub/common/nav_center/models/entity_config.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/nav_center/shell/tab_body_page.dart';
import 'package:diohub/common/pagination/paginated_sliver_list.dart';
import 'package:diohub/common/popup/popup_section_assemblers.dart';
import 'package:diohub/common/utils/github_visual_styles.dart';
import 'package:diohub/common/cards/metadata_chips.dart';
import 'package:diohub/common/widgets/metadata_composites.dart';
import 'package:diohub/common/widgets/metadata_rows.dart';
import 'package:diohub/common/widgets/metadata_section_sliver.dart';
import 'package:diohub/common/widgets/status_flag_row.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/commits/commit_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/navigable.dart';
import 'package:diohub/providers/database_providers.dart'
    show apiClientProvider;
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub_models/models/repositories/commit_comment_item.dart';
import 'package:diohub/providers/commits/commit_providers.dart';
import 'package:diohub/providers/dock/inline_search_query_provider.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/providers/repository/commit_comments_refresh_trigger_provider.dart';
import 'package:diohub/providers/repository/create_commit_comment_mutation_provider.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/diff_colors.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub_models/models/database_types.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/repository/commits/widgets/changed_files.dart';
import 'package:diohub/common/widgets/diff_insights_section.dart';
import 'package:diohub/common/widgets/section_header.dart';
import 'package:diohub/utils/diff_analysis.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pure config builder for the Commit detail screen.
///
/// Returns a [ScreenConfig] with 2 positions (About, Files), entity header
/// with commit headline and verification status, and full commit metadata.
ScreenConfig buildCommitScreenConfig({
  required CommitRef commitRef,
  required CommitData commitData,
  required Future<void> Function() onRefresh,
  required WidgetRef ref,
  required ClipboardService clipboard,
  required BuildContext context,
}) {
  final CommitInfo commit = commitData.info;
  final List<FileElement>? files = commitData.files;
  final int fileCount = files?.length ?? commit.changedFilesIfAvailable ?? 0;

  final List<TabConfig> positions = <TabConfig>[
    TabConfig(
      deeplinkPath: 'about',
      label: 'About',
      icon: Octicons.info,
      category: TabCategory.primary,
      body: TabBodyPage(
        body: SliverBuilderBody(
          sliverBuilder: (BuildContext ctx, WidgetRef ref) =>
              _buildAboutSlivers(ctx, commitData),
          refreshFuture: () =>
              ref.refresh(commitDataProvider(commitRef).future),
        ),
      ),
      inlineControls: (ctx, ref) => [],
      dockActions: (ctx, ref) => [
        BasicDockPill(
          iconData: Octicons.file_code,
          label: 'Browse files',
          onTapAction: (_) => commitRef.repo.navigate(ctx, ref),
        ),
        BasicDockPill(
          iconData: Icons.open_in_new_rounded,
          label: 'Open in browser',
          onTapAction: (_) => launchUrl(Uri.parse(commit.url.toString())),
        ),
      ],
      ambientIndicator: commit.statusCheckRollup != null
          ? CIStatusAmbient(commit.statusCheckRollup!.state)
          : null,
    ),
    TabConfig(
      deeplinkPath: 'files',
      label: 'Files',
      icon: Octicons.file_diff,
      category: TabCategory.primary,
      body: TabBodyPage(
        body: SliverBuilderBody(
          sliverBuilder: (BuildContext ctx, WidgetRef ref) =>
              buildChangedFilesSlivers(ctx, commit, files),
          refreshFuture: () =>
              ref.refresh(commitDataProvider(commitRef).future),
        ),
      ),
      trailing: fileCount > 0 ? CountTrailing(() => fileCount) : null,
      ambientIndicator: DiffStatAmbient(
        additions: commit.additions,
        deletions: commit.deletions,
        changedFiles: fileCount > 0 ? fileCount : null,
      ),
      dockActions: (ctx, ref) => [
        InlineSearchDockPill(
          queryNotifier: ref.read(
            inlineSearchQueryNotifierProvider(
              'commit/${commitRef.repo.owner}/${commitRef.repo.name}/${commitRef.oid}/files',
            ),
          ),
        ),
        BasicDockPill(
          iconData: Icons.download_rounded,
          label: 'Download .patch',
          onTapAction: (_) => launchUrl(Uri.parse('${commit.url}.patch')),
        ),
      ],
    ),
    TabConfig(
      deeplinkPath: 'insights',
      label: 'Insights',
      icon: Octicons.graph,
      category: TabCategory.content,
      body: TabBodyPage(
        body: SliverBuilderBody(
          sliverBuilder: (BuildContext ctx, WidgetRef ref) =>
              _buildInsightsSlivers(ctx, ref, commitData, commit, commitRef),
          refreshFuture: () =>
              ref.refresh(commitDataProvider(commitRef).future),
        ),
      ),
      inlineControls: (ctx, ref) => <DockPill>[],
      dockActions: (ctx, ref) => <DockPill>[],
    ),
    // Code: browse file tree at this commit (opens repo; app may support ref in code tab later)
    TabConfig(
      deeplinkPath: 'code',
      label: 'Code',
      icon: Octicons.file_code,
      category: TabCategory.content,
      body: TabBodyPage(
        body: SliverBuilderBody(
          sliverBuilder: (BuildContext ctx, WidgetRef ref) => [
            SliverPadding(
              padding: ctx.spacing.listInset,
              sliver: SliverToBoxAdapter(
                child: ListTile(
                  title: const Text('Browse file tree at this commit'),
                  subtitle: Text(
                    '${commitRef.repo.owner}/${commitRef.repo.name} @ ${commitRef.oid.length >= 7 ? commitRef.oid.substring(0, 7) : commitRef.oid}',
                  ),
                  leading: const Icon(Octicons.file_code),
                  onTap: () => commitRef.repo.navigate(ctx, ref),
                ),
              ),
            ),
          ],
          refreshFuture: () =>
              ref.refresh(commitDataProvider(commitRef).future),
        ),
      ),
      inlineControls: (ctx, ref) => [],
      dockActions: (ctx, ref) => [],
    ),
    TabConfig(
      deeplinkPath: 'comments',
      label: 'Comments',
      icon: Octicons.comment,
      category: TabCategory.content,
      keepAlive: true,
      body: TabBodyPage(
        body: SliverBuilderBody(
          sliverBuilder: (BuildContext ctx, WidgetRef ref) {
            final spacing = ctx.spacing;
            return <Widget>[
              SliverPadding(
                padding: spacing.listInset,
                sliver: SliverToBoxAdapter(
                  child: _CommitCommentComposeRow(commitRef: commitRef),
                ),
              ),
              SliverPadding(
                padding: spacing.listInset,
                sliver: _CommitCommentsListSliver(
                  key: ValueKey(commitRef.oid),
                  commitRef: commitRef,
                  buildTile: (BuildContext context, CommitCommentItem item) =>
                      _buildCommitCommentTile(context, ref, item),
                  spacing: spacing,
                ),
              ),
            ];
          },
          composeBar: ComposeBarConfig(
            entityType: 'commit',
            entityId: commitRef.oid,
            positionKey: 'comments',
            placeholder: 'Add a comment…',
            draftSubject: commitRef,
            draftScope: DraftScope.comment,
            onSubmit: (String text) async {
              await ref
                  .read(createCommitCommentMutationProvider(commitRef).notifier)
                  .create(body: text);
            },
          ),
          refreshFuture: () =>
              ref.refresh(commitDataProvider(commitRef).future),
        ),
      ),
      trailing: commit.comments.totalCount > 0
          ? CountTrailing(() => commit.comments.totalCount)
          : null,
      inlineControls: (ctx, ref) => [],
      dockActions: (ctx, ref) => [],
    ),
    buildEntityLogsPosition(
      entityPath: commitRef.apiPath,
      emptyMessage: 'No logs for this commit',
    ),
  ];

  final List<StatusFlag> commitFlags = _commitStatusFlags(commit);
  final EntityConfig entity = EntityConfig(
    leading: null,
    title: Text(commit.messageHeadline),
    statusIndicators: StatusFlagRow(flags: commitFlags),
    metadataSections: _buildCommitMetadataSections(context, commit, files, ref),
    actionSections: buildCommitPopupSections(
      commit.url,
      commit.oid,
      clipboard,
      context: context,
      ref: ref,
      repoRef: commitRef.repo,
      parentOid: commit.parents.edges?.isNotEmpty == true
          ? commit.parents.edges!.first?.node?.oid
          : null,
    ),
  );

  return ScreenConfig(
    entity: entity,
    tabs: positions,
    initialTabPath: 'about',
    onRefresh: onRefresh,
    expandedZoneContent: <ExpandedZoneDetail>[
      if (commit.messageHeadline.isNotEmpty)
        ExpandedZoneText(commit.messageHeadline),
      if (commitFlags.isNotEmpty) FlagSummary(commitFlags),
    ],
    screenInlineControls: (ctx, r) => [
      bookmarkDockPill(
        ref: r,
        entityRef: commitRef,
        snapshot: null,
        contextRepo: commitRef.repo,
      ),
    ],
  );
}

List<StatusFlag> _commitStatusFlags(CommitInfo commit) => <StatusFlag>[
  if (commit.signature != null && commit.signature!.isValid)
    StatusFlag.verified,
  if (commit.signature != null && !commit.signature!.isValid)
    StatusFlag.unverified,
];

List<MetadataSectionData> _buildCommitMetadataSections(
  BuildContext context,
  CommitInfo commit,
  List<FileElement>? files,
  WidgetRef ref,
) {
  final List<Widget> detailsChildren = <Widget>[];
  final AppSpacing spacing = context.spacing;
  final int fileCount = files?.length ?? commit.changedFilesIfAvailable ?? 0;

  detailsChildren.add(
    MetadataGroupCard(
      title: 'Changes',
      children: <Widget>[
        DiffDistribution(
          additions: commit.additions,
          deletions: commit.deletions,
          changedFiles: fileCount > 0 ? fileCount : null,
        ),
      ],
    ),
  );
  detailsChildren.add(spacing.sectionGap);

  final String? signerText = commit.signature?.signer != null
      ? '${commit.signature!.signer!.name ?? ''}${commit.signature!.signer!.email.isNotEmpty ? ' <${commit.signature!.signer!.email}>' : ''}'
      : null;
  final bool hasVerification =
      commit.signature != null || commit.statusCheckRollup != null;
  if (hasVerification) {
    detailsChildren.add(
      MetadataGroupCard(
        title: 'Verification',
        children: <Widget>[
          Wrap(
            spacing: spacing.tightSpacing,
            runSpacing: spacing.compactSpacing,
            children: <Widget>[
              VerificationStatusCard(
                isVerified: commit.signature?.isValid ?? false,
                signer: signerText,
                ciState: commit.statusCheckRollup?.state,
                contained: false,
              ),
              if (commit.signature?.wasSignedByGitHub == true)
                StatusBadge(
                  label: 'GitHub Web',
                  color: context.colorScheme.primary,
                  icon: Octicons.globe,
                ),
            ],
          ),
        ],
      ),
    );
    detailsChildren.add(spacing.sectionGap);
  }

  final List<Widget> authorshipRows = <Widget>[];
  if (commit.author != null) {
    authorshipRows.add(
      MetadataUserRow(
        label: 'Author',
        avatarUrl: commit.author!.avatarUrl.toString(),
        login: commit.author?.user?.login ?? commit.author?.name ?? 'Unknown',
        onTap: commit.author?.user != null
            ? () => UserRef(
                login: commit.author!.user!.login,
              ).navigate(context, ref)
            : null,
      ),
    );
    if (commit.author!.email != null &&
        commit.author!.email!.trim().isNotEmpty) {
      authorshipRows.add(
        MetadataContactRow(
          icon: Icons.email_outlined,
          value: commit.author!.email!,
          onTap: () => launchUrl(Uri.parse('mailto:${commit.author!.email}')),
        ),
      );
    }
  }
  if (commit.committer != null && !commit.authoredByCommitter) {
    authorshipRows.add(
      Consumer(
        builder:
            (
              final BuildContext context,
              final WidgetRef ref,
              final Widget? child,
            ) => MetadataUserRow(
              label: 'Committer',
              avatarUrl: commit.committer!.avatarUrl.toString(),
              login:
                  commit.committer?.user?.login ??
                  commit.committer?.name ??
                  'Unknown',
              onTap: commit.committer?.user != null
                  ? () => UserRef(
                      login: commit.committer!.user!.login,
                    ).navigate(context, ref)
                  : null,
            ),
      ),
    );
    final String authorEmail = commit.author?.email?.trim() ?? '';
    if (commit.committer!.email != null &&
        commit.committer!.email!.trim().isNotEmpty &&
        commit.committer!.email!.trim() != authorEmail) {
      authorshipRows.add(
        MetadataContactRow(
          icon: Icons.email_outlined,
          value: commit.committer!.email!,
          onTap: () =>
              launchUrl(Uri.parse('mailto:${commit.committer!.email}')),
        ),
      );
    }
  }
  final List<TimestampEntry> tsEntries = <TimestampEntry>[
    if (commit.author?.date != null &&
        commit.author!.date != commit.committedDate)
      TimestampEntry(label: 'Authored', date: commit.author!.date!),
    TimestampEntry(label: 'Committed', date: commit.committedDate),
  ];
  authorshipRows.add(MetadataTimestampRow(timestamps: tsEntries));
  detailsChildren.add(
    MetadataGroupCard(
      title: 'Authorship',
      children: <Widget>[
        Column(mainAxisSize: MainAxisSize.min, children: authorshipRows),
      ],
    ),
  );
  detailsChildren.add(spacing.sectionGap);

  final List<Widget> referenceRows = <Widget>[
    Consumer(
      builder:
          (
            final BuildContext context,
            final WidgetRef ref,
            final Widget? child,
          ) => MetadataRow(
            icon: Octicons.file_directory,
            label: 'Tree',
            onTap: () {
              RepoRef.fromFullName(
                commit.repository.nameWithOwner,
              ).navigate(context, ref);
            },
            child: Text(
              commit.tree.abbreviatedOid,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
    ),
    Consumer(
      builder:
          (
            final BuildContext context,
            final WidgetRef ref,
            final Widget? child,
          ) => MetadataRow(
            icon: Octicons.repo,
            label: 'Repository',
            onTap: () {
              RepoRef.fromFullName(
                commit.repository.nameWithOwner,
              ).navigate(context, ref);
            },
            child: Text(commit.repository.nameWithOwner),
          ),
    ),
    Consumer(
      builder:
          (
            final BuildContext context,
            final WidgetRef ref,
            final Widget? child,
          ) => MetadataRow(
            icon: Octicons.repo,
            label: 'Repository',
            onTap: () {
              RepoRef.fromFullName(
                commit.repository.nameWithOwner,
              ).navigate(context, ref);
            },
            child: Text(commit.repository.nameWithOwner),
          ),
    ),
  ];
  if (commit.parents.edges != null && commit.parents.edges!.isNotEmpty) {
    final List<MetadataChipData> parentChips = commit.parents.edges!
        .where((CommitParentEdge? edge) => edge?.node != null)
        .map((CommitParentEdge? edge) {
          final CommitParentNode parent = edge!.node!;
          return MetadataChipData(
            label: parent.abbreviatedOid,
            onTap: () => CommitRef(
              repo: RepoRef.fromFullName(commit.repository.nameWithOwner),
              oid: parent.oid,
            ).navigate(context, ref),
          );
        })
        .toList();
    referenceRows.add(MetadataChipWrap(chips: parentChips));
  }
  detailsChildren.add(
    MetadataGroupCard(
      title: 'References',
      children: <Widget>[
        Column(mainAxisSize: MainAxisSize.min, children: referenceRows),
      ],
    ),
  );

  return <MetadataSectionData>[
    MetadataSectionData(
      title: 'Details',
      icon: Icons.info_outline_rounded,
      variant: MetadataSectionVariant.strong,
      children: detailsChildren,
    ),
  ];
}

/// Slivers for the commit About tab for use inside the shell's scroll view.
List<Widget> _buildAboutSlivers(BuildContext context, CommitData commitData) {
  final CommitInfo commit = commitData.info;

  return <Widget>[
    SliverToBoxAdapter(
      child: Padding(
        padding: context.spacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              commit.messageHeadline,
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
            context.spacing.sectionGap,
            _buildTotalChangesStats(context, commit, commitData.files),
            context.spacing.sectionGap,
            if (commit.associatedPullRequests?.edges?.isNotEmpty ??
                false) ...<Widget>[
              _buildAssociatedPRs(context, commit),
              context.spacing.sectionGap,
            ],
          ],
        ),
      ),
    ),
    if (commitData.files != null && commitData.files!.isNotEmpty)
      FileTreeView(
        files: commitData.files!,
        onFileTap: (FileElement file) async {
          if (file.patch != null) {
            await AutoRouter.of(context).push(
              ChangesViewer(
                patch: file.patch,
                contentURL: file.contentsUrl ?? '',
                fileType: file.filename.split('.').last,
              ),
            );
          }
        },
      ),
    SliverToBoxAdapter(
      child: Padding(
        padding: context.spacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            context.spacing.sectionGap,
            if (commit.messageBody.isNotEmpty)
              BorderedContainer(
                backgroundColor: context.colorScheme.surfaceContainerLow,
                elevation: 0,
                padding: context.spacing.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Full Message',
                      style: context.textTheme.labelMedium?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    context.spacing.itemGap,
                    Text(
                      commit.messageBody,
                      style: context.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  ];
}

List<Widget> _buildInsightsSlivers(
  BuildContext context,
  WidgetRef ref,
  CommitData commitData,
  CommitInfo commit,
  CommitRef commitRef,
) {
  final List<FileElement>? files = commitData.files;
  if (files == null || files.isEmpty) {
    return <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: context.spacing.listInset,
          child: Center(
            child: Padding(
              padding: context.spacing.pagePadding,
              child: Text(
                'No file data available',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    ];
  }

  final DiffAnalysisResult analysis = analyzeDiffs<FileElement>(
    files: files,
    getFilename: (f) => f.filename,
    getAdditions: (f) => f.additions,
    getDeletions: (f) => f.deletions,
  );

  final List<Widget> children = <Widget>[
    DiffInsightsSection(analysis: analysis),
  ];

  final authorsNodes = commit.authors.nodes;
  if (authorsNodes != null && authorsNodes.length > 1) {
    children.add(context.spacing.sectionGap);
    children.add(_CoAuthorsRow(authorNodes: authorsNodes));
  }

  final prEdges = commit.associatedPullRequests?.edges;
  if (prEdges != null && prEdges.isNotEmpty) {
    final prs = prEdges
        .where((CommitAssociatedPREdge? e) => e?.node != null)
        .map((CommitAssociatedPREdge? e) => e!.node!)
        .toList();
    if (prs.isNotEmpty) {
      children.add(context.spacing.sectionGap);
      children.add(
        _AssociatedPRsSection(prs: prs, commitRef: commitRef, ref: ref),
      );
    }
  }

  return <Widget>[
    SliverPadding(
      padding: context.spacing.listInset,
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    ),
  ];
}

class _CoAuthorsRow extends StatelessWidget {
  const _CoAuthorsRow({required this.authorNodes});
  final List<dynamic> authorNodes;

  @override
  Widget build(BuildContext context) {
    final label = authorNodes.length == 2 ? 'Pair programmed' : 'Mob commit';
    return SectionHeader(
      title: label,
      style: SectionHeaderStyle.small,
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: authorNodes
            .map<Widget>(
              (dynamic a) =>
                  UserAvatar(avatarUrl: a.avatarUrl.toString(), size: 28),
            )
            .toList(),
      ),
    );
  }
}

class _AssociatedPRsSection extends StatelessWidget {
  const _AssociatedPRsSection({
    required this.prs,
    required this.commitRef,
    required this.ref,
  });
  final List<CommitAssociatedPRNode> prs;
  final CommitRef commitRef;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return SectionHeader(
      title: 'Associated Pull Requests',
      style: SectionHeaderStyle.small,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: prs
            .map<Widget>(
              (CommitAssociatedPRNode pr) => BorderedContainer(
                child: ListTile(
                  leading: Icon(
                    Octicons.git_pull_request,
                    color: GitHubVisualStyles.fromGraphQLPullRequestState(
                      pr.state,
                      isDraft: pr.isDraft,
                    ).color,
                  ),
                  title: Text(pr.title ?? '#${pr.number}'),
                  subtitle: Text('#${pr.number} · ${pr.state.name}'),
                  dense: true,
                  onTap: () => PullRequestRef(
                    repo: commitRef.repo,
                    number: pr.number,
                  ).navigate(context, ref),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

Widget _buildTotalChangesStats(
  BuildContext context,
  CommitInfo commit,
  List<FileElement>? files,
) {
  final int totalAdditions = commit.additions;
  final int totalDeletions = commit.deletions;
  final int fileCount = files?.length ?? commit.changedFilesIfAvailable ?? 0;

  return BorderedContainer(
    backgroundColor: Color.lerp(
      context.colorScheme.surfaceContainer,
      Colors.black,
      0.1,
    ),
    elevation: 0,
    padding: context.spacing.pagePadding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              Octicons.diff,
              size: 16,
              color: context.colorScheme.onSurfaceVariant,
            ),
            context.spacing.itemGap,
            Text(
              'Changes',
              style: context.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        context.spacing.contentGap,
        Row(
          children: <Widget>[
            Expanded(
              child: _statItem(
                context,
                icon: Octicons.diff_added,
                label: 'Additions',
                value: totalAdditions.toString(),
                color: DiffColors.addition,
              ),
            ),
            Expanded(
              child: _statItem(
                context,
                icon: Octicons.diff_removed,
                label: 'Deletions',
                value: totalDeletions.toString(),
                color: DiffColors.deletion,
              ),
            ),
            Expanded(
              child: _statItem(
                context,
                icon: Octicons.file_diff,
                label: 'Files',
                value: fileCount.toString(),
                color: context.colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _statItem(
  BuildContext context, {
  required IconData icon,
  required String label,
  required String value,
  required Color color,
}) => Column(
  children: <Widget>[
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: 14, color: color),
        context.spacing.tightGap,
        Text(
          value,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    ),
    context.spacing.tightGap,
    Text(
      label,
      style: context.textTheme.labelSmall?.copyWith(
        color: context.colorScheme.onSurfaceVariant,
      ),
    ),
  ],
);

Widget _buildAssociatedPRs(BuildContext context, CommitInfo commit) {
  final CommitAssociatedPRs? pullRequests = commit.associatedPullRequests;
  if (pullRequests == null) return const SizedBox.shrink();

  final List<CommitAssociatedPREdge?>? edges = pullRequests.edges;
  if (edges == null || edges.isEmpty) return const SizedBox.shrink();

  final List<CommitAssociatedPRNode> prs = edges
      .where((CommitAssociatedPREdge? edge) => edge?.node != null)
      .map((CommitAssociatedPREdge? edge) => edge!.node!)
      .toList();

  if (prs.isEmpty) return const SizedBox.shrink();

  return BorderedContainer(
    backgroundColor: Color.lerp(
      context.colorScheme.surfaceContainer,
      Colors.black,
      0.1,
    ),
    elevation: 0,
    padding: context.spacing.pagePadding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              Octicons.git_pull_request,
              size: 16,
              color: context.colorScheme.onSurfaceVariant,
            ),
            context.spacing.itemGap,
            Text(
              'Associated Pull Requests',
              style: context.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        context.spacing.contentGap,
        ...prs.map((CommitAssociatedPRNode pr) {
          final GitHubActionVisual visual =
              GitHubVisualStyles.fromGraphQLPullRequestState(
                pr.state,
                isDraft: pr.isDraft,
              );
          final Color stateColor = visual.color;
          final IconData stateIcon = visual.icon;
          final String stateText = visual.label;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TapFeedback(
              onTap: () => launchUrl(Uri.parse(pr.url.toString())),
              child: Padding(
                padding: EdgeInsets.all(context.spacing.itemSpacing),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: context.spacing.chipPadding,
                      decoration: BoxDecoration(
                        color: stateColor.tintMedium,
                        borderRadius: context.radius(RadiusSize.small),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(stateIcon, size: 12, color: stateColor),
                          context.spacing.tightGap,
                          Text(
                            '#${pr.number}',
                            style: context.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: stateColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    context.spacing.itemGap,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            pr.title,
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stateText,
                            style: context.textTheme.labelSmall?.copyWith(
                              color: stateColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 16,
                      color: context.colorScheme.onSurfaceVariant.hinted,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    ),
  );
}

Widget _buildCommitCommentTile(
  BuildContext context,
  WidgetRef ref,
  CommitCommentItem item,
) {
  final spacing = context.spacing;
  return BorderedContainer(
    backgroundColor: context.colorScheme.surfaceContainerLow,
    elevation: 0,
    padding: spacing.contentPadding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            if (item.userAvatarUrl != null)
              UserAvatar(avatarUrl: item.userAvatarUrl, size: 24),
            if (item.userAvatarUrl != null) spacing.compactGap,
            if (item.userLogin != null)
              Text(
                item.userLogin!,
                style: context.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colorScheme.onSurfaceVariant.secondary,
                ),
              ),
            const Spacer(),
            Text(
              item.createdAt.toRelativeDate(shorten: true),
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant.hinted,
              ),
            ),
          ],
        ),
        if (item.body.isNotEmpty) ...[
          spacing.tightGap,
          TrimmableMarkdownContent(text: item.body, repo: null),
        ],
      ],
    ),
  );
}

class _CommitCommentComposeRow extends ConsumerWidget {
  const _CommitCommentComposeRow({required this.commitRef});

  final CommitRef commitRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.itemSpacing),
      child: Text(
        'Add a comment below or use the compose bar when this tab is focused.',
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colorScheme.onSurfaceVariant.hinted,
        ),
      ),
    );
  }
}

const int _commitCommentsPageSize = 20;

class _CommitCommentsListSliver extends ConsumerStatefulWidget {
  const _CommitCommentsListSliver({
    super.key,
    required this.commitRef,
    required this.buildTile,
    required this.spacing,
  });

  final CommitRef commitRef;
  final Widget Function(BuildContext context, CommitCommentItem item) buildTile;
  final AppSpacing spacing;

  @override
  ConsumerState<_CommitCommentsListSliver> createState() =>
      _CommitCommentsListSliverState();
}

class _CommitCommentsListSliverState
    extends ConsumerState<_CommitCommentsListSliver> {
  late final PaginationController<CommitCommentItem, CommitCommentItem>
  _controller;

  @override
  void initState() {
    super.initState();
    _controller = PaginationController<CommitCommentItem, CommitCommentItem>(
      source: PageNumberForwardSource<CommitCommentItem>(
        fetch: ({required int page, required int perPage}) async {
          final apiClient = ref.read(apiClientProvider);
          return widget.commitRef.repo
              .services(apiClient)
              .listCommitComments(
                commitRef: widget.commitRef,
                page: page,
                perPage: perPage,
                refresh: page == 1,
              );
        },
      ),
      idOf: (CommitCommentItem c) => '${c.id}',
      pageSize: _commitCommentsPageSize,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      commitCommentsRefreshTriggerProvider(widget.commitRef),
      (_, __) => _controller.refresh(),
    );
    return PaginatedSliverList<CommitCommentItem>(
      controller: _controller,
      itemBuilder: (BuildContext context, CommitCommentItem item, int index) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (index > 0) SizedBox(height: widget.spacing.itemSpacing),
            widget.buildTile(context, item),
          ],
        );
      },
    );
  }
}
