import 'package:diohub/common/animations/animated_counter_text.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/duration_format.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Duration display for workflow runs: value counts up via [AnimatedCounterText]
/// when run completes; shown in a neutral [TintedChip].
class WorkflowDurationTrend extends ConsumerWidget {
  const WorkflowDurationTrend({
    required this.start,
    required this.end,
    super.key,
  });

  final DateTime start;
  final DateTime end;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final Duration diff = end.difference(start);
    final int totalSeconds = diff.inSeconds.clamp(0, 86400 * 7); // cap 7 days
    final AppSpacing spacing = context.spacing;
    final ColorScheme cs = context.colorScheme;
    return TintedChip(
      color: cs.onSurfaceVariant,
      icon: Octicons.clock,
      iconSize: 12,
      padding: spacing.chipPadding,
      gap: spacing.tightSpacing,
      trailing: AnimatedCounterText(
        value: totalSeconds,
        formatter: (seconds) =>
            formatDuration(Duration(seconds: seconds), granularity: DurationGranularity.secondsUp),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}
