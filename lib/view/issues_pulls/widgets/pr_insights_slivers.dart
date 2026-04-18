import 'package:diohub/common/charts/stat_card_widget.dart';
import 'package:diohub/common/misc/shimmer_bone.dart';
import 'package:diohub/common/pagination/pagination_phase.dart';
import 'package:diohub/common/pagination/pagination_state.dart';
import 'package:diohub/common/widgets/diff_insights_section.dart';
import 'package:diohub/common/widgets/section_header.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub/common/pull_file_edge_mapping.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_models/models/commits/commit_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/issue_pulls/issue_providers.dart';
import 'package:diohub/utils/diff_analysis.dart';
import 'package:diohub/utils/duration_format.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

List<Widget> buildPRInsightsSlivers(
  BuildContext context,
  WidgetRef ref,
  PullRequestRef pullRef,
  PullInfo data,
) {
  final spacing = context.spacing;
  return <Widget>[
    SliverPadding(
      padding: spacing.listInset,
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _PRSizeBadge(
              additions: data.additions,
              deletions: data.deletions,
              changedFiles: data.changedFiles,
            ),
            spacing.sectionGap,
            _PRLifecycleTimeline(data: data),
            spacing.sectionGap,
            _ReviewVelocityCards(data: data),
            spacing.sectionGap,
            _PRFileAnalysis(pullRef: pullRef),
          ],
        ),
      ),
    ),
  ];
}

ChangeSize _prChangeSize(int totalLines, int changedFiles) {
  if (totalLines < 10 && changedFiles <= 2) return ChangeSize.xs;
  if (totalLines < 100) return ChangeSize.small;
  if (totalLines < 500) return ChangeSize.medium;
  if (totalLines < 1000) return ChangeSize.large;
  return ChangeSize.xl;
}

String _prSizeLabel(ChangeSize size) {
  switch (size) {
    case ChangeSize.xs:
      return 'XS';
    case ChangeSize.small:
      return 'S';
    case ChangeSize.medium:
      return 'M';
    case ChangeSize.large:
      return 'L';
    case ChangeSize.xl:
      return 'XL';
  }
}

class _PRSizeBadge extends StatelessWidget {
  const _PRSizeBadge({
    required this.additions,
    required this.deletions,
    required this.changedFiles,
  });
  final int additions;
  final int deletions;
  final int changedFiles;

  @override
  Widget build(BuildContext context) {
    final total = additions + deletions;
    final size = _prChangeSize(total, changedFiles);
    final color = switch (size) {
      ChangeSize.xs => Colors.green.shade700,
      ChangeSize.small => Colors.teal.shade700,
      ChangeSize.medium => Colors.orange.shade700,
      ChangeSize.large => Colors.deepOrange.shade700,
      ChangeSize.xl => Colors.red.shade700,
    };
    return TintedChip(
      color: color,
      label: '${_prSizeLabel(size)} · $total lines · $changedFiles files',
    );
  }
}

class _PRLifecycleTimeline extends StatelessWidget {
  const _PRLifecycleTimeline({required this.data});
  final PullInfo data;

  @override
  Widget build(BuildContext context) {
    final steps = <_TimelineStepData>[];
    steps.add(_TimelineStepData(
      icon: Octicons.git_pull_request,
      label: 'Created',
      timestamp: data.createdAt,
    ));

    // Review step omitted: latestReviews.nodes do not expose createdAt in current fragment.

    if (data.mergedAt != null) {
      steps.add(_TimelineStepData(
        icon: Octicons.git_merge,
        label: 'Merged',
        timestamp: data.mergedAt!,
        delta: data.mergedAt!.difference(data.createdAt),
      ));
    } else if (data.closedAt != null) {
      steps.add(_TimelineStepData(
        icon: Octicons.git_pull_request_closed,
        label: 'Closed',
        timestamp: data.closedAt!,
        delta: data.closedAt!.difference(data.createdAt),
      ));
    }

    return SectionHeader(
      title: 'Lifecycle',
      style: SectionHeaderStyle.small,
      child: _HorizontalTimeline(steps: steps),
    );
  }
}

class _TimelineStepData {
  const _TimelineStepData({
    required this.icon,
    required this.label,
    required this.timestamp,
    this.delta,
  });
  final IconData icon;
  final String label;
  final DateTime timestamp;
  final Duration? delta;
}

class _HorizontalTimeline extends StatelessWidget {
  const _HorizontalTimeline({required this.steps});
  final List<_TimelineStepData> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < steps.length; i++) ...[
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Icon(steps[i].icon, size: 20, color: theme.colorScheme.primary),
                SizedBox(height: 4),
                Text(
                  steps[i].label,
                  style: theme.textTheme.labelSmall,
                ),
                if (steps[i].delta != null)
                  Text(
                    formatDuration(steps[i].delta!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            if (i < steps.length - 1)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: theme.colorScheme.outline,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ReviewVelocityCards extends StatelessWidget {
  const _ReviewVelocityCards({required this.data});
  final PullInfo data;

  @override
  Widget build(BuildContext context) {
    final stats = <StatCardData>[];

    if (data.mergedAt != null) {
      stats.add(StatCardData(
        icon: Octicons.git_merge,
        value: formatDuration(data.mergedAt!.difference(data.createdAt)),
        label: 'Time to merge',
        color: Colors.purple,
      ));
    }

    final reviewCount = data.latestReviews?.nodes?.length ?? 0;
    stats.add(StatCardData(
      icon: Octicons.eye,
      value: '$reviewCount',
      label: 'Reviews',
    ));

    stats.add(StatCardData(
      icon: Octicons.git_commit,
      value: '${data.commits.totalCount}',
      label: 'Commits',
    ));

    stats.add(StatCardData(
      icon: Octicons.diff,
      value: '${data.changedFiles}',
      label: 'Files',
    ));

    return StatCardGrid(
      stats: stats,
      crossAxisCount: stats.length.clamp(2, 4),
    );
  }
}

class _PRFileAnalysis extends ConsumerWidget {
  const _PRFileAnalysis({required this.pullRef});
  final PullRequestRef pullRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(pullFilesFullListControllerProvider(pullRef));
    return ValueListenableBuilder<PaginationState<PullFileEdge?>>(
      valueListenable: controller.state,
      builder: (context, state, _) {
        if (state.phase is LoadingForward && state.items.isEmpty) {
          return const ShimmerBone.block(height: 100);
        }
        if (state.phase is Failed) {
          return const SizedBox.shrink();
        }
        final edges = state.items.whereType<PullFileEdge>().toList();
        if (edges.isEmpty) return const SizedBox.shrink();
        final files = edges
            .map((e) => fileFromPullFileEdge(e))
            .toList();
        final analysis = analyzeDiffs<FileElement>(
          files: files,
          getFilename: (f) => f.filename,
          getAdditions: (f) => f.additions,
          getDeletions: (f) => f.deletions,
        );
        return DiffInsightsSection(
          analysis: analysis,
          showComplexity: false,
        );
      },
    );
  }
}
