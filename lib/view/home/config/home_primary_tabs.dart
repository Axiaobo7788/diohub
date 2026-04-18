import 'package:auto_route/auto_route.dart';
import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/context_dock/pills/basic_dock_pill.dart';
import 'package:diohub/common/context_dock/pills/popup_hint_dock_pill.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/nav_center/models/sort_binding.dart';
import 'package:diohub/common/nav_center/models/tab_action.dart';
import 'package:diohub/common/nav_center/models/tab_controls.dart';
import 'package:diohub/common/nav_center/shell/tab_body_page.dart';
import 'package:diohub/common/search_overlay/bookmark_filter_adapter.dart';
import 'package:diohub/common/search_overlay/notifications_filter_adapter.dart';
import 'package:diohub/common/widgets/entity_store_card.dart';
import 'package:diohub/common/wrappers/sticky_glass_header.dart';
import 'package:diohub_database/database/enums/enums.dart';
import 'package:diohub_graphql/queries/viewer/viewer_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/search/sort_spec.dart';
import 'package:diohub/providers/browsing/bookmark_grouping_providers.dart';
import 'package:diohub/providers/browsing/view_mode_providers.dart';
import 'package:diohub/providers/entity_store_providers.dart';
import 'package:diohub/providers/filter_state_providers.dart';
import 'package:diohub/providers/notifier_update_extension.dart';
import 'package:diohub/providers/notifications/notifications_service_provider.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/view/home/config/home_dashboard_tab.dart';
import 'package:diohub/view/home/config/home_popup_sections.dart';
import 'package:diohub/view/home/widgets/repo_picker_bottom_sheet.dart';
import 'package:diohub/view/notifications/notifications.dart';
import 'package:diohub/view/repository/issues/widgets/template_picker_sheet.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub_models/models/database_types.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:diohub/models/search/search_scope.dart';

