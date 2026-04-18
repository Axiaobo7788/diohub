import 'dart:async';

import 'package:diohub/app/settings/code_browser_settings.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/search/client_text_matcher.dart';
import 'package:diohub/common/cards/commit_card.dart';
import 'package:diohub/common/misc/async_error_widgets.dart';
import 'package:diohub/common/misc/highlighted_container.dart';
import 'package:diohub/common/widgets/metadata_section_sliver.dart';
import 'package:diohub/common/wrappers/sticky_glass_header.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub/models/commits/commit_list_item_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/code/code_browser_state.dart';
import 'package:diohub_models/models/repositories/code/code_tree_node.dart';
import 'package:diohub_models/models/repositories/code/directory_last_commit.dart';
import 'package:diohub/providers/code_browser/code_browser_state_provider.dart';
import 'package:diohub/providers/code_browser/directory_last_commit_provider.dart';
import 'package:diohub/providers/code_browser/directory_provider.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/providers/settings/code_browser_settings_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/view/repository/code/commit_browser.dart';
import 'package:diohub/view/repository/code/file_viewer_screen.dart';
import 'package:diohub/view/repository/code/widgets/breadcrumb_bar.dart';
import 'package:diohub/view/repository/code/widgets/directory_entry_tile.dart';
import 'package:diohub/view/repository/code/widgets/directory_skeleton.dart';
import 'package:diohub/view/repository/code/widgets/directory_toolbar.dart';
import 'package:diohub/view/issues_pulls/widgets/timeline_chips.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/utils/utils.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:diohub/common/extensions/async_value_logging.dart';

/// Slivers for the Code tab (path-based directory browser).
/// Use in the shell's Code position.
List<Widget> buildCodeBrowserSlivers(
  final BuildContext context,
  final WidgetRef ref,
  final RepoRef repoRef,
) {
  final CodeBrowserState navState =
      ref.watch(codeBrowserStateProvider(repoRef));
  final CodeBrowserSettings settings = ref.watch(codeBrowserSettingsProvider);
  final BranchState branchState = ref.watch(branchProvider(repoRef));
  final BranchStateResolved? resolved =
      branchState is BranchStateResolved ? branchState : null;
  final String branchRef = resolved?.currentSHA ?? '';
  final DirectoryKey dirKey = (
    repo: repoRef,
    branch: branchRef,
    path: navState.currentPath,
  );
  final AsyncValue<List<CodeTreeNode>> dirAsync =
      ref.watch(directoryProvider(dirKey));
  final String repoName = ref.watch(
    repositoryProvider(repoRef).select(
      (final AsyncValue<RepoInfoData> a) => a.value?.repository?.name ?? '',
    ),
  );

  return <Widget>[
    if (resolved != null && resolved.isCommit)
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: _buildCommitShaCard(context, ref, repoRef, resolved),
        ),
      ),
    StickyGlassHeader(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          BreadcrumbBar(
            repoName: repoName,
            currentPath: navState.currentPath,
            onSegmentTap: (int index) => ref
                .read(codeBrowserStateProvider(repoRef).notifier)
                .jumpToPathIndex(index),
            onRootTap: () => ref
                .read(codeBrowserStateProvider(repoRef).notifier)
                .jumpToPathIndex(-1),
          ),
          DirectoryToolbar(
            repoRef: repoRef,
            settings: settings,
            searchQuery: navState.searchQuery,
          ),
        ],
      ),
    ),
    dirAsync.maybeWhen(
      loading: () => SliverToBoxAdapter(
        child: DirectorySkeleton(itemCount: 8),
      ),
      error: (final Object err, final StackTrace _) => SliverFillRemaining(
        hasScrollBody: false,
        child: CenteredError('Error loading directory: $err'),
      ),
      data: (final List<CodeTreeNode> entries) {
        final List<CodeTreeNode> filtered =
            _filterEntries(entries, settings, navState.searchQuery);
        final List<CodeTreeNode> sorted =
            _sortEntries(filtered, settings.sortOrder);
        final List<CodeTreeNode> fileSiblings = sorted
            .where((CodeTreeNode e) =>
                e.kind == CodeEntryKind.file || e.kind == CodeEntryKind.symlink)
            .toList();

        return MultiSliver(
          children: <Widget>[
            SliverPadding(
              padding: context.spacing.screenPadding,
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext ctx, int i) {
                    final CodeTreeNode node = sorted[i];
                    return DirectoryEntryTile(
                      entry: node,
                      repoRef: repoRef,
                      branch: branchRef,
                      showLastCommit: settings.showLastCommitInfo,
                      showMetadata: settings.showMetadata,
                      onDirectoryTap: (CodeTreeNode dir) => ref
                          .read(codeBrowserStateProvider(repoRef).notifier)
                          .pushDirectory(dir.path),
                      onFileTap: (CodeTreeNode file) => _pushFileViewer(
                        ctx,
                        repoRef,
                        branchRef,
                        file,
                        fileSiblings,
                      ),
                      onSubmoduleTap: (CodeTreeNode sub) =>
                          _onSubmoduleTap(ctx, ref, sub),
                    );
                  },
                  childCount: sorted.length,
                ),
              ),
            ),
            _LatestCommitSection(
              repoRef: repoRef,
              branch: branchRef,
              path: navState.currentPath,
              onCommitTap: () => _showCommitHistory(
                context,
                ref,
                repoRef,
                resolved?.currentSHA,
                navState.currentPath,
              ),
            ),
          ],
        );
      },
      orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
    ),
  ];
}

