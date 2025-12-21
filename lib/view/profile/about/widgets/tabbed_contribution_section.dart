import 'package:diohub/common/events/events.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/view/profile/about/widgets/activity_timeline_section.dart';
import 'package:diohub/view/profile/about/widgets/contribution_summary_tab.dart';
import 'package:flutter/material.dart';

/// Tabbed section showing Summary, Contributions timeline, and Activity feed
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
  final DateTime createdAt;

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

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: theme.colorScheme.primary,
            indicatorWeight: 2,
            tabs: const [
              Tab(text: 'Summary'),
              Tab(text: 'Contributions'),
              Tab(text: 'Activity'),
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

