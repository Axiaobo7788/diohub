import 'package:diohub/common/cards/chips/metadata_chips_base.dart';
import 'package:diohub/common/cards/issue_pull_card_data.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/diff_colors.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/utils/duration_format.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class ChecksStatusChip extends StatelessWidget {
  const ChecksStatusChip({
    required this.state,
    this.showChevron = false,
    super.key,
  });

  final CardChecksState? state;
  final bool showChevron;

  @override
  Widget build(final BuildContext context) {
    if (state == null) return const SizedBox.shrink();
    final AppSpacing spacing = context.spacing;
    final Color color;
    final IconData icon;
    switch (state!) {
      case CardChecksState.success:
        color = DiffColors.addition;
        icon = Octicons.check_circle;
        break;
      case CardChecksState.failure:
        color = DiffColors.deletion;
        icon = Octicons.x_circle;
        break;
      case CardChecksState.error:
        color = DiffColors.deletion;
        icon = Octicons.alert;
        break;
      case CardChecksState.pending:
      case CardChecksState.expected:
        color = DiffColors.modified;
        icon = Octicons.clock;
        break;
    }
    return TintedChip(
      color: color,
      icon: icon,
      iconSize: 12,
      padding: spacing.chipPadding,
      minContentHeight: 16,
      gap: spacing.tightSpacing,
      trailing: showChevron
          ? Icon(Icons.expand_more_rounded, size: 10, color: color.muted)
          : null,
    );
  }
}

class WorkflowStatusChip extends StatelessWidget {
  const WorkflowStatusChip({
    required this.runNumber,
    required this.status,
    this.conclusion,
    super.key,
  });

  final int runNumber;
  final String status;
  final String? conclusion;

  @override
  Widget build(final BuildContext context) {
    final (IconData icon, Color color) = _resolveVisual(context);
    final AppSpacing spacing = context.spacing;
    return TintedChip(
      color: color,
      icon: icon,
      label: '#$runNumber',
      padding: spacing.badgePadding,
      labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color.secondary,
            fontWeight: FontWeight.w500,
          ),
    );
  }

  (IconData, Color) _resolveVisual(final BuildContext context) {
    final cs = context.colorScheme;
    if (conclusion == 'success') {
      return (Octicons.check_circle_fill, DiffColors.addition);
    }
    if (conclusion == 'failure') {
      return (Octicons.x_circle_fill, DiffColors.deletion);
    }
    if (conclusion == 'cancelled') {
      return (Icons.cancel, cs.onSurfaceVariant);
    }
    if (conclusion == 'skipped') {
      return (Octicons.skip, cs.onSurfaceVariant);
    }
    if (conclusion == 'timed_out') {
      return (Octicons.clock, DiffColors.modified);
    }
    if (conclusion == 'action_required') {
      return (Octicons.alert, DiffColors.modified);
    }
    if (status == 'in_progress') {
      return (Icons.refresh, cs.tertiary);
    }
    if (status == 'queued') {
      return (Octicons.clock, cs.onSurfaceVariant);
    }
    if (status == 'waiting') {
      return (Octicons.clock, DiffColors.modified);
    }
    return (Octicons.circle, cs.onSurfaceVariant);
  }
}

class DurationChip extends StatelessWidget {
  const DurationChip({
    required this.start,
    required this.end,
    super.key,
  });

  final DateTime start;
  final DateTime end;

  @override
  Widget build(final BuildContext context) {
    final diff = end.difference(start);
    final String label = formatDuration(diff, granularity: DurationGranularity.secondsUp);
    return MetadataChip(
      leading: Icon(Octicons.clock, size: 12),
      label: label,
    );
  }
}

class DeploymentStateChip extends StatelessWidget {
  const DeploymentStateChip({
    required this.state,
    this.statusState,
    super.key,
  });

  final String? state;
  final String? statusState;

  @override
  Widget build(final BuildContext context) {
    final (IconData icon, Color color) = _resolve(context);
    final AppSpacing spacing = context.spacing;
    return TintedChip(
      color: color,
      icon: icon,
      padding: spacing.badgePadding,
    );
  }

  (IconData, Color) _resolve(final BuildContext context) {
    final cs = context.colorScheme;
    if (statusState == 'SUCCESS') {
      return (Octicons.check_circle_fill, DiffColors.addition);
    }
    if (statusState == 'FAILURE') {
      return (Octicons.x_circle_fill, DiffColors.deletion);
    }
    if (state == 'ACTIVE') {
      return (Octicons.rocket, cs.primary);
    }
    if (state == 'IN_PROGRESS') {
      return (Icons.refresh, cs.tertiary);
    }
    if (state == 'QUEUED') {
      return (Octicons.clock, DiffColors.modified);
    }
    if (state == 'DESTROYED') {
      return (Icons.cancel, cs.onSurfaceVariant);
    }
    if (state == 'INACTIVE') {
      return (Octicons.circle, cs.onSurfaceVariant);
    }
    return (Octicons.rocket, cs.onSurfaceVariant);
  }
}
