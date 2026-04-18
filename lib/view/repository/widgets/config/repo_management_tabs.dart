import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub_graphql/fragments/common_exports.dart';
import 'package:diohub/common/misc/profile_card.dart';
import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_models/models/entity_snapshot_factories.dart';
import 'package:diohub_models/models/users/profile_card_input.dart'
    hide OrgCardData, UserCardData;
import 'package:diohub/common/context_dock/context_dock.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/nav_center/models/sort_binding.dart';
import 'package:diohub/common/nav_center/models/tab_action.dart';
import 'package:diohub/common/nav_center/models/tab_body.dart';
import 'package:diohub/common/nav_center/models/tab_controls.dart';
import 'package:diohub/common/nav_center/shell/tab_body_page.dart';
import 'package:diohub_models/models/entity_snapshot_factories.dart';
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub_models/models/search/sort_spec.dart';
import 'package:diohub_models/models/database_types.dart';
import 'package:diohub/providers/filter_state_providers.dart';
import 'package:diohub/providers/notifier_update_extension.dart';
import 'package:diohub/providers/search/search_state_notifier.dart';
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

import 'repo_branch_tag_tiles.dart';
import 'repo_label_milestone_tiles.dart';
import 'repo_settings_sections.dart';
import 'package:diohub/view/repository/collaborators/repo_collaborators_tab.dart';

