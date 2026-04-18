import 'package:diohub/common/cards/issue_pull_card_data.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/diff_colors.dart';
import 'package:diohub/style/opacities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Shows CI check pass/fail ratio with optional mini segmented bar.
///
/// When [totalCount] and [state] are set: "N checks ✓" or "N checks ✗" with icon.
/// When only [state] is set: same as [ChecksStatusChip] (icon + state).
/// When [state] is null: returns [SizedBox.shrink].
class CICheckRatioChip extends StatelessWidget {
  const CICheckRatioChip({
    required this.state,
    this.totalCount,
    this.passedCount,
    this.failedCount,
    this.showChevron = false,
    super.key,
  });

  final CardChecksState? state;
  final int? totalCount;
  final int? passedCount;
  final int? failedCount;
  final bool showChevron;

  @override
  Widget build(final BuildContext context) {
    if (state == null) {
      return const SizedBox.shrink();
    }
    final AppSpacing spacing = context.spacing;
    final Color color = _colorForState(context);
    final IconData icon = _iconForState();
    final String label = _label(context);

    return TintedChip(
      color: color,
      icon: icon,
      label: label,
      iconSize: 12,
      padding: spacing.chipPadding,
      minContentHeight: 16,
      gap: spacing.tightSpacing,
      trailing: showChevron
          ? Icon(Icons.expand_more_rounded, size: 10, color: color.muted)
          : null,
    );
  }

  Color _colorForState(final BuildContext context) {
    switch (state!) {
      case CardChecksState.success:
        return DiffColors.addition;
      case CardChecksState.failure:
      case CardChecksState.error:
        return DiffColors.deletion;
      case CardChecksState.pending:
      case CardChecksState.expected:
        return DiffColors.modified;
    }
  }

  IconData _iconForState() {
    switch (state!) {
      case CardChecksState.success:
        return Octicons.check_circle;
      case CardChecksState.failure:
        return Octicons.x_circle;
      case CardChecksState.error:
        return Octicons.alert;
      case CardChecksState.pending:
      case CardChecksState.expected:
        return Octicons.clock;
    }
  }

  String _label(final BuildContext context) {
    if (totalCount != null && totalCount! > 0) {
      if (passedCount != null && failedCount != null) {
        return '$passedCount/$totalCount';
      }
      final String iconChar = state == CardChecksState.success ? '✓' : '✗';
      return '$totalCount checks $iconChar';
    }
    switch (state!) {
      case CardChecksState.success:
        return 'Checks passed';
      case CardChecksState.failure:
      case CardChecksState.error:
        return 'Checks failed';
      case CardChecksState.pending:
      case CardChecksState.expected:
        return 'Checks pending';
    }
  }
}
