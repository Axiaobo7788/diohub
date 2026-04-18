import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/bottom_sheet/confirm_action_sheet.dart';
import 'package:diohub/common/context_dock/pills/basic_dock_pill.dart';
import 'package:diohub/common/context_dock/pills/inline_search_dock_pill.dart';
import 'package:diohub/common/context_dock/pills/popup_hint_dock_pill.dart';
import 'package:diohub/common/misc/async_error_widgets.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/nav_center/shell/tab_body_page.dart';
import 'package:diohub/common/widgets/entity_store_card.dart';
import 'package:diohub/common/widgets/log_entry_card.dart';
import 'package:diohub/common/wrappers/sticky_glass_header.dart';
import 'package:diohub_graphql/queries/viewer/viewer_typedefs.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/browsing/history_filter_providers.dart';
import 'package:diohub/providers/browsing/history_grouping_providers.dart';
import 'package:diohub/providers/browsing/view_mode_providers.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/providers/entity_store_providers.dart';
import 'package:diohub/providers/notifier_update_extension.dart';
import 'package:diohub/providers/logging/log_providers.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/view/home/widgets/accounts_tab.dart';
import 'package:diohub/view/home/widgets/preferences_tab.dart';
import 'package:diohub/view/home/widgets/code_settings_tab.dart';
import 'package:diohub/view/home/widgets/behavior_tab.dart';
import 'package:diohub/view/home/widgets/themes_tab.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';
import 'package:diohub/view/logs/log_detail_sheet.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:diohub_models/models/database_types.dart';

List<Widget> _accountsSliverBuilder(BuildContext context, WidgetRef ref) => [
  const AccountsTabSlivers(),
];
List<Widget> _themesSliverBuilder(BuildContext context, WidgetRef ref) => [
  const ThemesTabSlivers(),
];
List<Widget> _preferencesBuilder(BuildContext context, WidgetRef ref) => [
  const PreferencesTabSlivers(),
];
List<Widget> _codeSettingsBuilder(BuildContext context, WidgetRef ref) => [
  const CodeSettingsTabSlivers(),
];
List<Widget> _behaviorBuilder(BuildContext context, WidgetRef ref) => [
  const BehaviorTabSlivers(),
];
List<Widget> _aiSettingsBuilder(BuildContext context, WidgetRef ref) =>
    ref.read(premiumSettingsProvider).settingsSections(context, ref);

void _showLogOutConfirmDialog(BuildContext context, WidgetRef ref) {
  showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: const Text('Log out'),
      content: const Text(
        'Log out of all accounts? You will need to sign in again to use the app.',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(dialogContext).pop();
            await ref.read(accountProvider.notifier).logOutAll();
          },
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(dialogContext).colorScheme.error,
          ),
          child: const Text('Log out'),
        ),
      ],
    ),
  );
}

