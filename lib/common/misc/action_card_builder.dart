import 'package:diohub/common/animations/animations.dart';
import 'package:diohub/common/misc/action_card_style.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/expandable_action_card.dart';
import 'package:diohub/common/misc/highlighted_container.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

// Re-export ActionButtonColors
export 'package:diohub/common/misc/collapsible_action_buttons.dart'
    show ActionButtonColors;

/// Calculates colors for action buttons based on their state and type
/// This centralizes the color logic used across all action button builders
///
/// This is a convenience wrapper around [ActionButtonData.getColors]
ActionButtonColors calculateActionButtonColors(
  final BuildContext context,
  final ActionButtonData action, {
  final bool forProminentButton = false,
  final Color? seedColor,
}) =>
    action.getColors(
      context,
      forProminentButton: forProminentButton,
      seedColor: seedColor,
    );

/// Formats size in KB to human-readable format (KB, MB, GB)
String formatSize(final int? sizeInKB) {
  if (sizeInKB == null) return '';
  if (sizeInKB < 1024) {
    return '$sizeInKB KB';
  } else if (sizeInKB < 1024 * 1024) {
    return '${(sizeInKB / 1024).toStringAsFixed(1)} MB';
  } else {
    return '${(sizeInKB / (1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Helper function to build a trailing widget for action button showing count
Widget buildActionButtonTrailingCount(
        final BuildContext context, final int count) =>
    Text(
      count.toString(),
      style: context.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );

/// Helper function to build a modern, sleek count badge for action buttons
/// Uses a subtle pill-shaped design with good contrast
Widget buildModernCountBadge(final BuildContext context, final int count) =>
    Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.spacing.itemSpacing, vertical: 3),
      decoration: context.surfaceDecoration(
        RadiusSize.medium,
        color: context.colorScheme.surfaceContainerHighest.strong,
        border: Border.all(
          color: context.colorScheme.outline.subtle,
          width: 0.5,
        ),
      ),
      child: Text(
        count.toString(),
        style: context.textTheme.labelSmall?.copyWith(
          color: context.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );

/// Helper function to build a trailing widget for action button showing size
Widget buildActionButtonTrailingSize(
        final BuildContext context, final int sizeInKB) =>
    Text(
      formatSize(sizeInKB),
      style: context.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );

/// Builds a standard action card widget matching iOS liquid glass pill-button style.
///
/// Design inspired by iOS navigation bars:
/// - Vertical pill-shaped button (icon above label)
/// - Translucent background with subtle border
/// - Badge as circular overlay on icon
/// - Clean, compact appearance
Widget buildStandardActionCard(
  final BuildContext context,
  final ActionButtonData action, {
  final double iconSize = 20,
  final RadiusSize size = RadiusSize.medium,
  final EdgeInsets padding =
      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
}) {
  final ActionButtonColors colors =
      calculateActionButtonColors(context, action);

  // Standard card uses primary for icon, slightly muted text
  final Color iconColor =
      action.enabled && !action.isDestructive && !action.isPositive
          ? (action.iconColor ?? context.colorScheme.primary)
          : colors.iconColor;
  final Color textColor =
      action.enabled && !action.isDestructive && !action.isPositive
          ? context.colorScheme.onSurface.emphasized
          : colors.textColor;

  // Special handling for positive actions in standard cards
  final Color effectiveIconColor =
      action.isPositive ? Colors.green.shade400 : iconColor;
  final Color effectiveTextColor =
      action.isPositive ? Colors.green.shade300 : textColor;

  // Extract badge text from trailing widget
  final String? badgeText = action.badgeText;

  return Material(
    color: Colors.transparent,
    child: AbsorbPointer(
      absorbing: !action.enabled,
      child: InkWell(
        onTap: action.enabled
            ? switch (action) {
                MinorActionButton(:final VoidCallback? onTap) => onTap,
                CheckboxActionButton(
                  :final ValueChanged<bool>? onChanged,
                  :final bool value
                ) =>
                  () {
                    onChanged?.call(!value);
                  },
                _ => null,
              }
            : null,
        borderRadius: context.radius(size),
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Icon with badge overlay
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: effectiveIconColor.tintMedium,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      action.displayIcon,
                      size: iconSize,
                      color: effectiveIconColor,
                    ),
                  ),
                  // Badge overlay on icon (top-right)
                  if (badgeText != null && badgeText.isNotEmpty)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.badgeColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: Text(
                            badgeText,
                            style: (context.textTheme.labelSmall ??
                                    const TextStyle())
                                .copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.badgeTextColor,
                              height: 1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              context.spacing.compactGap,
              // Label below icon
              Text(
                action.label,
                style: context.textTheme.labelSmall?.copyWith(
                  color: effectiveTextColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Builds a prominent/expanded action card widget for important actions.
///
/// Used for actions like "Comment" on issue screens - larger, more prominent design.
/// Features:
/// - Horizontal layout (icon + label side by side)
/// - More prominent appearance
/// - Larger touch target
/// - Can span full width when in expanded vertical layout
///
/// Accepts MajorActionButton which has onTap field.
///
/// Note: Padding is now handled internally (12h, 8v)
Widget buildProminentActionCard(
  final BuildContext context,
  final ActionButtonData action, {
  final double iconSize = 20,
  final RadiusSize size = RadiusSize.medium,
  final Color? seedColor,
  final double? borderRadiusOverride,
}) {
  // Calculate colors using shared function
  final ActionButtonColors colors = calculateActionButtonColors(
    context,
    action,
    forProminentButton: true,
    seedColor: seedColor,
  );

  // Extract badge text from trailing widget or use trailing widget directly
  final String? badgeText = action.badgeText;
  final Widget? trailingWidget =
      action.trailing != null && action.trailing is! Text
          ? action.trailing
          : null;

  // Get onTap from MajorActionButton or CheckboxActionButton
  final VoidCallback? onTap = switch (action) {
    MajorActionButton(:final VoidCallback? onTap) => onTap,
    CheckboxActionButton(
      :final ValueChanged<bool>? onChanged,
      :final bool value
    ) =>
      () {
        onChanged?.call(!value);
      },
    _ => null,
  };

  final BorderRadius effectiveBorderRadius = borderRadiusOverride != null
      ? BorderRadius.circular(borderRadiusOverride)
      : context.radius(size);

  return Material(
    color: Colors.transparent,
    borderRadius: effectiveBorderRadius,
    child: AbsorbPointer(
      absorbing: !action.enabled,
      child: InkWell(
        onTap: action.enabled ? onTap : null,
        borderRadius: effectiveBorderRadius,
        child: Ink(
          decoration: BoxDecoration(
            color: colors.backgroundColor,
            borderRadius: effectiveBorderRadius,
            border: Border.all(
              color: context.colorScheme.outline.subtle,
              width: 0.5,
            ),
          ),
          child: AnimatedSize(
            key: action.getCheckboxKey(),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            child: Padding(
              padding: context.spacing.cardContentPadding,
              child: SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Icon
                    AnimatedContentSwitcher(
                      transition: AnimationTransition.fadeScale,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        action.displayIcon,
                        key: ValueKey(action.displayIcon),
                        size: iconSize,
                        color: colors.iconColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Label and subtitle
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            style: (context.textTheme.labelLarge ??
                                    context.textTheme.bodyMedium ??
                                    const TextStyle())
                                .copyWith(
                              color: colors.textColor,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                              height:
                                  1, // Prevent extra line height from affecting Row height
                            ),
                            child: Text(
                              action.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textHeightBehavior: const TextHeightBehavior(
                                applyHeightToFirstAscent: false,
                                applyHeightToLastDescent: false,
                              ),
                            ),
                          ),
                          if (action.subtitle != null) ...<Widget>[
                            const SizedBox(height: 2),
                            Text(
                              action.subtitle!,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: colors.textColor.secondary,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Badge or trailing widget (moved to the right side)
                    if (trailingWidget != null) ...<Widget>[
                      context.spacing.itemGap,
                      trailingWidget,
                    ] else if (badgeText != null &&
                        badgeText.isNotEmpty) ...<Widget>[
                      context.spacing.itemGap,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: context.surfaceDecoration(
                          RadiusSize.small,
                          color: colors.badgeColor,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 1.5,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Center(
                          child: Text(
                            badgeText,
                            style: (context.textTheme.labelSmall ??
                                    const TextStyle())
                                .copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.badgeTextColor,
                              height: 1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Builds an expandable prominent action card widget that can expand to show options.
///
/// When expanded, shows a list of options below the button.
/// Uses ExpandableActionCard for consistent expansion behavior.
///
/// Accepts ExpandableActionButton which has expandableWidgetBuilder field.
///
/// Note: Padding is now handled internally by ActionCardStyle.toolbarExpanded
Widget buildExpandableProminentActionCard(
  final BuildContext context,
  final ActionButtonData action, {
  final VoidCallback? onOptionSelected,
  final double? borderRadiusOverride,
}) {
  // Validate action type
  if (action is! ExpandableActionButton) {
    throw ArgumentError(
      'buildExpandableProminentActionCard requires ExpandableActionButton',
    );
  }

  // Use ExpandableActionCard with toolbar styling
  // Padding is handled internally by the style
  return ExpandableActionCard(
    action: action,
    style: ActionCardStyle.toolbarExpanded,
    borderRadiusOverride: borderRadiusOverride,
    onOptionSelected: onOptionSelected,
  );
}

/// Builds an action card widget specifically for appbar collapsible sections.
///
/// Uses the original buildStandardActionCard design with Material 3 styling.
/// Matches the original UI before toolbar changes.
Widget buildAppBarActionCard(
  final BuildContext context,
  final ActionButtonData action, {
  final double iconSize = 18,
  final RadiusSize size = RadiusSize.medium,
  final EdgeInsets padding = const EdgeInsets.all(12),
}) {
  // Calculate base colors
  final ActionButtonColors colors =
      calculateActionButtonColors(context, action);

  // AppBar cards have some special styling
  Color backgroundColor;
  Color iconColor;
  Color textColor;

  if (!action.enabled) {
    backgroundColor = context.colorScheme.surfaceContainerHighest.borderO;
    iconColor = colors.iconColor;
    textColor = colors.textColor;
  } else if (action.isDestructive) {
    backgroundColor = context.colorScheme.errorContainer;
    iconColor = colors.iconColor;
    textColor = context.colorScheme.onErrorContainer;
  } else if (action.isPositive) {
    backgroundColor = Colors.green.tint;
    iconColor = Colors.green.shade700;
    textColor = Colors.green.shade900;
  } else {
    // Use surfaceContainerHigh for a slightly darker, more visible background
    backgroundColor = context.colorScheme.surfaceContainerHigh;
    iconColor = action.iconColor ?? context.colorScheme.primary;
    textColor = context.colorScheme.onSurface;
  }

  // Subtle background tint based on action type for distinction
  Color? typeBackgroundColor;
  if (action.actionType != null) {
    switch (action.actionType!) {
      case ActionButtonActionType.tab:
        typeBackgroundColor = context.colorScheme.primary.tintSubtle;
      case ActionButtonActionType.bottomSheet:
        typeBackgroundColor = context.colorScheme.secondary.tintSubtle;
      case ActionButtonActionType.navigation:
        typeBackgroundColor = context.colorScheme.tertiary.tintSubtle;
      case ActionButtonActionType.action:
        break;
    }
  }
  final Color finalBackgroundColor = typeBackgroundColor != null
      ? Color.alphaBlend(typeBackgroundColor, backgroundColor)
      : backgroundColor;

  return HighlightedContainer(
    highlightColor: iconColor,
    size: size,
    child: Material(
      color: finalBackgroundColor,
      borderRadius: context.radius(size),
      child: AbsorbPointer(
        absorbing: !action.enabled,
        child: InkWell(
          onTap: action.enabled
              ? switch (action) {
                  MinorActionButton(:final VoidCallback? onTap) => onTap,
                  _ => null,
                }
              : null,
          borderRadius: context.radius(size),
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    if (action.leading != null) ...<Widget>[
                      action.leading!,
                      context.spacing.itemGap,
                    ],
                    Icon(
                      action.icon,
                      size: iconSize,
                      color: iconColor,
                    ),
                    const Spacer(),
                    if (action.trailing != null)
                      DefaultTextStyle(
                        style:
                            (context.textTheme.titleSmall ?? const TextStyle())
                                .copyWith(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        child: action.trailing!,
                      )
                    else
                      // Reserve space for consistency when no trailing widget
                      SizedBox(
                        width: context.textTheme.titleSmall?.fontSize != null
                            ? (context.textTheme.titleSmall!.fontSize! * 2.2)
                            : 26,
                      ),
                  ],
                ),
                context.spacing.tightGap,
                Text(
                  action.label,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
