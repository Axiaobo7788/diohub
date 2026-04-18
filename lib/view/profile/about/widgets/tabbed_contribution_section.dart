import 'package:diohub/common/animations/animations.dart';
import 'package:diohub/common/misc/shimmer_bone.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_models/models/contributions/contribution_chip_type.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/view/profile/about/widgets/activity_timeline_section.dart';
import 'package:diohub/view/profile/about/widgets/contribution_deep_dive_tab.dart';
import 'package:diohub/view/profile/about/widgets/contribution_summary_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// Contribution section tab; single source of truth for tab identity.
enum ContributionTab {
  overview('Overview'),
  deepDive('Deep Dive'),
  timeline('Timeline');

  const ContributionTab(this.label);
  final String label;
}

/// Section with dropdown selection showing Summary, Contributions timeline, and Activity feed
/// Appears below the contribution calendar
class TabbedContributionSection extends StatelessWidget {
  const TabbedContributionSection({
    required this.contributionsAsync,
    required this.userRef,
    required this.createdAt,
    required this.providerKey,
    required this.selectedTab,
    this.pinnedRepos,
    this.onChipTap,
    this.topWidget,
    super.key,
  });

  static const ContributionTab defaultTab = ContributionTab.overview;
  static const List<ContributionTab> tabOrder = <ContributionTab>[
    ContributionTab.overview,
    ContributionTab.deepDive,
    ContributionTab.timeline,
  ];

  final AsyncValue<ContributionCollectionResult> contributionsAsync;
  final UserRef userRef;
  final DateTime? createdAt;
  final ContributionQueryKey providerKey;
  final List<RepoCardData>? pinnedRepos;
  final void Function(ContributionChipType chipType)? onChipTap;
  final Widget? topWidget;
  final ContributionTab selectedTab;

  /// Extract display values from providerKey
  int? get selectedYear => providerKey.dateRange.displayYear;
  DateTime? get customFromDate => providerKey.dateRange.displayFromDate;
  DateTime? get customToDate => providerKey.dateRange.displayToDate;
  bool get useCustomRange => providerKey.dateRange.isCustomRange;

  @override
  Widget build(final BuildContext context) {
    return MultiSliver(children: _buildSlivers(context));
  }

  List<Widget> _buildSlivers(final BuildContext context) => <Widget>[
    if (topWidget != null) SliverToBoxAdapter(child: topWidget!),
    _buildSectionTitleSliver(context, selectedTab),
    _buildContentForKey(context, selectedTab),
  ];

  Widget _buildSectionTitleSliver(
    final BuildContext context,
    final ContributionTab tab,
  ) {
    final String title = tab.label;
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return SliverToBoxAdapter(
      child: Padding(
        padding: context.spacing.sectionTitlePaddingMedium,
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildContentForKey(
    final BuildContext context,
    final ContributionTab tab,
  ) {
    // For Summary tab, handle loading/error states
    if (tab == ContributionTab.overview) {
      return contributionsAsync.animatedWhenSliver(
        data: (final ContributionCollectionResult result) =>
            ContributionSummaryTab(
              contributionResult: result,
              userRef: userRef,
              createdAt: createdAt,
              providerKey: providerKey,
              pinnedItems: pinnedRepos ?? const <RepoCardData>[],
              onChipTap: onChipTap,
            ),
        loading: _buildSummaryLoadingSkeleton,
        error: (final Object error, final StackTrace stackTrace) => Center(
          child: Padding(
            padding: context.spacing.pagePadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                context.spacing.sectionGap,
                Text(
                  'Unable to load contribution data',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                context.spacing.itemGap,
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        transition: AnimationTransition.fadeSize,
      );
    }

    // Other tabs
    switch (tab) {
      case ContributionTab.deepDive:
        return contributionsAsync.animatedWhenSliver(
          data: (final ContributionCollectionResult result) =>
              ContributionDeepDiveTab(
                contributionResult: result,
                userRef: userRef,
                providerKey: providerKey,
              ),
          loading: _buildSummaryLoadingSkeleton,
          error: (final Object error, final StackTrace stackTrace) => Center(
            child: Padding(
              padding: context.spacing.pagePadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  context.spacing.sectionGap,
                  Text(
                    'Unable to load contribution data',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          transition: AnimationTransition.fadeSize,
        );
      case ContributionTab.timeline:
        return ActivityTimelineSection(providerKey: providerKey);
      case ContributionTab.overview:
        return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
  }

  /// Builds loading skeleton for Summary tab content
  Widget _buildSummaryLoadingSkeleton() =>
      const _SummaryContentLoadingSkeleton();
}

/// Loading skeleton for Summary tab content (calendar, activity overview, highlights)
class _SummaryContentLoadingSkeleton extends StatelessWidget {
  const _SummaryContentLoadingSkeleton();

  @override
  Widget build(final BuildContext context) => ShimmerScope(
    child: Column(
      children: <Widget>[
        // Calendar skeleton
        Padding(
          padding: EdgeInsets.all(context.spacing.itemSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Title and stats row
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  ShimmerBone.title(width: 150),
                  ShimmerBone.title(width: 100),
                ],
              ),
              context.spacing.sectionGap,
              // Calendar grid
              const ShimmerBone.block(height: 120),
              context.spacing.contentGap,
              // Stats chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const <Widget>[
                  ShimmerBone.chip(height: 28, width: 80),
                  ShimmerBone.chip(height: 28, width: 70),
                  ShimmerBone.chip(height: 28, width: 75),
                  ShimmerBone.chip(height: 28, width: 65),
                ],
              ),
            ],
          ),
        ),

        context.spacing.sectionGap,

        // Divider between calendar and activity overview
        const Divider(),

        context.spacing.sectionGap,

        // Activity overview skeleton (radar chart section)
        Padding(
          padding: EdgeInsets.all(context.spacing.itemSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Section header skeleton
              const Padding(
                padding: EdgeInsets.fromLTRB(8, 0, 8, 12),
                child: ShimmerBone(height: 24, width: 180),
              ),
              context.spacing.itemGap,
              const ShimmerBone.title(width: 120),
              context.spacing.sectionGap,
              Row(
                children: <Widget>[
                  // Repositories list
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: List.generate(
                        3,
                        (final int index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: <Widget>[
                              const ShimmerBone.icon(size: 16),
                              context.spacing.itemGap,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    const ShimmerBone.text(),
                                    context.spacing.tightGap,
                                    const ShimmerBone.label(width: 80),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  context.spacing.sectionGap,
                  // Radar chart
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: <Widget>[
                        const ShimmerBone.text(width: 80),
                        context.spacing.contentGap,
                        const ShimmerBone.block(height: 150, width: 150),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
      ],
    ),
  );
}