final _codeMatcher = ClientTextMatcher<CodeTreeNode>(
  fields: [(CodeTreeNode e) => e.name],
);

List<CodeTreeNode> _filterEntries(
  List<CodeTreeNode> entries,
  CodeBrowserSettings settings,
  String searchQuery,
) {
  List<CodeTreeNode> out = entries;
  if (!settings.showDotfiles) {
    out = out.where((CodeTreeNode e) => !e.name.startsWith('.')).toList();
  }
  if (!settings.showGeneratedFiles) {
    out = out.where((CodeTreeNode e) => !e.isGenerated).toList();
  }
  return _codeMatcher.filter(out, searchQuery);
}

List<CodeTreeNode> _sortEntries(
    List<CodeTreeNode> entries, CodeSortOrder order) {
  final List<CodeTreeNode> list = List<CodeTreeNode>.from(entries);
  switch (order) {
    case CodeSortOrder.type:
      list.sort((CodeTreeNode a, CodeTreeNode b) {
        final int kindOrder = _kindOrder(a.kind).compareTo(_kindOrder(b.kind));
        if (kindOrder != 0) return kindOrder;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      break;
    case CodeSortOrder.nameAsc:
      list.sort((CodeTreeNode a, CodeTreeNode b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      break;
    case CodeSortOrder.nameDesc:
      list.sort((CodeTreeNode a, CodeTreeNode b) =>
          b.name.toLowerCase().compareTo(a.name.toLowerCase()));
      break;
    case CodeSortOrder.size:
      list.sort((CodeTreeNode a, CodeTreeNode b) {
        final int s = (b.size).compareTo(a.size);
        if (s != 0) return s;
        return a.name.compareTo(b.name);
      });
      break;
    case CodeSortOrder.extension:
      list.sort((CodeTreeNode a, CodeTreeNode b) {
        final String extA = a.extension ?? '';
        final String extB = b.extension ?? '';
        final int c = extA.compareTo(extB);
        if (c != 0) return c;
        return a.name.compareTo(b.name);
      });
      break;
  }
  return list;
}

int _kindOrder(CodeEntryKind kind) {
  return switch (kind) {
    CodeEntryKind.directory => 0,
    CodeEntryKind.file => 1,
    CodeEntryKind.symlink => 2,
    CodeEntryKind.submodule => 3,
  };
}

void _pushFileViewer(
  BuildContext context,
  RepoRef repoRef,
  String branch,
  CodeTreeNode file,
  List<CodeTreeNode> siblingFiles,
) {
  final int initialIndex = siblingFiles.length > 1
      ? siblingFiles
          .indexWhere((CodeTreeNode e) => e.path == file.path)
          .clamp(0, siblingFiles.length - 1)
      : 0;
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (BuildContext _) => FileViewerScreen(
        repoRef: repoRef,
        branch: branch,
        filePath: file.path,
        siblingFiles: siblingFiles.length > 1 ? siblingFiles : null,
        initialIndex: initialIndex,
      ),
    ),
  );
}

void _onSubmoduleTap(BuildContext context, WidgetRef ref, CodeTreeNode sub) {
  final String? url = sub.submoduleGitUrl;
  if (url == null || url.isEmpty) return;
  // Parse owner/name from git URL and push RepositoryRoute if possible.
  // For now we do nothing; router can handle deep link to repo.
}

Widget _buildCommitShaCard(
  final BuildContext context,
  final WidgetRef ref,
  final RepoRef repoRef,
  final BranchStateResolved branch,
) {
  final RepoInfo repo =
      ref.read(repositoryProvider(repoRef)).requireValue.repository!;
  final String? defaultOid = repo.defaultBranchRef?.target?.maybeWhen(
    commit: (final c) => c.oid,
    orElse: () => null,
  );
  final String? defaultTreeOid = repo.defaultBranchRef?.target?.maybeWhen(
    commit: (final c) => c.tree.oid,
    orElse: () => null,
  );
  final bool canReturn = defaultOid != null &&
      defaultTreeOid != null &&
      defaultOid.isNotEmpty &&
      defaultTreeOid.isNotEmpty;
  return HighlightedContainer(
    highlightColor: context.colorScheme.primary,
    child: Material(
      color: context.colorScheme.surfaceContainerHigh,
      borderRadius: context.radius(RadiusSize.medium),
      child: InkWell(
        onTap: canReturn
            ? () {
                ref.read(branchProvider(repoRef).notifier).setRef(
                      repo.defaultBranchRef!.name,
                      RefKind.branch,
                      oid: defaultOid,
                      treeOid: defaultTreeOid,
                    );
              }
            : null,
        borderRadius: context.radius(RadiusSize.medium),
        child: Padding(
          padding: context.spacing.pagePadding,
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.colorScheme.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Octicons.git_commit,
                  size: 20,
                  color: context.colorScheme.primary,
                ),
              ),
              context.spacing.contentGap,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Currently browsing commit',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    context.spacing.tightGap,
                    InteractiveCommitChip(
                      abbreviatedOid: branch.currentSHA.length >= 7
                          ? branch.currentSHA.substring(0, 7)
                          : branch.currentSHA,
                      fullOid: branch.currentSHA,
                      repoRef: repoRef,
                    ),
                  ],
                ),
              ),
              if (repo.defaultBranchRef != null)
                Padding(
                  padding: EdgeInsets.only(right: context.spacing.tightSpacing),
                  child: TextButton.icon(
                    onPressed: () {
                      context.router.push(CompareViewRoute(
                        repoRef: repoRef,
                        base: branch.currentSHA,
                        head: repo.defaultBranchRef!.name,
                      ));
                    },
                    icon: Icon(
                      Octicons.git_compare,
                      size: 16,
                      color: context.colorScheme.primary,
                    ),
                    label: Text(
                      'Compare with HEAD',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              Icon(
                Icons.refresh_rounded,
                size: 20,
                color: context.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void _showCommitHistory(
  final BuildContext context,
  final WidgetRef ref,
  final RepoRef repoRef,
  final String? currentSHA,
  final String path,
) {
  final BranchState branch = ref.read(branchProvider(repoRef));
  if (branch is! BranchStateResolved) return;
  final BranchStateResolved resolved = branch;

  unawaited(
    AppSheet.scrollable(
      context,
      header: AppSheetHeader(
        title: Text(
          'Commit History',
          style: context.textTheme.titleSmall,
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Octicons.git_branch, size: 14),
            context.spacing.tightGap,
            Flexible(
              child: Text(
                resolved.currentSHA,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      bodyBuilder: (
        final BuildContext context,
        final StateSetter setState,
        final ScrollController scrollController,
      ) =>
          CommitBrowser(
        controller: scrollController,
        currentSHA: currentSHA,
        isLocked: resolved.isCommit,
        repo: repoRef,
        path: path.isEmpty ? null : path,
        branchName: resolved.currentSHA,
        onSelected: (final String sha, final String treeOid) {
          ref.read(branchProvider(repoRef).notifier).setRef(
                sha,
                RefKind.commit,
                oid: sha,
                treeOid: treeOid,
              );
        },
      ),
    ),
  );
}

class _LatestCommitSection extends ConsumerWidget {
  const _LatestCommitSection({
    required this.repoRef,
    required this.branch,
    required this.path,
    required this.onCommitTap,
  });

  final RepoRef repoRef;
  final String branch;
  final String path;
  final VoidCallback onCommitTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LastCommitKey key = (repo: repoRef, branch: branch, path: path);
    final AsyncValue<DirectoryLastCommit?> asyncLast =
        ref.watch(directoryLastCommitProvider(key));

    return asyncLast.whenOrShrink(
      debugLabel: 'codeBrowser',
      data: (DirectoryLastCommit? lastCommit) {
        if (lastCommit == null)
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        final CommitListItemModel model = CommitListItemModel(
          messageHeadline: lastCommit.message.length > 80
              ? '${lastCommit.message.substring(0, 80)}…'
              : lastCommit.message,
          committedDate: lastCommit.committedDate,
          sha: lastCommit.oid,
          authorLogin: lastCommit.authorName,
          authorAvatarUrl: lastCommit.authorAvatarUrl,
        );
        return MetadataSectionSliver(
          title: 'Latest Commit',
          icon: Octicons.git_commit,
          children: <Widget>[
            HighlightedContainer(
              highlightColor: context.colorScheme.primary,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onCommitTap,
                  child: Padding(
                    padding: context.spacing.cardContentPadding,
                    child: CommitCard(data: model),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