List<TabConfig> buildManagementTabs(RepoTabContext ctx) {
  final tabs = <TabConfig>[];
  final context = ctx.context;
  final ref = ctx.ref;
  final repoRef = ctx.repoRef;
  final repo = ctx.repo;
  final permission = ctx.permission;

  // Stargazers position
  tabs.add(
    TabConfig(
      label: 'Stargazers',
      icon: Octicons.star,
      category: TabCategory.other,
      keepAlive: false,
      deeplinkPath: 'stargazers',
      body: TabBodyPage(
        body: SliverListBody<StargazerEdge>(
          getCursor: (e) => e?.cursor,
          pageSize: 20,
          fetcher: ({after, first = 20, refresh = false}) => repoRef
              .services(ref.read(apiClientProvider))
              .fetchStargazersPaginated(
                first: first,
                after: after,
                refresh: refresh,
              ),
          itemBuilder: (ctx, edge) {
            final node = edge.node;
            if (node == null) return const SizedBox.shrink();
            final input = ProfileCardInputUser(
              FragmentUser(node as UserCardData),
            );
            return BorderedContainer(
              ref: UserRef(login: input.login),
              child: ProfileCard(input),
            );
          },
        ),
      ),
      controls: TabControls.clientList(
        searchQuery: ref.read(
          inlineSearchQueryNotifierProvider(
            'repo/${repoRef.owner}/${repoRef.name}/stargazers',
          ),
        ),
      ),
      trailing: repo.stargazerCount > 0
          ? CountTrailing(() => repo.stargazerCount)
          : null,
      ambientIndicator: null,
    ),
  );

  // Forks position
  tabs.add(
    TabConfig(
      label: 'Forks',
      icon: Octicons.repo_forked,
      category: TabCategory.other,
      keepAlive: false,
      deeplinkPath: 'forks',
      body: TabBodyPage(
        body: SliverListBody<ForkEdge>(
          getCursor: (e) => e?.cursor,
          pageSize: 20,
          fetcher: ({after, first = 20, refresh = false}) => repoRef
              .services(ref.read(apiClientProvider))
              .fetchForksPaginated(
                first: first,
                after: after,
                refresh: refresh,
              ),
          itemBuilder: (ctx, edge) {
            final node = edge.node;
            if (node == null) return const SizedBox.shrink();
            final spacing = ctx.spacing;
            return Padding(
              padding: spacing.screenPadding,
              child: RepositoryCard(
                node,
                starChip: RepoStarChipFromProvider(
                  repoRef: RepoRef.fromFullName(node.nameWithOwner),
                ),
              ),
            );
          },
        ),
      ),
      inlineControls: (ctx, ref) => [],
      dockActions: (ctx, ref) => [
        InlineSearchDockPill(
          queryNotifier: ref.read(
            inlineSearchQueryNotifierProvider(
              'repo/${repoRef.owner}/${repoRef.name}/forks',
            ),
          ),
        ),
      ],
      trailing: repo.forkCount > 0 ? CountTrailing(() => repo.forkCount) : null,
      ambientIndicator: null,
    ),
  );

  // Watchers position
  tabs.add(
    TabConfig(
      label: 'Watchers',
      icon: Octicons.eye,
      category: TabCategory.other,
      keepAlive: false,
      deeplinkPath: 'watchers',
      body: TabBodyPage(
        body: SliverListBody<WatcherEdge>(
          getCursor: (e) => e?.cursor,
          pageSize: 20,
          fetcher: ({after, first = 20, refresh = false}) => repoRef
              .services(ref.read(apiClientProvider))
              .fetchWatchersPaginated(
                first: first,
                after: after,
                refresh: refresh,
              ),
          itemBuilder: (ctx, edge) {
            final node = edge.node;
            if (node == null) return const SizedBox.shrink();
            final input = ProfileCardInputUser(
              FragmentUser(node as UserCardData),
            );
            return BorderedContainer(
              ref: UserRef(login: input.login),
              child: ProfileCard(input),
            );
          },
        ),
      ),
      inlineControls: (ctx, ref) => [],
      dockActions: (ctx, ref) => [
        InlineSearchDockPill(
          queryNotifier: ref.read(
            inlineSearchQueryNotifierProvider(
              'repo/${repoRef.owner}/${repoRef.name}/watchers',
            ),
          ),
        ),
      ],
      trailing: repo.watchers.totalCount > 0
          ? CountTrailing(() => repo.watchers.totalCount)
          : null,
      ambientIndicator: null,
    ),
  );

  // Tags position
  final canWriteRepo = isAtLeast(permission, RepositoryPermission.WRITE);
  final ownerLogin = switch (repo.owner) {
    Fragment$actor actor => actor.login,
    _ => throw ArgumentError('Invalid owner type: ${repo.owner.runtimeType}'),
  };
  final tagsSearchKey = 'repo/$ownerLogin/${repo.name}/tags';
  final tagsQueryNotifier = ref.read(
    inlineSearchQueryNotifierProvider(tagsSearchKey),
  );
  tabs.add(
    TabConfig(
      label: 'Tags',
      icon: Octicons.tag,
      category: TabCategory.other,
      keepAlive: false,
      deeplinkPath: 'tags',
      body: TabBodyPage(
        body: SliverListBody<TagEdge>(
          getCursor: (e) => e?.cursor,
          pageSize: 20,
          hintText: 'Filter tags',
          queryNotifier: tagsQueryNotifier,
          refreshTrigger: ref.read(tagsRefreshTriggerProvider(repoRef)),
          fetcherWithQuery: ({after, first = 20, refresh = false, query}) {
            final order = ref.read(tagSortOrderProvider(repoRef));
            final refOrder = refOrderForTagSort(order);
            return repoRef
                .branches(ref.read(apiClientProvider))
                .fetchTagsPaginated(
                  first: first,
                  after: after,
                  query: query,
                  orderField: refOrder.field,
                  orderDirection: refOrder.direction,
                  refresh: refresh,
                );
          },
          itemBuilder: (ctx, edge) =>
              buildTagTile(ctx, ref, edge, repoRef, permission),
        ),
      ),
      controls: TabControls.clientList(
        searchQuery: tagsQueryNotifier,
        sort: SortBinding.typed<TagSortOrder>(
          spec: SortSpec(
            options: TagSortOrder.values,
            defaultValue: TagSortOrder.byDate,
            labelOf: (o) => switch (o) {
              TagSortOrder.byDate => 'Recent',
              TagSortOrder.byName => 'Name',
            },
          ),
          getValue: (r) => r.watch(tagSortOrderProvider(repoRef)),
          onSelected: (r, order) {
            r.read(tagSortOrderProvider(repoRef).notifier).state = order;
            r.read(tagsRefreshTriggerProvider(repoRef)).value++;
          },
        ),
      ),
      actions: [
        if (canWriteRepo)
          TabAction.create(
            icon: Icons.add_rounded,
            label: 'New tag',
            onTap: (_) => CreateBranchSheet.show(
              context,
              repoRef: repoRef,
              repositoryId: repo.id,
              onCreated: () {},
            ),
          ),
      ],
      trailing: repo.tagCount != null && repo.tagCount!.totalCount > 0
          ? CountTrailing(() => repo.tagCount!.totalCount)
          : null,
      ambientIndicator: null,
    ),
  );

  // Settings tab (admin only)
  if (repo.viewerCanAdminister == true) {
    tabs.add(
      TabConfig(
        label: 'Settings',
        icon: Octicons.gear,
        category: TabCategory.other,
        keepAlive: false,
        deeplinkPath: 'settings',
        body: TabBodyPage(
          body: SettingsBody(
            sections: repoSettingsSections(context, ref, repoRef, repo),
          ),
        ),
        ambientIndicator: null,
      ),
    );
  }

  // Labels tab (admin only)
  if (repo.viewerCanAdminister == true) {
    tabs.add(
      TabConfig(
        label: 'Labels',
        icon: Octicons.tag,
        category: TabCategory.other,
        keepAlive: false,
        deeplinkPath: 'labels',
        body: TabBodyPage(
          body: SliverListBody<LabelEdge?>(
            getCursor: (e) => e?.cursor,
            pageSize: 30,
            fetcher: ({after, first = 30, refresh = false}) => repoRef
                .labelsAndMilestones(ref.read(apiClientProvider))
                .listAvailableLabelsGQL(first: first, after: after),
            itemBuilder: (ctx, edge) =>
                buildLabelTile(ctx, ref, repoRef, repo, edge?.node),
          ),
        ),
        ambientIndicator: null,
      ),
    );
  }

  // Milestones tab (write access)
  if (isAtLeast(permission, RepositoryPermission.WRITE)) {
    tabs.add(
      TabConfig(
        label: 'Milestones',
        icon: Octicons.milestone,
        category: TabCategory.other,
        keepAlive: false,
        deeplinkPath: 'milestones',
        body: TabBodyPage(
          body: SliverListBody<MilestoneEdge?>(
            getCursor: (e) => e?.cursor,
            pageSize: 30,
            fetcher: ({after, first = 30, refresh = false}) => repoRef
                .labelsAndMilestones(ref.read(apiClientProvider))
                .listMilestonesGQL(first: first, after: after),
            itemBuilder: (ctx, edge) {
              if (edge == null) return const SizedBox.shrink();
              return buildMilestoneTile(
                ctx,
                ref,
                repoRef,
                edge,
                repo.viewerCanAdminister,
              );
            },
          ),
        ),
        ambientIndicator: null,
      ),
    );
  }

  // Collaborators tab (admin only)
  if (repo.viewerCanAdminister == true) {
    tabs.add(
      TabConfig(
        label: 'Collaborators',
        icon: Octicons.people,
        category: TabCategory.other,
        keepAlive: false,
        deeplinkPath: 'collaborators',
        body: TabBodyPage(body: createCollaboratorsBody(ref, repoRef)),
        ambientIndicator: null,
      ),
    );
  }

  // Branches tab
  tabs.add(
    TabConfig(
      label: 'Branches',
      icon: Octicons.git_branch,
      category: TabCategory.other,
      keepAlive: false,
      deeplinkPath: 'branches',
      body: TabBodyPage(
        body: SliverListBody<BranchEdge>(
          getCursor: (e) => e?.cursor,
          pageSize: 20,
          fetcher: ({after, first = 20, refresh = false}) => repoRef
              .branches(ref.read(apiClientProvider))
              .fetchBranchesPaginated(
                first: first,
                after: after,
                refresh: refresh,
              ),
          itemBuilder: (ctx, edge) =>
              buildBranchTile(ctx, edge, repoRef, permission),
        ),
      ),
      ambientIndicator: null,
    ),
  );

  // Premium tabs injection
  final premiumDefs = ref
      .read(premiumTabsProvider)
      .repoManagementTabs(context, ref, repoRef: repoRef, repo: repo);
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
