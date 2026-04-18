import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// Reusable widget for selecting enum values
class EnumSettingWidget<T extends Enum> extends StatelessWidget {
  const EnumSettingWidget({
    required this.title,
    required this.description,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.labelBuilder,
    super.key,
    this.icon,
  });

  final String title;
  final String? description;
  final T value;
  final List<T> options;
  final ValueChanged<T> onChanged;
  final String Function(T) labelBuilder;
  final IconData? icon;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppSpacing spacing = context.spacing;

    return ListTile(
      leading: icon != null
          ? Icon(
              icon,
              size: 22,
              color: colorScheme.onSurfaceVariant,
            )
          : null,
      title: Text(title),
      subtitle: description != null ? Text(description!) : null,
      contentPadding: spacing.cardContentPadding,
      trailing: SizedBox(
        width: 160,
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: options
              .map(
                (final T option) => DropdownMenuItem<T>(
                  value: option,
                  child: Text(labelBuilder(option)),
                ),
              )
              .toList(),
          onChanged: (final T? newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ),
    );
  }
}
