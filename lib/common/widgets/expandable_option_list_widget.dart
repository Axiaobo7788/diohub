import 'package:diohub/style/surface_style_theme.dart';
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
    this.maxWidth = 300,
    super.key,
  });

  /// List of options to display
  final List<ExpandableOption> options;

  /// Callback to collapse the expandable widget
  final VoidCallback onCollapse;

  /// Maximum width constraint for the list
  final double maxWidth;

  Widget _buildOptionTile({
    required BuildContext context,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required ExpandableOption option,
  }) {
    final surfaceStyle =
        theme.extension<SurfaceStyleTheme>() ?? const SurfaceStyleTheme();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          option.onTap();
          onCollapse();
        },
        borderRadius: surfaceStyle.borderRadius(size: BorderRadiusSize.medium),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: option.isSelected
                ? colorScheme.primaryContainer.withOpacity(0.3)
                : Colors.transparent,
            borderRadius:
                surfaceStyle.borderRadius(size: BorderRadiusSize.medium),
          ),
          child: Row(
            children: [
              if (option.icon != null) ...[
                Icon(
                  option.icon,
                  size: 20,
                  color: option.isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  option.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: option.isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    fontWeight:
                        option.isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (option.isSelected)
                Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(8),
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isLast = index == options.length - 1;

            return Container(
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: colorScheme.outline.withOpacity(0.1),
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
  });

  /// Label text for the option
  final String label;

  /// Whether this option is currently selected
  final bool isSelected;

  /// Callback when the option is tapped
  final VoidCallback onTap;

  /// Optional icon for the option
  final IconData? icon;
}

















