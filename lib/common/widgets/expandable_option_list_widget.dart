import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';

/// A reusable widget for displaying a list of options in expandable action buttons
///
/// This widget provides a consistent UI for option lists with:
/// - Selectable items with icons and labels
/// - Visual indication of selected state
/// - Proper spacing and borders between items
///
/// Example usage:
/// ```dart
/// ExpandableOptionListWidget(
///   options: [
///     ExpandableOption(
///       icon: Icons.light_mode,
///       label: 'Light',
///       isSelected: currentMode == ThemeMode.light,
///       onTap: () => setMode(ThemeMode.light),
///     ),
///     ExpandableOption(
///       icon: Icons.dark_mode,
///       label: 'Dark',
///       isSelected: currentMode == ThemeMode.dark,
///       onTap: () => setMode(ThemeMode.dark),
///     ),
///   ],
///   onCollapse: onCollapse,
/// )
/// ```
class ExpandableOptionListWidget extends StatelessWidget {
  const ExpandableOptionListWidget({
    required this.options,
    required this.onCollapse,
    super.key,
  });

  /// List of options to display
  final List<ExpandableOption> options;

  /// Callback to collapse the expandable widget
  final VoidCallback onCollapse;

  Widget _buildOptionTile({
    required final BuildContext context,
    required final ThemeData theme,
    required final ColorScheme colorScheme,
    required final ExpandableOption option,
  }) {
    final SurfaceStyle surfaceStyle =
        theme.extension<SurfaceStyle>() ?? const SurfaceStyle();
    final bool isEnabled = option.enabled;
    final Color baseTextColor =
        option.isSelected ? colorScheme.primary : colorScheme.onSurface;
    final Color mutedTextColor = colorScheme.onSurfaceVariant;
    final Color resolvedTextColor =
        isEnabled ? baseTextColor : mutedTextColor.muted;
    final Color resolvedIconColor = option.isSelected
        ? colorScheme.primary
        : mutedTextColor.withValues(alpha: isEnabled ? 1.0 : 0.6);

    return TapFeedback(
      onTap: () {
        if (!isEnabled) {
          return;
        }
        option.onTap();
        if (option.collapseOnTap) {
          onCollapse();
        }
      },
      child: Container(
        padding: context.spacing.inputPadding,
        decoration: BoxDecoration(
          color: option.isSelected
              ? colorScheme.primaryContainer.borderO
              : Colors.transparent,
          borderRadius: context.radius(RadiusSize.medium),
        ),
        child: Row(
          children: <Widget>[
            if (option.leading != null) ...<Widget>[
              option.leading!,
              context.spacing.contentGap,
            ] else if (option.icon != null) ...<Widget>[
              Icon(
                option.icon,
                size: 20,
                color: resolvedIconColor,
              ),
              context.spacing.contentGap,
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    option.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: resolvedTextColor,
                      fontWeight:
                          option.isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (option.subtitle != null &&
                      option.subtitle!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      option.subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: mutedTextColor.strong,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (option.trailing != null) ...<Widget>[
              context.spacing.itemGap,
              option.trailing!,
            ] else if (option.isSelected) ...<Widget>[
              context.spacing.itemGap,
              Icon(
                Icons.check_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final Iterable<MapEntry<int, ExpandableOption>> entries =
        options.asMap().entries;
    return Padding(
      padding: EdgeInsets.all(context.spacing.itemSpacing),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: entries.map((final MapEntry<int, ExpandableOption> entry) {
            final int index = entry.key;
            final ExpandableOption option = entry.value;
            final bool isLast = index == options.length - 1;

            return DecoratedBox(
              decoration: BoxDecoration(
                border: isLast || option.isSelected
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: colorScheme.outline.subtle,
                          width: 0.5,
                        ),
                      ),
              ),
              child: _buildOptionTile(
                context: context,
                theme: theme,
                colorScheme: colorScheme,
                option: option,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Represents a single option in an expandable option list
class ExpandableOption {
  const ExpandableOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.leading,
    this.subtitle,
    this.trailing,
    this.enabled = true,
    this.collapseOnTap = true,
  });

  /// Label text for the option
  final String label;

  /// Whether this option is currently selected
  final bool isSelected;

  /// Callback when the option is tapped
  final VoidCallback onTap;

  /// Optional icon for the option
  final IconData? icon;

  /// Optional leading widget (overrides icon when provided)
  final Widget? leading;

  /// Optional subtitle text for richer option rows
  final String? subtitle;

  /// Optional trailing widget (overrides check icon when provided)
  final Widget? trailing;

  /// Whether the option is enabled
  final bool enabled;

  /// Whether to collapse the list when tapped
  final bool collapseOnTap;
}
