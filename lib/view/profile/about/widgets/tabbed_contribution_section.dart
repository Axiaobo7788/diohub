import 'package:diohub/common/events/events.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/view/profile/about/widgets/activity_timeline_section.dart';
import 'package:diohub/view/profile/about/widgets/contribution_summary_tab.dart';
import 'package:flutter/material.dart';

/// Tabbed section showing Summary, Contributions timeline, and Activity feed
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
    super.key,
  });

  final ContributionCollectionResult contributionResult;
  final String userName;
  final int? selectedYear;
  final DateTime? customFromDate;
  final DateTime? customToDate;
  final bool useCustomRange;
  final DateTime? createdAt;

  @override
  State<TabbedContributionSection> createState() =>
      _TabbedContributionSectionState();
}

class _TabbedContributionSectionState extends State<TabbedContributionSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Enhanced tab bar with subtle border
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            // Color-only design: No indicator, just color change
            indicator: const BoxDecoration(),
            indicatorSize: TabBarIndicatorSize.label,
            indicatorPadding: EdgeInsets.zero,
            dividerColor: Colors.transparent,
            tabAlignment: TabAlignment.center,
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.2,
            ),
            unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              letterSpacing: 0.1,
            ),
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant.withOpacity(0.6),
            labelPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            tabs: const [
              Tab(
                height: 40,
                text: 'Summary',
              ),
              Tab(
                height: 40,
                text: 'Contributions',
              ),
              Tab(
                height: 40,
                text: 'Activity',
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Summary tab
              ContributionSummaryTab(
                contributionResult: widget.contributionResult,
                userName: widget.userName,
                selectedYear: widget.selectedYear,
                customFromDate: widget.customFromDate,
                customToDate: widget.customToDate,
                useCustomRange: widget.useCustomRange,
                createdAt: widget.createdAt,
              ),
              // Contributions timeline tab
              CustomScrollView(
                slivers: [
                  ActivityTimelineSection(
                    userName: widget.userName,
                    selectedYear: widget.selectedYear,
                    customFromDate: widget.customFromDate,
                    customToDate: widget.customToDate,
                    useCustomRange: widget.useCustomRange,
                  ),
                ],
              ),
              // Activity feed tab
              Events(
                privateEvents: false,
                specificUser: widget.userName,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
