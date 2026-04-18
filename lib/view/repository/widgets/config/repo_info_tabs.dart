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
import 'package:diohub/common/nav_center/models/tab_body.dart';
import 'package:diohub/common/nav_center/models/tab_controls.dart';
import 'package:diohub/common/nav_center/shell/tab_body_page.dart';
import 'package:diohub_models/models/app_config.dart';
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
import 'package:diohub/utils/permission_utils.dart';
import 'package:diohub/providers/code_browser/code_browser_state_provider.dart';
import 'package:diohub/providers/code_browser/directory_provider.dart';
import 'package:diohub/view/repository/code/code_browser_slivers.dart';
import 'package:diohub/view/repository/commits/commit_graph_view.dart';
import 'package:diohub/view/repository/license/repository_license.dart';
import 'package:diohub/view/repository/projects/projects_tab.dart';
import 'package:diohub/view/repository/readme/repository_readme.dart';
// TODO(phase-10): Premium will provide create release action via callback
// import 'package:diohub/view/repository/releases/create_release_screen.dart';
import 'package:diohub/view/repository/releases/release_assets_sheet.dart';
import 'package:diohub/view/repository/releases/releases_tab.dart';
import 'package:diohub/view/repository/code/create_file_screen.dart';
import 'package:diohub/view/repository/code/widgets/create_branch_sheet.dart';
import 'package:diohub/providers/repository/milestone_filter_provider.dart';
import 'package:diohub/providers/repository/milestone_list_patches_provider.dart';
import 'package:diohub/view/repository/wiki/wiki_browser.dart';
import 'package:diohub/providers/repository/wiki_providers.dart';
import 'package:diohub_models/models/repositories/workflow_run.dart';
import 'package:diohub/providers/entity_store_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/view/repository/widgets/config/repo_pinned_issues_section.dart';
import 'package:diohub/view/repository/widgets/config/repo_tabs.dart';