List<TabConfig> buildHomeSecondaryPositions(
  BuildContext context,
  WidgetRef ref,
  ViewerInfo viewer,
  TabBody orgsBody,
) {
  return [
    TabConfig(
      deeplinkPath: 'history',
      label: 'History',
      icon: Octicons.history,
      category: TabCategory.primary,
      tint: Theme.of(context).colorScheme.outline,
      keepAlive: true,
      body: TabBodyPage(
        body: SliverBuilderBody(
          sliverBuilder: (ctx, ref) {
            final viewMode = ref.watch(historyViewModeProvider);
            final history =
                ref.watch(filteredHistoryProvider).asData?.value ?? [];
            final spacing = ctx.spacing;

            if (viewMode == HistoryViewMode.flat) {
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
                          showParentBreadcrumb: true,
                        ),
                      );
                    },
                  ),
                ),
              ];
            }

            if (viewMode == HistoryViewMode.byRepo) {
              final byRepo = <String?, List<HistoryWithEntity>>{};
              for (final e in history) {
                byRepo.putIfAbsent(e.entity.parentPath, () => []).add(e);
              }
              final repoGroups = byRepo.entries.toList()
                ..sort((a, b) {
                  final aFirst = a.value.isNotEmpty
                      ? a.value.first.visit.visitedAt
                      : DateTime(0);
                  final bFirst = b.value.isNotEmpty
                      ? b.value.first.visit.visitedAt
                      : DateTime(0);
                  return bFirst.compareTo(aFirst);
                });
              return [
                for (final group in repoGroups)
                  StickyGlassSection.withTitle(
                    title: group.key ?? 'Ungrouped',
                    trailing: Text('${group.value.length}'),
                    sliver: SliverPadding(
                      padding: spacing.listInset,
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final entry = group.value[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: spacing.itemSpacing,
                            ),
                            child: EntityStoreCard(
                              entry: HistoryEntry(entry),
                              showParentBreadcrumb: true,
                            ),
                          );
                        }, childCount: group.value.length),
                      ),
                    ),
                  ),
              ];
            }

            // byTime: use grouped history with date sections and search session sub-headers
            final sectionsAsync = ref.watch(groupedHistoryProvider);
            return sectionsAsync.when(
              data: (sections) => [
                for (final section in sections) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: spacing.listInset,
                      child: Text(
                        section.label,
                        style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  for (final group in section.groups)
                    if (group.isSearchSession)
                      StickyGlassSection.withTitle(
                        title: '🔍 "${group.searchQuery ?? ''}"',
                        trailing: Text('${group.count}'),
                        sliver: SliverPadding(
                          padding: spacing.listInset,
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final entry = group.entries[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: spacing.itemSpacing,
                                ),
                                child: EntityStoreCard(
                                  entry: HistoryEntry(entry),
                                  showParentBreadcrumb: true,
                                ),
                              );
                            }, childCount: group.count),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: spacing.listInset,
                        sliver: SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: spacing.itemSpacing,
                            ),
                            child: EntityStoreCard(
                              entry: HistoryEntry(group.entries.first),
                              showParentBreadcrumb: true,
                            ),
                          ),
                        ),
                      ),
                ],
              ],
              loading: () => [
                SliverPadding(
                  padding: spacing.listInset,
                  sliver: SliverToBoxAdapter(child: const CenteredSpinner()),
                ),
              ],
              error: (_, __) => [
                SliverPadding(
                  padding: spacing.listInset,
                  sliver: const SliverFillRemaining(
                    child: Center(child: Text('Failed to load history')),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      inlineControls: (ctx, ref) => [
        PopupHintDockPill<HistoryViewMode>(
          iconData: Icons.view_list_rounded,
          options: HistoryViewMode.values,
          defaultValue: HistoryViewMode.byTime,
          getValue: (r) => r.watch(historyViewModeProvider),
          onSelected: (r, v) =>
              r.read(historyViewModeProvider.notifier).state = v,
          labelOf: (v) => v.label,
        ),
        PopupHintDockPill<EntityTypeFilter?>(
          iconData: Octicons.tag,
          options: const [
            null,
            EntityTypeFilter.repo,
            EntityTypeFilter.issue,
            EntityTypeFilter.pr,
            EntityTypeFilter.commit,
            EntityTypeFilter.release,
          ],
          defaultValue: null,
          getValue: (r) => r.watch(historyFilterProvider).entityType,
          onSelected: (r, v) => r
              .read(historyFilterProvider.notifier)
              .update((f) => f.copyWith(entityType: v)),
          labelOf: (v) => EntityTypeFilter.displayLabelFor(v?.dbValue),
        ),
        PopupHintDockPill<HistoryTimeRange?>(
          iconData: Icons.schedule_rounded,
          options: [null, ...HistoryTimeRange.values],
          defaultValue: null,
          getValue: (r) => r.watch(historyFilterProvider).timeRange,
          onSelected: (r, v) => r
              .read(historyFilterProvider.notifier)
              .update((f) => f.copyWith(timeRange: v)),
          labelOf: (v) => v?.displayLabel ?? 'All time',
        ),
        BasicDockPill(
          iconData: ref.watch(historyFilterProvider).bookmarkedOnly
              ? Icons.bookmark_rounded
              : Octicons.bookmark,
          label: 'Bookmarked',
          onTapAction: (r) => r
              .read(historyFilterProvider.notifier)
              .update((f) => f.copyWith(bookmarkedOnly: !f.bookmarkedOnly)),
        ),
      ],
      dockActions: (ctx, ref) => [
        InlineSearchDockPill(
          queryNotifier: ref.read(historySearchQueryNotifierProvider),
        ),
      ],
    ),
    TabConfig(
      deeplinkPath: 'orgs',
      label: 'Organizations',
      icon: Octicons.organization,
      category: TabCategory.content,
      keepAlive: true,
      trailing: CountTrailing(() => viewer.organizations.totalCount),
      body: TabBodyPage(body: orgsBody),
      inlineControls: (ctx, ref) => [],
      dockActions: (ctx, ref) => [],
    ),
    TabConfig(
      deeplinkPath: 'accounts',
      label: 'Manage Accounts',
      icon: Icons.swap_horiz_rounded,
      category: TabCategory.other,
      keepAlive: true,
      body: TabBodyPage(
        body: SliverBuilderBody(sliverBuilder: _accountsSliverBuilder),
      ),
      inlineControls: (ctx, ref) => [],
      dockActions: (ctx, ref) => [
        BasicDockPill(
          iconData: Icons.person_add_rounded,
          label: 'Add Account',
          onTapAction: (_) {
            AutoRouter.of(ctx).push(AuthRoute());
          },
        ),
        BasicDockPill(
          iconData: Icons.logout_rounded,
          label: 'Log Out',
          onTapAction: (_) {
            _showLogOutConfirmDialog(ctx, ref);
          },
        ),
      ],
    ),
    TabConfig(
      deeplinkPath: 'themes',
      label: 'Themes',
      icon: Icons.palette_outlined,
      category: TabCategory.settings,
      keepAlive: true,
      body: TabBodyPage(
        body: SliverBuilderBody(sliverBuilder: _themesSliverBuilder),
      ),
    ),
    TabConfig(
      deeplinkPath: 'logs',
      label: 'Logs',
      icon: Icons.bug_report_rounded,
      category: TabCategory.other,
      keepAlive: false,
      visible: true,
      trailing: CountTrailing(
        () => ref.read(recentErrorCountProvider).value ?? 0,
      ),
      body: TabBodyPage(
        body: SliverBuilderBody(
          sliverBuilder: (ctx, ref) {
            final logsAsync = ref.watch(filteredLogsStreamProvider);
            final spacing = ctx.spacing;
            return [
              logsAsync.when(
                data: (entries) {
                  if (entries.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'No log entries',
                          style: Theme.of(ctx).textTheme.bodyLarge,
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: spacing.listInset,
                    sliver: SliverList.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: spacing.itemSpacing),
                          child: LogEntryCard(
                            entry: entry,
                            onTap: () => LogDetailSheet.show(ctx, entry),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: const CenteredSpinner(),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: spacing.pagePadding,
                    child: CenteredError(e.toString()),
                  ),
                ),
              ),
            ];
          },
        ),
      ),
      inlineControls: (ctx, ref) => [
        PopupHintDockPill<LogLevel?>(
          iconData: Icons.label_rounded,
          options: [null, ...LogLevel.values],
          defaultValue: null,
          getValue: (r) => r.watch(logFilterProvider).level,
          onSelected: (r, v) => r
              .read(logFilterProvider.notifier)
              .update((f) => f.copyWith(level: v)),
          labelOf: (v) => v == null ? 'All levels' : v.dbValue.toUpperCase(),
        ),
        PopupHintDockPill<String?>(
          iconData: Icons.source_rounded,
          options: const [null, 'Dio', 'GraphQL', 'Auth', 'Riverpod'],
          defaultValue: null,
          getValue: (r) => r.watch(logFilterProvider).tag,
          onSelected: (r, v) => r
              .read(logFilterProvider.notifier)
              .update((f) => f.copyWith(tag: v)),
          labelOf: (v) => v ?? 'All sources',
        ),
        PopupHintDockPill<EntityTypeFilter?>(
          iconData: Icons.category_rounded,
          options: const [
            null,
            EntityTypeFilter.repo,
            EntityTypeFilter.issue,
            EntityTypeFilter.pr,
            EntityTypeFilter.commit,
            EntityTypeFilter.release,
            EntityTypeFilter.workflowRun,
          ],
          defaultValue: null,
          getValue: (r) => r.watch(logFilterProvider).entityType,
          onSelected: (r, v) => r
              .read(logFilterProvider.notifier)
              .update((f) => f.copyWith(entityType: v)),
          labelOf: (v) => v == null
              ? 'All types'
              : EntityTypeFilter.displayLabelFor(v.dbValue),
        ),
        PopupHintDockPill<LogTimeRange?>(
          iconData: Icons.schedule_rounded,
          options: [null, ...LogTimeRange.values],
          defaultValue: null,
          getValue: (r) => r.watch(logFilterProvider).timeRange,
          onSelected: (r, v) => r
              .read(logFilterProvider.notifier)
              .update((f) => f.copyWith(timeRange: v)),
          labelOf: (v) => v?.displayLabel ?? 'All time',
        ),
        BasicDockPill(
          iconData: Icons.error_outline_rounded,
          label: ref.watch(logFilterProvider).errorsOnly
              ? 'Errors only ✓'
              : 'Errors only',
          onTapAction: (r) => r
              .read(logFilterProvider.notifier)
              .update((f) => f.copyWith(errorsOnly: !f.errorsOnly)),
        ),
        BasicDockPill(
          iconData: Icons.bookmark_rounded,
          label: ref.watch(logFilterProvider).bookmarkedOnly
              ? 'Bookmarked ✓'
              : 'Bookmarked only',
          onTapAction: (r) => r
              .read(logFilterProvider.notifier)
              .update((f) => f.copyWith(bookmarkedOnly: !f.bookmarkedOnly)),
        ),
      ],
      dockActions: (ctx, ref) => [
        InlineSearchDockPill(
          queryNotifier: ref.read(logSearchQueryNotifierProvider),
        ),
        BasicDockPill(
          iconData: Icons.delete_sweep_rounded,
          label: 'Clear logs',
          onTapAction: (r) async {
            final confirmed = await showConfirmAction(
              ctx,
              title: 'Clear all logs?',
              explanation: 'This will delete all stored log entries.',
              confirmLabel: 'Clear',
              isDestructive: true,
            );
            if (confirmed == true) {
              await r.read(logDaoProvider).deleteAll();
            }
          },
        ),
      ],
    ),
    TabConfig(
      deeplinkPath: 'preferences',
      label: 'Preferences',
      icon: Icons.tune_rounded,
      category: TabCategory.settings,
      keepAlive: true,
      body: TabBodyPage(
        body: SliverBuilderBody(sliverBuilder: _preferencesBuilder),
      ),
    ),
    TabConfig(
      deeplinkPath: 'code-settings',
      label: 'Code & Diffs',
      icon: Icons.code_rounded,
      category: TabCategory.settings,
      keepAlive: true,
      body: TabBodyPage(
        body: SliverBuilderBody(sliverBuilder: _codeSettingsBuilder),
      ),
    ),
    TabConfig(
      deeplinkPath: 'behavior',
      label: 'Behavior',
      icon: Icons.touch_app_rounded,
      category: TabCategory.settings,
      keepAlive: true,
      body: TabBodyPage(
        body: SliverBuilderBody(sliverBuilder: _behaviorBuilder),
      ),
    ),
    if (ref.read(premiumLifecycleProvider).isPremiumAvailable)
      TabConfig(
        deeplinkPath: 'ai',
        label: 'DioLens & AI',
        icon: Icons.auto_awesome,
        category: TabCategory.settings,
        keepAlive: true,
        body: TabBodyPage(
          body: SliverBuilderBody(sliverBuilder: _aiSettingsBuilder),
        ),
      ),
  ];
}
