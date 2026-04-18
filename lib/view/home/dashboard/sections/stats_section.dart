import 'package:diohub/common/charts/stat_card_widget.dart';
import 'package:diohub/common/widgets/dashboard_section_header.dart';
import 'package:diohub/providers/dashboard/dashboard_provider.dart';
import 'package:diohub/providers/notifications/notification_count_provider.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub_graphql/queries/viewer/viewer_typedefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Dashboard stats section showing viewer's key metrics.
class DashboardStatsSection extends ConsumerWidget {
  const DashboardStatsSection({required this.data, super.key});

  final DashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.spacing;
    final user = ref.watch(currentUserProvider).value;
    final notificationCountAsync = ref.watch(unreadNotificationCountProvider);
    final notificationCount = notificationCountAsync.when(
      data: (count) => count,
      loading: () => 0,
      error: (_, __) => 0,
    );

    if (user == null) return const SizedBox.shrink();

    final stats = [
      StatCardData(
        icon: Octicons.repo,
        value: user.repositories.totalCount.toString(),
        label: 'Repositories',
      ),
      StatCardData(
        icon: Octicons.people,
        value: user.followers.totalCount.toString(),
        label: 'Followers',
      ),
      StatCardData(
        icon: Octicons.bell,
        value: notificationCount.toString(),
        label: 'Notifications',
      ),
      StatCardData(
        icon: Octicons.git_commit,
        value: data
            .viewer
            .contributionsCollection
            .contributionCalendar
            .totalContributions
            .toString(),
        label: 'Contributions',
      ),
    ];

    return Padding(
      padding: spacing.screenPadding.copyWith(top: spacing.sectionSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DashboardSectionHeader(title: 'Overview', icon: Octicons.graph),
          spacing.itemGap,
          StatCardGrid(
            stats: stats,
            crossAxisCount: 2,
            spacing: spacing.itemSpacing,
            runSpacing: spacing.itemSpacing,
          ),
        ],
      ),
    );
  }
}
