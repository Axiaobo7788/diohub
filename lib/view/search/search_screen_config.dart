import 'package:diohub/common/context_dock/context_dock.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/nav_center/models/entity_config.dart';
import 'package:diohub/common/search_overlay/search_type.dart';
import 'package:diohub/common/widgets/entity_store_card.dart';
import 'package:diohub_models/models/database_types.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/nav_center/models/tab_body.dart';
import 'package:diohub/common/nav_center/models/tab_controls.dart';
import 'package:diohub/common/nav_center/shell/tab_body_page.dart';
import 'package:diohub/common/wrappers/search_scroll_wrapper.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/providers/entity_store_providers.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/providers/search/search_state_notifier.dart';
import 'package:diohub/providers/search/search_type_counts_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/view/search/trending_repos_content.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Builds [ScreenConfig] for the Search tab (NavCenter shell with global search positions).
/// [reposRefreshRegistrar] is used by the Repositories position for pull-to-refresh when
/// search results are shown (empty query shows [TrendingReposContent] with no refresh).
ScreenConfig buildSearchScreenConfig(
  BuildContext context,
  WidgetRef ref, {
  String? initialTabPath,
  required ValueNotifier<Future<void> Function()?> reposRefreshRegistrar,
}) {
  const scopeRepos =
      SearchScope.typedGlobal(searchType: SearchType.repositories);
  const scopeIssues =
      SearchScope.typedGlobal(searchType: SearchType.issuesPulls);
  const scopeUsers = SearchScope.typedGlobal(searchType: SearchType.users);
  const scopeDiscussions =
      SearchScope.typedGlobal(searchType: SearchType.discussions);

  final counts = ref.watch(searchTypeCountsNotifierProvider);

  return ScreenConfig(
    entity: EntityConfig(
      title: const Text('Search'),
      metadataSections: const [],
      actionSections: const [],
    ),
    initialTabPath: initialTabPath,
    tabs: [
      _reposPosition(
        scope: scopeRepos as TypedGlobalSearchScope,
        count: counts?.repositories,
        refreshRegistrar: reposRefreshRegistrar,
      ),
      _position(
        scope: scopeIssues,
        deeplinkPath: 'issues',
        count: counts?.issues,
      ),
      _position(
        scope: scopeUsers,
        deeplinkPath: 'users',
        count: counts?.users,
      ),
      _position(
        scope: scopeDiscussions,
        deeplinkPath: 'discussions',
        count: counts?.discussions,
      ),
      _savedSearchesPosition(),
      _searchHistoryPosition(),
    ],
  );
}

TabConfig _savedSearchesPosition() {
  return TabConfig(
    deeplinkPath: 'saved-searches',
    label: 'Saved Searches',
    icon: Octicons.bookmark,
    category: TabCategory.primary,
    keepAlive: true,
    body: TabBodyPage(
      body: SliverBuilderBody(
        sliverBuilder: (ctx, ref) {
          final saved = ref.watch(allSavedSearchesProvider).asData?.value ?? [];
          final spacing = ctx.spacing;
          return [
            SliverPadding(
              padding: spacing.listInset,
              sliver: SliverList.builder(
                itemCount: saved.length,
                itemBuilder: (context, index) {
                  final entry = saved[index];
                  final query = entry.query;
                  final title = (entry.label?.isNotEmpty ?? false)
                      ? entry.label!
                      : (query.isEmpty ? 'Empty query' : query);
                  return Padding(
                    padding: EdgeInsets.only(bottom: spacing.itemSpacing),
                    child: BorderedContainer(
                      onTap: () {
                        ref
                            .read(pendingSearchInitialQueryProvider.notifier)
                            .set(query.isEmpty ? null : query);
                      },
                      child: Padding(
                        padding: context.spacing.cardContentPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (entry.label != null &&
                                entry.label != query &&
                                query.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(
                                    top: spacing.itemSpacing * 0.5),
                                child: Text(
                                  query,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            Text(
                              entry.savedAt.toRelativeDate(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
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
  );
}

TabConfig _searchHistoryPosition() {
  return TabConfig(
    deeplinkPath: 'search-history',
    label: 'Search History',
    icon: Octicons.history,
    category: TabCategory.primary,
    keepAlive: true,
    body: TabBodyPage(
      body: SliverBuilderBody(
        sliverBuilder: (ctx, ref) {
          final history = ref.watch(allHistoryProvider).asData?.value ?? [];
          final spacing = ctx.spacing;
          return [
            SliverPadding(
              padding: spacing.listInset,
              sliver: SliverList.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final entry = history[index];
                  final title =
                      entry.entity.snapshotTitle ?? entry.entity.entityPath;
                  return Padding(
                    padding: EdgeInsets.only(bottom: spacing.itemSpacing),
                    child: EntityStoreCard(
                      entry: HistoryEntry(entry),
                      showParentBreadcrumb: false,
                      titleOverride: title,
                      onTap: () {
                        ref
                            .read(pendingSearchInitialQueryProvider.notifier)
                            .set(title);
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
  );
}

TabConfig _reposPosition({
  required TypedGlobalSearchScope scope,
  int? count,
  required ValueNotifier<Future<void> Function()?> refreshRegistrar,
}) {
  return TabConfig(
    deeplinkPath: 'repositories',
    label: scope.searchType.displayName,
    icon: scope.searchType.icon,
    category: TabCategory.primary,
    keepAlive: true,
    trailing: count != null ? CountTrailing(() => count) : null,
    searchScope: scope,
    body: TabBodyPage(
      body: SliverBuilderBody(
        sliverBuilder: (context, ref) {
          ref.listen(pendingSearchInitialQueryProvider, (final _, final next) {
            if (next != null && next.isNotEmpty) {
              ref
                  .read(searchStateNotifierProvider(scope).notifier)
                  .setRawFreeText(next);
              ref.read(pendingSearchInitialQueryProvider.notifier).set(null);
            }
          });
          final q = ref.watch(
              searchStateNotifierProvider(scope).select((s) => s.freeText));
          if (q.trim().isEmpty) {
            refreshRegistrar.value = null;
            return [
              SliverFillRemaining(
                child: const TrendingReposContent(),
              ),
            ];
          }
          return [
            SearchScrollSlivers(
              scope,
              onRefreshReady: (fn) => refreshRegistrar.value = fn,
            ),
          ];
        },
        refreshRegistrar: refreshRegistrar,
      ),
    ),
    controls: TabControls.search(scope: scope),
  );
}

TabConfig _position({
  required SearchScope scope,
  required String deeplinkPath,
  int? count,
}) {
  final typedScope = scope as TypedGlobalSearchScope;
  return TabConfig(
    deeplinkPath: deeplinkPath,
    label: scope.searchType.displayName,
    icon: scope.searchType.icon,
    category: TabCategory.primary,
    keepAlive: true,
    trailing: count != null ? CountTrailing(() => count) : null,
    searchScope: scope,
    body: TabBodyPage(body: SearchListBody(scope: scope)),
    controls: TabControls.search(scope: typedScope),
  );
}
