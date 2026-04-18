import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/widgets/dashboard_section_header.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub_graphql/queries/viewer/dashboard.query.graphql.dart';
import 'package:diohub_graphql/queries/viewer/viewer_typedefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Dashboard pinned repositories section.
class DashboardPinnedReposSection extends ConsumerWidget {
  const DashboardPinnedReposSection({required this.data, super.key});

  final DashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.spacing;
    final pinnedItems = data.viewer.pinnedItems.nodes;

    if (pinnedItems == null || pinnedItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final repos = pinnedItems
        .whereType<Query$dashboard$viewer$pinnedItems$nodes$$Repository>()
        .toList();

    if (repos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: spacing.screenPadding.copyWith(top: spacing.sectionSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DashboardSectionHeader(
            title: 'Pinned Repositories',
            icon: Octicons.pin,
          ),
          spacing.itemGap,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: repos.take(3).map((repo) {
                final name = repo.name;
                final description = repo.description;
                final stargazerCount = repo.stargazerCount;

                return Container(
                  width: 200,
                  margin: EdgeInsets.only(right: spacing.itemSpacing),
                  child: BorderedContainer(
                    padding: spacing.cardContentPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (description != null) ...[
                          spacing.tightGap,
                          Text(
                            description,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        spacing.tightGap,
                        Row(
                          children: [
                            Icon(Octicons.star, size: 12),
                            SizedBox(width: spacing.tightSpacing),
                            Text(
                              stargazerCount.toString(),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
