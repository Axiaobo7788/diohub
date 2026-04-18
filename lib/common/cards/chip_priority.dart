import 'package:diohub/common/cards/chips/metadata_chips_base.dart';
import 'package:flutter/material.dart';

/// Priority levels for chip truncation in entity cards.
enum ChipPriority {
  critical, // Always visible (CI status, critical state indicators)
  high, // Visible unless very constrained (labels, primary metadata)
  medium, // Visible in comfortable/detailed modes (assignees, reactions)
  low, // Only in detailed mode (low-value metadata, secondary info)
}

/// A chip with an assigned priority for intelligent truncation.
class PrioritizedChip {
  const PrioritizedChip({
    required this.widget,
    required this.priority,
  });

  final Widget widget;
  final ChipPriority priority;
}

/// Builds a chip section with intelligent truncation based on priority.
///
/// Sorts chips by priority (critical → high → medium → low), then
/// truncates to [maxVisible] chips, appending a [ShowMoreChip] if truncated.
///
/// Example:
/// ```dart
/// buildChipSection(
///   chips: [
///     PrioritizedChip(widget: CIStatusChip(...), priority: ChipPriority.critical),
///     PrioritizedChip(widget: LabelsChip(...), priority: ChipPriority.high),
///     PrioritizedChip(widget: AssigneesChip(...), priority: ChipPriority.medium),
///   ],
///   maxVisible: 3,
///   onShowMore: () => showAllChipsSheet(),
/// )
/// ```
List<Widget> buildChipSection({
  required List<PrioritizedChip> chips,
  required int maxVisible,
  VoidCallback? onShowMore,
}) {
  if (chips.isEmpty) return <Widget>[];
  
  // Sort by priority
  final List<PrioritizedChip> sorted = List<PrioritizedChip>.from(chips)
    ..sort((final PrioritizedChip a, final PrioritizedChip b) =>
        a.priority.index.compareTo(b.priority.index));
  
  // Truncate if needed
  if (sorted.length <= maxVisible) {
    return sorted.map((final PrioritizedChip c) => c.widget).toList();
  }
  
  final List<Widget> visible =
      sorted.take(maxVisible).map((final PrioritizedChip c) => c.widget).toList();
  final int remaining = sorted.length - maxVisible;
  
  if (onShowMore != null && remaining > 0) {
    visible.add(
      ShowMoreChip(
        remainingCount: remaining,
        onTap: onShowMore,
      ),
    );
  }
  
  return visible;
}
