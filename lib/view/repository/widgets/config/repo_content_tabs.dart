import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/misc/profile_card.dart';
import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_models/models/entity_snapshot_factories.dart';
import 'package:diohub_models/models/users/profile_card_input.dart'
    hide OrgCardData, UserCardData;
import 'package:diohub/common/context_dock/context_dock.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/nav_center/models/tab_action.dart';
import 'package:diohub/common/nav_center/models/tab_body.dart';
import 'package:diohub/common/nav_center/models/tab_controls.dart';
import 'package:diohub/common/nav_center/shell/tab_body_page.dart';
import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub_models/models/database_types.dart';
import 'package:diohub/providers/filter_state_providers.dart';
import 'package:diohub/providers/notifier_update_extension.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub/common/widgets/entity_store_card.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';

import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/dock/inline_search_query_provider.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/providers/database_providers.dart'
    show apiClientProvider;
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/providers/repository/tag_sort_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/view/repository/code/widgets/create_branch_sheet.dart';
import 'package:diohub/utils/permission_utils.dart';
import 'package:diohub/providers/code_browser/code_browser_state_provider.dart';
import 'package:diohub/providers/code_browser/directory_provider.dart';
import 'package:diohub/view/repository/code/code_browser_slivers.dart';
import 'package:diohub/view/repository/commits/commit_graph_view.dart';
import 'package:diohub/view/repository/license/repository_license.dart';
import 'package:diohub/view/repository/projects/projects_tab.dart';
import 'package:diohub/view/repository/readme/repository_readme.dart';
import 'package:diohub/view/repository/releases/release_assets_sheet.dart';
import 'package:diohub/view/repository/releases/releases_tab.dart';
import 'package:diohub/view/repository/code/create_file_screen.dart';
import 'package:diohub/view/repository/code/widgets/create_branch_sheet.dart';
import 'package:diohub/view/repository/wiki/wiki_browser.dart';
import 'package:diohub/providers/repository/wiki_providers.dart';
import 'package:diohub_models/models/download/download_metadata.dart';
import 'package:diohub/providers/entity_store_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/view/repository/widgets/config/repo_pinned_issues_section.dart';
import 'package:diohub/view/repository/widgets/config/repo_tabs.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';

