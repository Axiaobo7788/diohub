import 'package:diohub/common/widgets/expandable_option_list_widget.dart';
import 'package:flutter/material.dart';

/// A generic option selector that wraps [ExpandableOptionListWidget].
///
/// Works with Dart `enum` types, `built_value` `EnumClass` values, or
/// any type with a fixed list of values. Eliminates boilerplate by mapping
/// values to [ExpandableOption] instances automatically.
///
/// Example usage:
/// ```dart
/// EnumOptionListWidget<ThemeMode>(
///   values: ThemeMode.values,
///   selected: currentThemeMode,
///   onChanged: (m) => updateThemeMode(m),
///   labelBuilder: (m) => switch (m) {
///     ThemeMode.light => 'Light',
///     ThemeMode.dark => 'Dark',
///     ThemeMode.system => 'Auto',
///   },
///   iconBuilder: (m) => switch (m) {
///     ThemeMode.light => Icons.light_mode,
///     ThemeMode.dark => Icons.dark_mode,
///     ThemeMode.system => Icons.brightness_auto,
///   },
///   onCollapse: onCollapse,
/// )
/// ```
class EnumOptionListWidget<T> extends StatelessWidget {
  const EnumOptionListWidget({
    required this.values,
    required this.selected,
    required this.onChanged,
    required this.labelBuilder,
    required this.onCollapse,
    this.iconBuilder,
    this.subtitleBuilder,
    this.enabledBuilder,
    super.key,
  });

  /// All enum values to display as options
  final List<T> values;

  /// The currently selected value
  final T selected;

  /// Callback when an option is selected
  final ValueChanged<T> onChanged;

  /// Converts an enum value to its display label
  final String Function(T) labelBuilder;

  /// Callback to collapse the expandable widget
  final VoidCallback onCollapse;

  /// Optional: converts an enum value to an icon
  final IconData Function(T)? iconBuilder;

  /// Optional: converts an enum value to a subtitle string
  final String? Function(T)? subtitleBuilder;

  /// Optional: determines whether an option is enabled
  /// Defaults to all options being enabled.
  final bool Function(T)? enabledBuilder;

  @override
  Widget build(final BuildContext context) => ExpandableOptionListWidget(
        options: values
            .map(
              (final v) => ExpandableOption(
                icon: iconBuilder?.call(v),
                label: labelBuilder(v),
                subtitle: subtitleBuilder?.call(v),
                isSelected: v == selected,
                enabled: enabledBuilder?.call(v) ?? true,
                onTap: () => onChanged(v),
              ),
            )
            .toList(),
        onCollapse: onCollapse,
      );
}