List<TabConfig> buildTabs(
  BuildContext context,
  WidgetRef ref,
  ViewerInfo viewer,
  Widget Function(BuildContext, [ValueNotifier<Future<void> Function()?>?])
  eventsViewBuilder,
  ValueNotifier<Future<void> Function()?> feedRefreshRegistrar,
  ValueNotifier<Future<void> Function()?> notificationsRefreshRegistrar,
) {
  final String login = viewer.login;
  return [
    buildDashboardTab(ref),
    TabConfig(
      deeplinkPath: 'events',
      label: 'Feed',
      icon: Octicons.pulse,
      category: TabCategory.primary,
      keepAlive: true,
      body: TabBodyPage(
        body: SliverBuilderBody(
          sliverBuilder: (ctx, ref) => [
            eventsViewBuilder(ctx, feedRefreshRegistrar),
          ],
          refreshRegistrar: feedRefreshRegistrar,
        ),
      ),
    ),
    TabConfig(
      deeplinkPath: 'issues',
      label: 'Issues',
      icon: Octicons.issue_opened,
      category: TabCategory.primary,
      keepAlive: true,
      supportsSelection: true,
      trailing: CountTrailing(() => viewer.issues.totalCount),
      searchScope: SearchScope.homeIssues(viewerLogin: login),
      presets: NavigationPresets.issues,
      body: TabBodyPage(
        body: SearchListBody(scope: SearchScope.homeIssues(viewerLogin: login)),
      ),
      controls: TabControls.search(
        scope: SearchScope.homeIssues(viewerLogin: login),
        presets: NavigationPresets.issues,
        supportsSelection: true,
      ),
      actions: [
        TabAction.create(
          icon: Icons.add_rounded,
          label: 'New Issue',
          onTap: (r) async {
            final repoRef = await RepoPickerBottomSheet.show(context, login);
            if (repoRef == null || !context.mounted) return;
            try {
              final data = await r.read(repositoryProvider(repoRef).future);
              final templates = data.repository?.issueTemplates?.toList() ?? [];
              final selected = await TemplatePickerSheet.show(
                context,
                templates: templates,
                showBlankOption: true,
              );
              if (!context.mounted) return;
              await AutoRouter.of(
                context,
              ).push(NewIssueRoute(repoRef: repoRef, template: selected));
            } catch (e, st) {
              AppLogger.warning(
                'New issue route or template selection failed',
                error: e,
                stackTrace: st,
                tag: 'HomeScreenConfig',
              );
            }
          },
        ),
      ],
    ),
    TabConfig(
      deeplinkPath: 'pulls',
      label: 'Pull Requests',
      icon: Octicons.git_pull_request,
      category: TabCategory.primary,
      keepAlive: true,
      supportsSelection: true,
      trailing: CountTrailing(() => viewer.pullRequests.totalCount),
      searchScope: SearchScope.homePulls(viewerLogin: login),
      presets: NavigationPresets.pulls,
      body: TabBodyPage(
        body: SearchListBody(scope: SearchScope.homePulls(viewerLogin: login)),
      ),
      controls: TabControls.search(
        scope: SearchScope.homePulls(viewerLogin: login),
        presets: NavigationPresets.pulls,
        supportsSelection: true,
      ),
      actions: [
        TabAction.create(
          icon: Octicons.git_pull_request,
          label: 'New PR',
          onTap: (_) async {
            final RepoRef? repoRef = await RepoPickerBottomSheet.show(
              context,
              login,
            );
            if (repoRef != null && context.mounted) {
              AutoRouter.of(
                context,
              ).push(NewPullRequestRoute(repoRef: repoRef));
            }
          },
        ),
      ],
    ),
    TabConfig(
      deeplinkPath: 'notifications',
      label: 'Inbox',
      icon: Octicons.bell,
      category: TabCategory.primary,
      keepAlive: true,
      supportsSelection: true,
      trailing: buildNotificationCountTrailing(ref),
      body: TabBodyPage(
        body: SliverBuilderBody(
          refreshRegistrar: notificationsRefreshRegistrar,
          sliverBuilder: (ctx, ref) => [
            SliverFillRemaining(
              child: NotificationsInboxWithRefreshRegistrar(
                refreshRegistrar: notificationsRefreshRegistrar,
              ),
            ),
          ],
        ),
      ),
      controls: TabControls.filterable(
        sections: NotificationsFilterAdapter(ref).sections,
        stateNotifier: NotificationsFilterAdapter(ref),
        activeFilterCount: () => NotificationsFilterAdapter(ref).activeCount,
        adapter: NotificationsFilterAdapter(ref),
      ),
      dockActions: (ctx, ref) => [
        BasicDockPill(
          iconData: Icons.mark_email_read_rounded,
          label: 'Mark all read',
          onTapAction: (_) =>
              ref.read(notificationsServiceProvider).markAllAsRead(),
        ),
      ],
    ),
    TabConfig(
      deeplinkPath: 'bookmarks',
      label: 'Bookmarks',
      icon: Octicons.bookmark,
      category: TabCategory.primary,
      tint: Theme.of(context).colorScheme.primary,
      keepAlive: true,
      body: TabBodyPage(
        body: SliverBuilderBody(
          sliverBuilder: (ctx, ref) {
            final viewMode = ref.watch(bookmarkViewModeProvider);
            final spacing = ctx.spacing;
            if (viewMode == BookmarkViewMode.flat) {
              final bookmarks =
                  ref.watch(filteredBookmarksProvider).asData?.value ?? [];
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
                          showParentBreadcrumb: true,
                        ),
                      );
                    },
                  ),
                ),
              ];
            }
            if (viewMode == BookmarkViewMode.byRepo) {
              final groups =
                  ref.watch(bookmarksByRepoProvider).asData?.value ?? [];
              return [
                for (final group in groups)
                  StickyGlassSection.withTitle(
                    title: group.label ?? group.parentPath ?? 'Ungrouped',
                    trailing: Text('${group.count}'),
                    sliver: SliverPadding(
                      padding: spacing.listInset,
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final entry = group.entries[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: spacing.itemSpacing,
                            ),
                            child: EntityStoreCard(
                              entry: BookmarkEntry(entry),
                              showParentBreadcrumb: true,
                            ),
                          );
                        }, childCount: group.entries.length),
                      ),
                    ),
                  ),
              ];
            }
            final groups =
                ref.watch(bookmarksByTypeProvider).asData?.value ?? [];
            return [
              for (final group in groups)
                StickyGlassSection.withTitle(
                  title: group.label ?? group.groupKey ?? 'Other',
                  trailing: Text('${group.count}'),
                  sliver: SliverPadding(
                    padding: spacing.listInset,
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final entry = group.entries[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: spacing.itemSpacing),
                          child: EntityStoreCard(
                            entry: BookmarkEntry(entry),
                            showParentBreadcrumb: true,
                          ),
                        );
                      }, childCount: group.entries.length),
                    ),
                  ),
                ),
            ];
          },
        ),
      ),
      controls: TabControls.filterable(
        sections: BookmarkFilterAdapter(ref, bookmarkFilterProvider).sections,
        stateNotifier: BookmarkFilterAdapter(ref, bookmarkFilterProvider),
        activeFilterCount: () =>
            BookmarkFilterAdapter(ref, bookmarkFilterProvider).activeCount,
        adapter: BookmarkFilterAdapter(ref, bookmarkFilterProvider),
        sort: SortBinding.typed<BookmarkOrder>(
          spec: SortSpec(
            options: BookmarkOrder.values,
            defaultValue: BookmarkOrder.newest,
            labelOf: (o) => o.displayLabel,
          ),
          getValue: (r) => r.watch(bookmarkFilterProvider).order,
          onSelected: (r, order) {
            final current = r.read(bookmarkFilterProvider);
            r
                .read(bookmarkFilterProvider.notifier)
                .update((_) => current.copyWith(order: order));
          },
        ),
        searchQuery: ref.read(bookmarkSearchQueryNotifierProvider),
      ),
      inlineControls: (ctx, ref) => [
        PopupHintDockPill<BookmarkViewMode>(
          iconData: Icons.view_list_rounded,
          options: BookmarkViewMode.values,
          defaultValue: BookmarkViewMode.flat,
          getValue: (r) => r.watch(bookmarkViewModeProvider),
          onSelected: (r, v) {
            r.read(bookmarkViewModeProvider.notifier).update((_) => v);
          },
          labelOf: (v) => v.label,
        ),
      ],
    ),
  ];
}
