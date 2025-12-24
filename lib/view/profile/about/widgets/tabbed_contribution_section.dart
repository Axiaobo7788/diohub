import 'package:diohub/common/events/events.dart';
import 'package:diohub/common/misc/collapsible_app_bar.dart';
import 'package:diohub/models/contributions/contribution_chip_type.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/style/surface_style_theme.dart';
import 'package:diohub/view/profile/about/widgets/activity_timeline_section.dart';
import 'package:diohub/view/profile/about/widgets/contribution_summary_tab.dart';
import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// Section with dropdown selection showing Summary, Contributions timeline, and Activity feed
/// Appears below the contribution calendar
class TabbedContributionSection extends StatefulWidget {
  const TabbedContributionSection({
    required this.contributionResult,
    required this.userName,
    required this.selectedYear,
    required this.customFromDate,
    required this.customToDate,
    required this.useCustomRange,
    required this.createdAt,
    this.onChipTap,
    this.topWidget,
    super.key,
  });

  final ContributionCollectionResult contributionResult;
  final String userName;
  final int? selectedYear;
  final DateTime? customFromDate;
  final DateTime? customToDate;
  final bool useCustomRange;
  final DateTime? createdAt;
  final void Function(ContributionChipType chipType)? onChipTap;
  final Widget? topWidget;

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
        // Dropdown selection - distinct from main tab bar
        SliverPinnedHeader(
          child: FrostedBackdrop(
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 4),
            child: _buildDropdown(theme, colorScheme),
          ),
        ),
        // Content based on selected index
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
    switch (index) {
      case 0:
        // Summary tab
        return SliverToBoxAdapter(
          child: ContributionSummaryTab(
            contributionResult: widget.contributionResult,
            userName: widget.userName,
            selectedYear: widget.selectedYear,
            customFromDate: widget.customFromDate,
            customToDate: widget.customToDate,
            useCustomRange: widget.useCustomRange,
            createdAt: widget.createdAt,
            onChipTap: widget.onChipTap,
          ),
        );
      case 1:
        // Contributions timeline tab (already returns sliver)
        return ActivityTimelineSection(
          userName: widget.userName,
          selectedYear: widget.selectedYear,
          customFromDate: widget.customFromDate,
          customToDate: widget.customToDate,
          useCustomRange: widget.useCustomRange,
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
}
