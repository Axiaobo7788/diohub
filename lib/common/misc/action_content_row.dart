import 'package:diohub/common/animations/animated_content_switcher.dart';
import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';

/// Pure layout widget for action button content - no styling or interactivity
///
/// Layout: [leading/icon] [label + subtitle] [trailing/checkbox/chevron]
///
/// Always renders full content - no conditional flags.
class ActionContentRow extends StatelessWidget {
  const ActionContentRow({
    required this.action,
    this.iconSize = 20,
    this.iconColor,
    this.textColor,
    this.labelStyle,
    super.key,
  });

  final ActionButtonData action;
  final double iconSize;
  final Color? iconColor;
  final Color? textColor;
  final TextStyle? labelStyle;

  @override
  Widget build(final BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Leading widget or icon
          _buildLeading(context),
          context.spacing.contentGap,
          // Label and subtitle (Flexible with loose so layout works when parent has unbounded width, e.g. ProminentActionsRow)
          Flexible(
            fit: FlexFit.loose,
            child: _buildLabelColumn(context),
          ),
          // Trailing widget, badge, or indicator (constrained to avoid overflow)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: _buildTrailing(context),
          ),
        ],
      );

  Widget _buildLeading(final BuildContext context) {
    final ActionButtonColors colors = action.getColors(context);
    final Color effectiveIconColor = iconColor ?? colors.iconColor;

    if (action.leading != null) {
      return SizedBox(
        width: 24,
        height: 24,
        child: AnimatedContentSwitcher(
          transition: AnimationTransition.fadeScale,
          duration: kMicroDuration,
          child: KeyedSubtree(
            key: ValueKey(action.leading.hashCode),
            child: action.leading!,
          ),
        ),
      );
    }

    return AnimatedContentSwitcher(
      transition: AnimationTransition.fadeScale,
      duration: kMicroDuration,
      child: Icon(
        action.displayIcon,
        key: ValueKey(action.displayIcon),
        size: iconSize,
        color: effectiveIconColor,
      ),
    );
  }

  Widget _buildLabelColumn(final BuildContext context) {
    final ActionButtonColors colors = action.getColors(context);
    final Color effectiveTextColor = textColor ?? colors.textColor;
    final TextStyle? effectiveLabelStyle = labelStyle ??
        Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: effectiveTextColor,
              fontWeight: action is MajorActionButton
                  ? FontWeight.w500
                  : FontWeight.w400,
            );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          action.label,
          style: effectiveLabelStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (action.subtitle != null) ...<Widget>[
          const SizedBox(height: 2),
          Text(
            action.subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant.secondary,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildTrailing(final BuildContext context) {
    if (action is CheckboxActionButton) {
      return _buildCheckboxIndicator(context, action as CheckboxActionButton);
    } else if (action.trailing != null) {
      return _buildTrailingWidget(context, action.trailing!);
    } else if (action is SheetActionButton) {
      // Show a sheet indicator icon for sheet actions
      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Icon(
          Icons.open_in_new_rounded,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(
                alpha: action.enabled ? 0.6 : 0.3,
              ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCheckboxIndicator(
    final BuildContext context,
    final CheckboxActionButton action,
  ) =>
      Padding(
        padding: const EdgeInsets.only(left: 8),
        child: AnimatedContentSwitcher(
          transition: AnimationTransition.fadeScale,
          duration: kMicroDuration,
          child: Icon(
            action.value ? Icons.check_box : Icons.check_box_outline_blank,
            key: ValueKey(action.value),
            size: 20,
            color: action.value
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant.hinted,
          ),
        ),
      );

  Widget _buildTrailingWidget(
      final BuildContext context, final Widget trailing) {
    final ActionButtonColors colors = action.getColors(context);

    if (trailing is Text) {
      // Badge style for text trailing
      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Container(
          padding: context.spacing.badgePadding,
          decoration: BoxDecoration(
            color: colors.badgeColor.tintMedium,
            borderRadius: context.radius(RadiusSize.soft),
          ),
          child: Text(
            trailing.data ?? '',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.badgeColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      );
    }

    // Custom widget trailing
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: trailing,
    );
  }
}
