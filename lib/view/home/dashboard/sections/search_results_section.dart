import 'package:diohub/common/cards/issue_pull_card.dart';
import 'package:diohub/common/widgets/dashboard_section_header.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub_graphql/fragments/issue_card_fields.graphql.dart';
import 'package:diohub_graphql/fragments/pull_card_fields.graphql.dart';
import 'package:diohub_graphql/queries/viewer/viewer_typedefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Parameterized dashboard section for search results (reviews, issues, PRs).
class DashboardSearchResultsSection extends ConsumerWidget {
  const DashboardSearchResultsSection({
    required this.title,
    required this.icon,
    required this.nodes,
    required this.totalCount,
    required this.limit,
    this.onTap,
    super.key,
  });

  final String title;
  final IconData icon;
  final List<Object> nodes;
  final int totalCount;
  final int limit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.spacing;

    if (nodes.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayNodes = nodes.take(limit).toList();

    return Padding(
      padding: spacing.screenPadding.copyWith(top: spacing.sectionSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardSectionHeader(
            title: title,
            icon: icon,
            count: totalCount,
            onTap: onTap,
          ),
          spacing.itemGap,
          ...displayNodes.map((node) {
            // Use IssuePullCard factory constructors
            if (node is Fragment$issueCardFields) {
              return Padding(
                padding: EdgeInsets.only(bottom: spacing.itemSpacing),
                child: IssuePullCard.fromIssue(node),
              );
            } else if (node is Fragment$pullCardFields) {
              return Padding(
                padding: EdgeInsets.only(bottom: spacing.itemSpacing),
                child: IssuePullCard.fromPullRequest(node),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }
}
