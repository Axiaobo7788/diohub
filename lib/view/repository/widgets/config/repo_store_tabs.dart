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
import 'package:diohub/common/nav_center/shell/tab_body_page.dart';
import 'package:diohub_models/models/app_config.dart';
import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub_models/models/search/sort_config.dart';
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
import 'package:diohub/providers/repository/milestone_filter_provider.dart';
import 'package:diohub/providers/repository/milestone_list_patches_provider.dart';
import 'package:diohub/view/repository/wiki/wiki_browser.dart';
import 'package:diohub/providers/repository/wiki_providers.dart';
import 'package:diohub_models/models/repositories/workflow_run.dart';
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
import 'package:diohub/view/common/entity_logs_position.dart';

List<TabConfig> buildStoreTabs(RepoTabContext ctx) {
  final tabs = <TabConfig>[];
  final context = ctx.context;
  final ref = ctx.ref;
  final repoRef = ctx.repoRef;

  // Bookmarks scoped to this repo
  tabs.add(
    TabConfig(
      label: 'Bookmarks',
      icon: Octicons.bookmark,
      category: TabCategory.primary,
      tint: Theme.of(context).colorScheme.primary,
      keepAlive: true,
      deeplinkPath: 'bookmarks',
      body: TabBodyPage(
        body: SliverBuilderBody(
          sliverBuilder: (ctx, r) {
            final bookmarks =
                r
                    .watch(scopedBookmarksProvider(repoRef.apiPath))
                    .asData
                    ?.value ??
                [];
            final spacing = ctx.spacing;
            return [
              SliverPadding(
                padding: spacing.listInset,
                sliver: SliverList.builder(
                  itemCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    final entry = bookmarks[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: spacing.itemSpacing),
                      child: EntityStoreCard(
                        entry: BookmarkEntry(entry),
                        showParentBreadcrumb: false,
                      ),
                    );
                  },
                ),
              ),
            ];
          },
        ),
      ),
      inlineControls: (ctx, ref) => [
        PopupHintDockPill<EntityTypeFilter?>(
          iconData: Octicons.tag,
          options: const [
            null,
            EntityTypeFilter.issue,
            EntityTypeFilter.pr,
            EntityTypeFilter.commit,
            EntityTypeFilter.release,
            EntityTypeFilter.wiki,
            EntityTypeFilter.codeFile,
          ],
          defaultValue: null,
          getValue: (r) =>
              r.watch(scopedBookmarkFilterProvider(repoRef.apiPath)).entityType,
          onSelected: (r, v) => r
              .read(scopedBookmarkFilterProvider(repoRef.apiPath).notifier)
              .update((f) => f.copyWith(entityType: v)),
          labelOf: (v) => EntityTypeFilter.displayLabelFor(v?.dbValue),
        ),
        PopupHintDockPill<EntityState?>(
          iconData: Octicons.issue_opened,
          options: [null, ...EntityState.values],
          defaultValue: null,
          getValue: (r) =>
              r.watch(scopedBookmarkFilterProvider(repoRef.apiPath)).state,
          onSelected: (r, v) => r
              .read(scopedBookmarkFilterProvider(repoRef.apiPath).notifier)
              .update((f) => f.copyWith(state: v)),
          labelOf: (v) => v?.displayLabel ?? 'All',
        ),
        PopupHintDockPill<bool>(
          iconData: Icons.edit_note_rounded,
          options: const [false, true],
          defaultValue: false,
          getValue: (r) =>
              r.watch(scopedBookmarkFilterProvider(repoRef.apiPath)).hasDrafts,
          onSelected: (r, v) => r
              .read(scopedBookmarkFilterProvider(repoRef.apiPath).notifier)
              .update((q) => q.copyWith(hasDrafts: v)),
          labelOf: (v) => v ? 'With drafts' : 'All',
        ),
      ],
      dockActions: (ctx, ref) => [],
      trailing: null,
      ambientIndicator: null,
    ),
  );

  // History scoped to this repo
  tabs.add(
    TabConfig(
      label: 'History',
      icon: Octicons.history,
      category: TabCategory.primary,
      tint: Theme.of(context).colorScheme.outline,
      keepAlive: true,
      deeplinkPath: 'history',
      body: TabBodyPage(
        body: SliverBuilderBody(
          sliverBuilder: (ctx, r) {
            final history =
                r.watch(scopedHistoryProvider(repoRef.apiPath)).asData?.value ??
                [];
            final spacing = ctx.spacing;
            return [
              SliverPadding(
                padding: spacing.listInset,
                sliver: SliverList.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final entry = history[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: spacing.itemSpacing),
                      child: EntityStoreCard(
                        entry: HistoryEntry(entry),
                        showParentBreadcrumb: false,
                      ),
                    );
                  },
                ),
              ),
            ];
          },
        ),
      ),
      inlineControls: (ctx, ref) => [],
      dockActions: (ctx, ref) => [],
      trailing: null,
      ambientIndicator: null,
    ),
  );

  // Saved searches scoped to this repo
  tabs.add(
    TabConfig(
      label: 'Saved Searches',
      icon: Octicons.search,
      category: TabCategory.other,
      tint: Theme.of(context).colorScheme.tertiary,
      keepAlive: true,
      deeplinkPath: 'saved-searches',
      body: TabBodyPage(
        body: SliverBuilderBody(
          sliverBuilder: (ctx, r) {
            final saved =
                r
                    .watch(scopedSavedSearchesProvider(repoRef.apiPath))
                    .asData
                    ?.value ??
                [];
            final spacing = ctx.spacing;
            return [
              SliverPadding(
                padding: spacing.listInset,
                sliver: SliverList.builder(
                  itemCount: saved.length,
                  itemBuilder: (context, index) {
                    final entry = saved[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: spacing.itemSpacing),
                      child: ListTile(
                        title: Text(entry.label ?? entry.query),
                        onTap: () {
                          r
                              .read(pendingSearchInitialQueryProvider.notifier)
                              .set(entry.query);
                        },
                      ),
                    );
                  },
                ),
              ),
            ];
          },
        ),
      ),
      inlineControls: (ctx, ref) => [],
      dockActions: (ctx, ref) => [],
      trailing: null,
      ambientIndicator: null,
    ),
  );

  // Logs scoped to this repo
  tabs.add(
    buildEntityLogsPosition(
      entityPath: repoRef.apiPath,
      emptyMessage: 'No logs for this repo',
    ),
  );

  return tabs;
}
