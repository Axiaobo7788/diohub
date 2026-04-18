import 'package:diohub/app/settings/dashboard_settings.dart';
import 'package:diohub/common/animations/staggered_entrance.dart';
import 'package:diohub/common/misc/async_error_widgets.dart';
import 'package:diohub/providers/dashboard/dashboard_provider.dart';
import 'package:diohub/providers/dashboard/dashboard_settings_provider.dart';
import 'package:diohub/view/home/dashboard/dashboard_shimmer.dart';
import 'package:diohub/view/home/dashboard/sections/bookmarks_section.dart';
import 'package:diohub/view/home/dashboard/sections/contributions_section.dart';
import 'package:diohub/view/home/dashboard/sections/pinned_repos_section.dart';
import 'package:diohub/view/home/dashboard/sections/recent_history_section.dart';
import 'package:diohub/view/home/dashboard/sections/saved_searches_section.dart';
import 'package:diohub/view/home/dashboard/sections/search_results_section.dart';
import 'package:diohub/view/home/dashboard/sections/stats_section.dart';
import 'package:diohub_graphql/queries/viewer/viewer_typedefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Composer widget that orchestrates dashboard sections based on settings.
///
/// Reads [dashboardSettingsProvider] for section order/visibility and
/// [dashboardDataProvider] for GQL data, then dispatches to individual
/// section widgets.
class DashboardSectionComposer extends ConsumerWidget {
  const DashboardSectionComposer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(dashboardSettingsProvider);
    final gqlState = ref.watch(dashboardDataProvider);

    return gqlState.when(
      loading: () => SliverList.list(children: buildDashboardShimmer(settings)),
      error: (e, _) => SliverFillRemaining(child: CenteredError(e.toString())),
      data: (data) => SliverList.list(
        children: _buildVisibleSections(context, ref, settings, data),
      ),
    );
  }

  List<Widget> _buildVisibleSections(
    BuildContext context,
    WidgetRef ref,
    DashboardSettings settings,
    DashboardData data,
  ) {
    final sectionBuilders = <DashboardSectionId, Widget>{
      DashboardSectionId.stats: DashboardStatsSection(data: data),
      DashboardSectionId.contributions: DashboardContributionsSection(
        data: data,
      ),
      DashboardSectionId.reviewRequests: DashboardSearchResultsSection(
        title: 'Review Requests',
        icon: Octicons.eye,
        nodes: (data.reviewRequests.nodes ?? []).whereType<Object>().toList(),
        totalCount: data.reviewRequests.issueCount,
        limit: settings.limitFor(DashboardSectionId.reviewRequests),
      ),
      DashboardSectionId.assignedIssues: DashboardSearchResultsSection(
        title: 'Assigned Issues',
        icon: Octicons.issue_opened,
        nodes: (data.assignedIssues.nodes ?? []).whereType<Object>().toList(),
        totalCount: data.assignedIssues.issueCount,
        limit: settings.limitFor(DashboardSectionId.assignedIssues),
      ),
      DashboardSectionId.yourPRs: DashboardSearchResultsSection(
        title: 'Your PRs',
        icon: Octicons.git_pull_request,
        nodes: (data.yourPRs.nodes ?? []).whereType<Object>().toList(),
        totalCount: data.yourPRs.issueCount,
        limit: settings.limitFor(DashboardSectionId.yourPRs),
      ),
      DashboardSectionId.pinnedRepos: DashboardPinnedReposSection(data: data),
      DashboardSectionId.bookmarks: DashboardBookmarksSection(
        limit: settings.limitFor(DashboardSectionId.bookmarks),
      ),
      DashboardSectionId.savedSearches: DashboardSavedSearchesSection(
        limit: settings.limitFor(DashboardSectionId.savedSearches),
      ),
      DashboardSectionId.recentHistory: DashboardRecentHistorySection(
        limit: settings.limitFor(DashboardSectionId.recentHistory),
      ),
    };

    return [
      for (final (i, id) in settings.sectionOrder.indexed)
        if (settings.isVisible(id))
          StaggeredEntrance(index: i, child: sectionBuilders[id]!),
    ];
  }
}
