import 'package:diohub/common/events/events.dart';
import 'package:diohub/common/misc/collapsible_app_bar.dart';
import 'package:diohub/common/misc/shimmer_widget.dart';
import 'package:diohub/common/widgets/styled_divider.dart';
import 'package:diohub/models/contributions/contribution_chip_type.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/style/surface_style_theme.dart';
import 'package:diohub/view/profile/about/widgets/activity_timeline_section.dart';
import 'package:diohub/view/profile/about/widgets/contribution_summary_tab.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// Section with dropdown selection showing Summary, Contributions timeline, and Activity feed
/// Appears below the contribution calendar
class TabbedContributionSection extends StatefulWidget {
  const TabbedContributionSection({
    required this.contributionsAsync,
    required this.userName,
    required this.createdAt,
    required this.providerKey,
    this.onChipTap,
    this.topWidget,
    super.key,
  });

  final AsyncValue<ContributionCollectionResult> contributionsAsync;
  final String userName;
  final DateTime? createdAt;
  final ContributionQueryKey providerKey;
  final void Function(ContributionChipType chipType)? onChipTap;
  final Widget? topWidget;

  /// Extract display values from providerKey
  int? get selectedYear => providerKey.dateRange.displayYear;
  DateTime? get customFromDate => providerKey.dateRange.displayFromDate;
  DateTime? get customToDate => providerKey.dateRange.displayToDate;
  bool get useCustomRange => providerKey.dateRange.isCustomRange;

  @override
  State<TabbedContributionSection> createState() =>
      _TabbedContributionSectionState();
}

class _TabbedContributionSectionState extends State<TabbedContributionSection> {
  int _selectedIndex = 0;

  static const List<String> _options = ['Summary', 'Contributions', 'Activity'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final SliverOverlapAbsorberHandle overlapHandle =
        NestedScrollView.sliverOverlapAbsorberHandleFor(context);

    return CustomScrollView(
      slivers: [
        // Inject overlap to handle NestedScrollView header spacing
        SliverOverlapInjector(handle: overlapHandle),
        // Top widget (expandable metadata) - translate up to remove overlap spacing
        if (widget.topWidget != null)
          SliverToBoxAdapter(
            child: widget.topWidget!,
          ),
        // Dropdown selection - always visible, even during loading
        SliverPinnedHeader(
          child: FrostedBackdrop(
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 4),
            child: _buildDropdown(theme, colorScheme),
          ),
        ),
        // Content based on selected index - handles loading/error states
        _buildContentForIndex(_selectedIndex),
      ],
    );
  }

  Widget _buildDropdown(ThemeData theme, ColorScheme colorScheme) {
    return Builder(
      builder: (BuildContext context) => InkWell(
        onTap: () {},
        borderRadius: Theme.of(context).surfaceStyle.borderRadiusMedium(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: Theme.of(context).surfaceStyle.borderRadiusMedium(),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: DropdownButton<int>(
            value: _selectedIndex,
            onChanged: (int? newIndex) {
              if (newIndex != null) {
                setState(() => _selectedIndex = newIndex);
              }
            },
            items: List.generate(
              _options.length,
              (index) => DropdownMenuItem<int>(
                value: index,
                child: Center(
                  child: Text(
                    _options[index],
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            underline: const SizedBox.shrink(),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: colorScheme.primary,
              size: 16,
            ),
            isExpanded: true,
            isDense: true,
            alignment: Alignment.center,
            dropdownColor: colorScheme.surface,
            borderRadius: Theme.of(context).surfaceStyle.borderRadiusMedium(),
            selectedItemBuilder: (BuildContext context) {
              return List.generate(
                _options.length,
                (index) => Center(
                  child: Text(
                    _options[index],
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContentForIndex(final int index) {
    // For Summary tab (index 0), handle loading/error states
    if (index == 0) {
      return widget.contributionsAsync.when(
        data: (final ContributionCollectionResult result) {
          return SliverToBoxAdapter(
            child: ContributionSummaryTab(
              contributionResult: result,
              userName: widget.userName,
              createdAt: widget.createdAt,
              providerKey: widget.providerKey,
              onChipTap: widget.onChipTap,
            ),
          );
        },
        loading: () => _buildSummaryLoadingSkeleton(),
        error: (final Object error, final StackTrace stackTrace) {
          if (kDebugMode) {
            debugPrint('Error loading contribution data: $error');
            debugPrint('Stack trace: $stackTrace');
          }

          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Unable to load contribution data',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withOpacity(0.7),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    // Other tabs don't depend on contributionResult, so render directly
    switch (index) {
      case 1:
        // Contributions timeline tab (already returns sliver)
        return ActivityTimelineSection(
          providerKey: widget.providerKey,
        );
      case 2:
        // Activity feed tab - wrap Events widget in sliver
        return Events(
          privateEvents: false,
          specificUser: widget.userName,
        );
      default:
        return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
  }

  /// Builds loading skeleton for Summary tab content (below dropdown)
  Widget _buildSummaryLoadingSkeleton() {
    return SliverToBoxAdapter(
      child: _SummaryContentLoadingSkeleton(),
    );
  }
}

/// Loading skeleton for Summary tab content (calendar, activity overview, highlights)
/// Note: Dropdown is shown separately above this content
class _SummaryContentLoadingSkeleton extends StatelessWidget {
  const _SummaryContentLoadingSkeleton();

  @override
  Widget build(final BuildContext context) {
    return Column(
      children: <Widget>[
        // Calendar skeleton
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Title and stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  ShimmerWidget.container(
                    height: 20,
                    width: 150,
                  ),
                  ShimmerWidget.container(
                    height: 20,
                    width: 100,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Calendar grid
              ShimmerWidget.container(
                height: 120,
                width: double.infinity,
              ),
              const SizedBox(height: 12),
              // Stats chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ShimmerWidget.container(height: 28, width: 80),
                  ShimmerWidget.container(height: 28, width: 70),
                  ShimmerWidget.container(height: 28, width: 75),
                  ShimmerWidget.container(height: 28, width: 65),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Divider between calendar and activity overview
        StyledDivider(),

        const SizedBox(height: 16),

        // Activity overview skeleton (radar chart section)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Section header skeleton
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                child: ShimmerWidget.container(
                  height: 24,
                  width: 180,
                ),
              ),
              const SizedBox(height: 8),
              ShimmerWidget.container(
                height: 18,
                width: 120,
              ),
              const SizedBox(height: 16),
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
                              ShimmerWidget.container(
                                height: 16,
                                width: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    ShimmerWidget.container(
                                      height: 14,
                                      width: double.infinity,
                                    ),
                                    const SizedBox(height: 4),
                                    ShimmerWidget.container(
                                      height: 12,
                                      width: 80,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Radar chart
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: <Widget>[
                        ShimmerWidget.container(
                          height: 14,
                          width: 80,
                        ),
                        const SizedBox(height: 12),
                        ShimmerWidget.container(
                          height: 150,
                          width: 150,
                        ),
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
    );
  }
}