List<TabConfig> buildContentTabs(
  RepoTabContext ctx,
  GlobalKey<RepositoryReadmeState> readmeStateKey,
) {
  final tabs = <TabConfig>[];
  final context = ctx.context;
  final ref = ctx.ref;
  final repoRef = ctx.repoRef;
  final repo = ctx.repo;
  final permission = ctx.permission;
  final defaultBranchName = ctx.defaultBranchName;

  // README tab (conditional)
  if (repo.readmeFile != null) {
    tabs.add(
      TabConfig(
        label: 'README',
        icon: Octicons.book,
        category: TabCategory.content,
        keepAlive: true,
        deeplinkPath: 'readme',
        body: TabBodyPage(
          body: SliverBuilderBody(
            sliverBuilder: (ctx, ref) => [
              Consumer(
                builder: (_, ref, __) {
                  final readmeAsync = ref.watch(readmeProvider(repoRef));
                  final branch = ref.watch(branchProvider(repoRef));
                  final branchRef = switch (branch) {
                    BranchStateResolved(:final currentSHA) => currentSHA,
                    BranchStateLoading() => '',
                  };
                  return RepositoryReadmeSliver(
                    key: readmeStateKey,
                    readmeAsync: readmeAsync,
                    branch: branchRef,
                    repoFullName: repoRef.fullName,
                  );
                },
              ),
            ],
            refreshFuture: () => ref.refresh(readmeProvider(repoRef).future),
          ),
        ),
        inlineControls: (ctx, ref) => [
          BranchDockPill(
            repo: repoRef,
            defaultBranch: repo.defaultBranchRef?.name ?? 'main',
          ),
        ],
        dockActions: (ctx, ref) => [],
        trailing: null,
        ambientIndicator: () {
          final branch = ref.watch(branchProvider(repoRef));
          return branch is BranchStateResolved
              ? BranchAmbient(branch.refValue)
              : null;
        }(),
      ),
    );
  }

  // Local variables used by multiple content tabs
  final repoIssuesScope = SearchScope.repoIssues(repo: repoRef);
  final repoPullsScope = RepoPullsScope(repo: repoRef);

  // Code tab
  tabs.add(
    TabConfig(
      label: 'Code',
      icon: Octicons.file_code,
      category: TabCategory.content,
      keepAlive: true,
      deeplinkPath: 'code',
      body: TabBodyPage(
        body: SliverBuilderBody(
          sliverBuilder: (ctx, r) => buildCodeBrowserSlivers(ctx, r, repoRef),
          refreshFuture: () {
            final navState = ref.read(codeBrowserStateProvider(repoRef));
            final branchState = ref.read(branchProvider(repoRef));
            if (branchState is! BranchStateResolved)
              return Future<void>.value();
            final key = (
              repo: repoRef,
              branch: branchState.currentSHA,
              path: navState.currentPath,
            );
            return ref.refresh(directoryProvider(key).future);
          },
        ),
      ),
      inlineControls: (ctx, ref) => [
        BranchDockPill(
          repo: repoRef,
          defaultBranch: defaultBranchName,
          repositoryId: repo.id,
          onCreateBranch: (context, repoRef, repositoryId) async {
            return CreateBranchSheet.show(
              context,
              repoRef: repoRef,
              repositoryId: repositoryId,
              onCreated: () {},
            );
          },
        ),
      ],
      dockActions: (ctx, ref) {
        final branchState = ref.watch(branchProvider(repoRef));
        final currentRef = branchState is BranchStateResolved
            ? branchState.refValue
            : defaultBranchName;
        return [
          if (isAtLeast(permission, RepositoryPermission.WRITE))
            BasicDockPill(
              iconData: Icons.add_rounded,
              label: 'File',
              onTapAction: (r) async {
                final branchState = r.read(branchProvider(repoRef));
                final branchRef = branchState is BranchStateResolved
                    ? branchState.refValue
                    : defaultBranchName;
                if (branchRef.length == 40 && ctx.mounted) {
                  r
                      .read(notificationServiceProvider)
                      .error(
                        'Cannot create file when viewing a specific commit',
                      );
                  return;
                }
                if (!ctx.mounted) return;
                final parentPath = r
                    .read(codeBrowserStateProvider(repoRef))
                    .currentPath;
                await Navigator.of(ctx).push<void>(
                  MaterialPageRoute<void>(
                    builder: (BuildContext c) => CreateFileScreen(
                      repoRef: repoRef,
                      branchRef: branchRef,
                      parentPath: parentPath,
                    ),
                  ),
                );
              },
            ),
        ];
      },
      trailing: repo.languages != null && repo.languages!.totalCount > 0
          ? CountTrailing(() => repo.languages!.totalCount)
          : null,
      ambientIndicator: () {
        final edges = repo.languages?.edges;
        if (edges != null && edges.isNotEmpty) {
          final segs = edges
              .whereType<RepoLanguageEdge>()
              .map(
                (e) => LanguageBarSegment(
                  color: e.node.color ?? '#6e7681',
                  size: e.size,
                ),
              )
              .toList();
          if (segs.isNotEmpty) {
            return LanguageBarAmbient(segments: segs);
          }
        }
        final branch = ref.watch(branchProvider(repoRef));
        return branch is BranchStateResolved
            ? BranchAmbient(branch.refValue)
            : null;
      }(),
    ),
  );

  // Issues tab
  final Widget? pinnedIssuesLeading =
      repo.pinnedIssues != null &&
          (repo.pinnedIssues!.nodes?.isNotEmpty ?? false)
      ? buildPinnedIssuesSection(context, ref, repo.pinnedIssues!, repoRef)
      : null;
  tabs.add(
    TabConfig(
      label: 'Issues',
      icon: Octicons.issue_opened,
      category: TabCategory.content,
      keepAlive: true,
      supportsSelection: true,
      deeplinkPath: 'issues',
      searchScope: repoIssuesScope,
      presets: NavigationPresets.issues,
      body: TabBodyPage(
        body: SearchListBody(
          scope: repoIssuesScope,
          leading: pinnedIssuesLeading,
        ),
      ),
      controls: TabControls.search(
        scope: repoIssuesScope,
        presets: NavigationPresets.issues,
        supportsSelection: true,
      ),
      actions: [
        TabAction.create(
          icon: Icons.add_rounded,
          label: 'New Issue',
          onTap: (_) => AutoRouter.of(
            context,
          ).push(NewIssueRoute(repoRef: repoRef, template: null)),
        ),
      ],
      trailing: repo.issues.totalCount > 0
          ? CountTrailing(() => repo.issues.totalCount)
          : null,
      ambientIndicator: null,
    ),
  );

  // Pull Requests tab
  tabs.add(
    TabConfig(
      label: 'Pull Requests',
      icon: Octicons.git_pull_request,
      category: TabCategory.content,
      keepAlive: true,
      supportsSelection: true,
      deeplinkPath: 'pulls',
      searchScope: repoPullsScope,
      presets: NavigationPresets.pulls,
      body: TabBodyPage(body: SearchListBody(scope: repoPullsScope)),
      controls: TabControls.search(
        scope: repoPullsScope,
        presets: NavigationPresets.pulls,
        supportsSelection: true,
      ),
      actions: [
        TabAction.create(
          icon: Icons.add_rounded,
          label: 'New PR',
          onTap: (_) => AutoRouter.of(
            context,
          ).push(NewPullRequestRoute(repoRef: repoRef)),
        ),
      ],
      trailing: repo.pullRequests.totalCount > 0
          ? CountTrailing(() => repo.pullRequests.totalCount)
          : null,
      ambientIndicator: null,
    ),
  );

  // Commits tab
  tabs.add(
    TabConfig(
      label: 'Commits',
      icon: Octicons.git_commit,
      category: TabCategory.content,
      keepAlive: true,
      deeplinkPath: 'commits',
      body: TabBodyPage(
        body: SliverBuilderBody(
          sliverBuilder: (context, ref) => [CommitGraphView(repoRef: repoRef)],
          refreshFuture: () => ref.refresh(commitGraphProvider(repoRef).future),
        ),
      ),
      inlineControls: (ctx, ref) {
        final branchState = ref.watch(branchProvider(repoRef));
        final branch = branchState is BranchStateResolved
            ? branchState.refValue
            : defaultBranchName;
        return [
          BranchDockPill(repo: repoRef, defaultBranch: defaultBranchName),
          CommitFilterDockPill(repo: repoRef, branch: branch),
        ];
      },
      dockActions: (ctx, ref) => [],
      trailing: repo.defaultBranchRef?.target != null
          ? CountTrailing(
              () => repo.defaultBranchRef!.target!.maybeWhen(
                commit: (c) => c.history.totalCount,
                orElse: () => null,
              ),
            )
          : null,
      ambientIndicator: () {
        final branch = ref.watch(branchProvider(repoRef));
        return branch is BranchStateResolved
            ? BranchAmbient(branch.refValue)
            : null;
      }(),
    ),
  );

  // Premium tabs injection
  final premiumDefs = ref
      .read(premiumTabsProvider)
      .repoContentTabs(context, ref, repoRef: repoRef, repo: repo);
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
