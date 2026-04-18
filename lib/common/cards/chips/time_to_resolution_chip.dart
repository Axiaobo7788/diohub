import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub/style/diff_colors.dart';
import 'package:diohub/utils/duration_format.dart';
import 'package:diohub/utils/indicator_utils.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Glanceable chip showing time open or time to close/merge for issues and PRs.
///
/// Open: "Open 3d" with clock icon, color by [TimeCategory].
/// Closed/Merged: "Closed in 2h" / "Merged in 1d" with check icon, green.
/// Returns [SizedBox.shrink] if [createdAt] is null.
class TimeToResolutionChip extends StatelessWidget {
  const TimeToResolutionChip({
    required this.createdAt,
    this.closedAt,
    this.mergedAt,
    this.isMerged = false,
    super.key,
  });

  final DateTime createdAt;
  final DateTime? closedAt;
  final DateTime? mergedAt;
  final bool isMerged;

  @override
  Widget build(final BuildContext context) {
    final bool resolved = closedAt != null || mergedAt != null;
    final DateTime? resolvedAt = mergedAt ?? closedAt;
    final ColorScheme cs = context.colorScheme;

    if (resolved && resolvedAt != null) {
      final Duration duration = resolvedAt.difference(createdAt);
      final String label = isMerged
          ? 'Merged in ${formatDuration(duration, granularity: DurationGranularity.hoursUp)}'
          : 'Closed in ${formatDuration(duration, granularity: DurationGranularity.hoursUp)}';
      return TintedChip(
        color: DiffColors.addition,
        icon: Octicons.check,
        label: label,
        iconSize: 12,
      );
    }

    final Duration openDuration = DateTime.now().difference(createdAt);
    final TimeCategory category = categorizeTime(openDuration);
    final Color color = _colorForCategory(category, cs);
    return TintedChip(
      color: color,
      icon: Octicons.clock,
      label: 'Open ${formatDuration(openDuration, granularity: DurationGranularity.hoursUp)}',
      iconSize: 12,
    );
  }

  Color _colorForCategory(final TimeCategory category, final ColorScheme cs) {
    switch (category) {
      case TimeCategory.fast:
        return DiffColors.addition;
      case TimeCategory.normal:
        return cs.onSurface;
      case TimeCategory.slow:
        return Colors.amber;
      case TimeCategory.stale:
        return DiffColors.deletion;
    }
  }
}
