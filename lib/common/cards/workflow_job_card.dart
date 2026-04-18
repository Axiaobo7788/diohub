import 'package:auto_route/auto_route.dart';
import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub/utils/duration_format.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/workflow_job.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/style/diff_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';

/// Card for a single workflow job: expandable with steps.
/// When [repoRef] is provided, step rows and "View logs" open the job log viewer.
/// Caller MUST wrap in BorderedContainer if needed.
class WorkflowJobCard extends ConsumerWidget {
  const WorkflowJobCard({
    required this.job,
    this.repoRef,
    this.annotationCount = 0,
    super.key,
  });

  final WorkflowJob job;
  final RepoRef? repoRef;
  final int annotationCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final duration = _duration(job.startedAt, job.completedAt);

    // Build titlePrefix: status chip
    final Widget titlePrefix = _JobStatusChip(
      status: job.status,
      conclusion: job.conclusion,
    );

    // Build title: job name
    final Widget title = Text(
      job.name,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );

    // Build supplementary: duration subtitle + annotation badge
    Widget? subtitle;
    final List<Widget> subtitleWidgets = [];
    
    if (duration != null) {
      subtitleWidgets.add(
        Text(
          formatDuration(duration, granularity: DurationGranularity.secondsUp),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    
    if (annotationCount > 0) {
      subtitleWidgets.add(
        Chip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber,
                size: 14,
                color: Colors.orange,
              ),
              const SizedBox(width: 4),
              Text('$annotationCount annotation${annotationCount == 1 ? '' : 's'}'),
            ],
          ),
          backgroundColor: Colors.orange.withOpacity(0.1),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      );
    }
    
    if (subtitleWidgets.isNotEmpty) {
      subtitle = Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: subtitleWidgets,
      );
    }

    // Build trailing: view logs button (premium feature)
    Widget? trailing;
    if (repoRef != null) {
      final logRoute = ref.read(premiumRoutingProvider).logViewerRoute(
        owner: repoRef!.owner,
        repoName: repoRef!.name,
        jobId: job.id,
        jobName: job.name,
        runId: job.runId,
      );
      
      if (logRoute != null) {
        trailing = IconButton(
          icon: const Icon(Icons.description_outlined),
          tooltip: 'View logs',
          onPressed: () => context.router.push(logRoute),
        );
      }
    }

    // Build the card header using EntityCardLayout pattern
    final Widget header = Padding(
      padding: spacing.cardContentPadding,
      child: Row(
        children: [
          titlePrefix,
          SizedBox(width: spacing.itemSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                title,
                if (subtitle != null) ...[
                  SizedBox(height: spacing.tightSpacing),
                  subtitle,
                ],
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );

    // Use ExpansionTile for steps
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      title: header,
      children: job.steps
          .map(
            (WorkflowStep step) => ListTile(
              dense: true,
              leading: Icon(
                _stepIcon(step.conclusion, step.status),
                size: 20,
                color: _stepColor(context, step.conclusion, step.status),
              ),
              title: Text(
                step.name,
                style: theme.textTheme.bodyMedium,
              ),
              trailing: _stepDuration(step) != null
                  ? Text(
                      _stepDuration(step)!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  : null,
              onTap: repoRef != null
                  ? () {
                      final logRoute = ref.read(premiumRoutingProvider).logViewerRoute(
                        owner: repoRef!.owner,
                        repoName: repoRef!.name,
                        jobId: job.id,
                        jobName: job.name,
                        runId: job.runId,
                      );
                      if (logRoute != null) {
                        context.router.push(logRoute);
                      }
                    }
                  : null,
            ),
          )
          .toList(),
    );
  }

  static Duration? _duration(String? startedAt, String? completedAt) {
    if (startedAt == null || completedAt == null) return null;
    try {
      final start = DateTime.parse(startedAt);
      final end = DateTime.parse(completedAt);
      return end.difference(start);
    } catch (e, st) {
      AppLogger.warning(
        'Failed to parse workflow job duration dates',
        error: e,
        stackTrace: st,
        tag: 'WorkflowJobCard',
      );
      return null;
    }
  }

  static String? _stepDuration(WorkflowStep step) {
    if (step.startedAt == null || step.completedAt == null) return null;
    try {
      final start = DateTime.parse(step.startedAt!);
      final end = DateTime.parse(step.completedAt!);
      final d = end.difference(start);
      return formatDuration(d, granularity: DurationGranularity.secondsUp);
    } catch (e, st) {
      AppLogger.warning(
        'Failed to parse workflow step duration dates',
        error: e,
        stackTrace: st,
        tag: 'WorkflowJobCard',
      );
      return null;
    }
  }

  static IconData _stepIcon(String? conclusion, String status) {
    if (conclusion == 'success') return Octicons.check_circle_fill;
    if (conclusion == 'failure') return Octicons.x_circle_fill;
    if (conclusion == 'cancelled' || conclusion == 'skipped')
      return Icons.cancel;
    if (status == 'in_progress') return Icons.refresh;
    if (status == 'queued') return Octicons.clock;
    return Octicons.circle;
  }

  static Color _stepColor(
      BuildContext context, String? conclusion, String status) {
    final cs = context.colorScheme;
    if (conclusion == 'success') return DiffColors.addition;
    if (conclusion == 'failure' || conclusion == 'cancelled')
      return DiffColors.deletion;
    if (conclusion == 'skipped' || conclusion == 'timed_out')
      return DiffColors.modified;
    if (status == 'in_progress') return cs.tertiary;
    return cs.onSurfaceVariant;
  }
}

class _JobStatusChip extends StatelessWidget {
  const _JobStatusChip({required this.status, this.conclusion});

  final String status;
  final String? conclusion;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = _resolve(context);
    return TintedChip(
      color: color,
      icon: icon,
      label: conclusion ?? status,
      iconSize: 12,
      padding: context.spacing.badgePadding,
    );
  }

  (IconData, Color) _resolve(BuildContext context) {
    final cs = context.colorScheme;
    if (conclusion == 'success')
      return (Octicons.check_circle_fill, DiffColors.addition);
    if (conclusion == 'failure')
      return (Octicons.x_circle_fill, DiffColors.deletion);
    if (conclusion == 'cancelled') return (Icons.cancel, cs.onSurfaceVariant);
    if (conclusion == 'skipped') return (Octicons.skip, cs.onSurfaceVariant);
    if (status == 'in_progress') return (Icons.refresh, cs.tertiary);
    if (status == 'queued') return (Octicons.clock, cs.onSurfaceVariant);
    return (Octicons.circle, cs.onSurfaceVariant);
  }
}
