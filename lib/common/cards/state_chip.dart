import 'package:diohub/common/utils/github_visual_styles.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub_models/models/visual_state.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

/// A unified state chip widget for displaying issue or PR state.
/// Accepts a single [VisualState] that encodes all state information.
class StateChip extends StatelessWidget {
  const StateChip({
    required this.number,
    required this.state,
    this.useStateColor = true,
    super.key,
  });

  final int number;
  final VisualState state;
  final bool useStateColor;

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    final GitHubActionVisual visual = GitHubVisualStyles.fromVisualState(state);

    final Color stateColor =
        useStateColor ? visual.color : context.colorScheme.onSurfaceVariant;

    return TintedChip(
      color: stateColor,
      icon: visual.icon,
      label: '$number',
      padding: spacing.badgePadding,
      labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: useStateColor
                ? stateColor.secondary
                : context.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
    );
  }
}