List<TabConfig> buildInfoTabs(RepoTabContext ctx) {
  final tabs = <TabConfig>[];
  final context = ctx.context;
  final ref = ctx.ref;
  final repoRef = ctx.repoRef;
  final repo = ctx.repo;

  // License tab (conditional)
  if (repo.licenseInfo != null) {
    tabs.add(
      TabConfig(
        label: 'License',
        icon: Octicons.law,
        category: TabCategory.other,
        keepAlive: false,
        deeplinkPath: 'license',
        body: TabBodyPage(
          body: SliverBuilderBody(
            sliverBuilder: (ctx, ref) => [
              Consumer(
                builder: (_, ref, __) {
                  final licenseContentAsync = ref.watch(
                    licenseContentProvider(repoRef),
                  );
                  final repoData = ref
                      .watch(repositoryProvider(repoRef))
                      .when(
                        data: (d) => d.repository,
                        loading: () => null,
                        error: (_, __) => null,
                      );
                  return RepositoryLicenseSliver(
                    licenseInfo: repoData?.licenseInfo,
                    licenseContentAsync: licenseContentAsync,
                  );
                },
              ),
            ],
            refreshFuture: () =>
                ref.refresh(licenseContentProvider(repoRef).future),
          ),
        ),
        inlineControls: (ctx, ref) => [],
        dockActions: (ctx, ref) => [],
        trailing: null,
        ambientIndicator: LicenseAmbient(repo.licenseInfo!.name),
      ),
    );
  }

  // Releases tab (conditional)
  if (repo.latestRelease != null) {
    tabs.add(
      TabConfig(
        label: 'Releases',
        icon: Octicons.tag,
        category: TabCategory.other,
        keepAlive: false,
        deeplinkPath: 'releases',
        body: TabBodyPage(
          body: SliverListBody<ReleaseEdge>(
            getCursor: (e) => e?.cursor,
            pageSize: 20,
            fetcher: ({after, first = 20, refresh = false}) => repoRef
                .releases(ref.read(apiClientProvider))
                .fetchReleasesPaginated(
                  after: after,
                  first: first,
                  refresh: refresh,
                ),
            itemBuilder: (ctx, edge) => edge.node == null
                ? const SizedBox.shrink()
                : buildReleaseListItem(ctx, repoRef, edge.node!),
          ),
        ),
        inlineControls: (ctx, ref) => [],
        dockActions: (ctx, ref) => [
          // TODO(phase-10): Premium will inject create release button via callback
          // if (repo.viewerCanAdminister) BasicDockPill(...CreateReleaseScreen...),
          BasicDockPill(
            iconData: Icons.download_rounded,
            label: 'Download',
            onTapAction: (_) {
              final release = repo.latestRelease!;
              showReleaseAssetsSheet(
                ctx,
                ref,
                repoRef: repoRef,
                releaseNodeId: release.id,
                releaseTag: release.tagName,
                releaseName: release.name ?? release.tagName,
              );
            },
          ),
        ],
        trailing: repo.releases.totalCount > 0
            ? CountTrailing(() => repo.releases.totalCount)
            : null,
        ambientIndicator: TagAmbient(
          tagName: repo.latestRelease!.tagName,
          isPrerelease: repo.latestRelease!.isPrerelease,
        ),
      ),
    );
  }

  // Discussions tab (conditional)
  if (repo.hasDiscussionsEnabled) {
    final repoDiscussionsScope = SearchScope.repoDiscussions(repo: repoRef);
    tabs.add(
      TabConfig(
        label: 'Discussions',
        icon: Octicons.comment_discussion,
        category: TabCategory.social,
        keepAlive: true,
        deeplinkPath: 'discussions',
        searchScope: repoDiscussionsScope,
        presets: const <NavigationPreset>[
          NavigationPreset(label: 'All', qualifier: '', isDefault: true),
          NavigationPreset(label: 'Answered', qualifier: 'is:answered'),
          NavigationPreset(label: 'Unanswered', qualifier: 'is:unanswered'),
          NavigationPreset(label: 'Open', qualifier: 'is:open'),
        ],
        body: TabBodyPage(body: SearchListBody(scope: repoDiscussionsScope)),
        controls: TabControls.search(
          scope: repoDiscussionsScope,
          presets: const <NavigationPreset>[
            NavigationPreset(label: 'All', qualifier: '', isDefault: true),
            NavigationPreset(label: 'Answered', qualifier: 'is:answered'),
            NavigationPreset(label: 'Unanswered', qualifier: 'is:unanswered'),
            NavigationPreset(label: 'Open', qualifier: 'is:open'),
          ],
        ),
        trailing: repo.discussions.totalCount > 0
            ? CountTrailing(() => repo.discussions.totalCount)
            : null,
        ambientIndicator: null,
      ),
    );
  }

  // Projects tab (conditional)
  if (repo.projectsV2.totalCount > 0) {
    tabs.add(
      TabConfig(
        label: 'Projects',
        icon: Octicons.project,
        category: TabCategory.social,
        keepAlive: false,
        deeplinkPath: 'projects',
        body: TabBodyPage(
          body: SliverListBody<ProjectV2Edge>(
            getCursor: (e) => e?.cursor,
            pageSize: 20,
            fetcher: ({after, first = 20, refresh = false}) => repoRef
                .services(ref.read(apiClientProvider))
                .fetchProjectsPaginated(
                  after: after,
                  first: first,
                  refresh: refresh,
                ),
            itemBuilder: (ctx, edge) {
              final node = edge.node;
              if (node == null) return const SizedBox.shrink();
              return buildProjectListItem(ctx, node);
            },
          ),
        ),
        controls: TabControls.clientList(
          searchQuery: ref.read(
            inlineSearchQueryNotifierProvider(
              'repo/${repoRef.owner}/${repoRef.name}/projects',
            ),
          ),
        ),
        trailing: repo.projectsV2.totalCount > 0
            ? CountTrailing(() => repo.projectsV2.totalCount)
            : null,
        ambientIndicator: null,
      ),
    );
  }

  // Wiki tab (conditional)
  if (repo.hasWikiEnabled) {
    tabs.add(
      TabConfig(
        label: 'Wiki',
        icon: Octicons.book,
        category: TabCategory.other,
        keepAlive: false,
        deeplinkPath: 'wiki',
        body: TabBodyPage(
          body: SliverBuilderBody(
            sliverBuilder: (ctx, r) => buildWikiBrowserSlivers(ctx, r, repoRef),
            refreshFuture: () => ref.refresh(wikiProvider(repoRef).future),
          ),
        ),
        inlineControls: (ctx, ref) => [],
        dockActions: (ctx, ref) => [],
        trailing: null,
        ambientIndicator: null,
      ),
    );
  }

  return tabs;
}
