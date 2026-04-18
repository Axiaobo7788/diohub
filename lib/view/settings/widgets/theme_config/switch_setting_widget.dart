import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// Reusable widget for boolean switch settings
class SwitchSettingWidget extends StatelessWidget {
  const SwitchSettingWidget({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    super.key,
    this.icon,
  });

  final String title;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppSpacing spacing = context.spacing;

    return SwitchListTile(
      secondary: icon != null
          ? Icon(
              icon,
              size: 22,
              color: colorScheme.onSurfaceVariant,
            )
          : null,
      title: Text(title),
      subtitle: description != null ? Text(description!) : null,
      value: value,
      onChanged: onChanged,
      contentPadding: spacing.cardContentPadding,
    );
  }
}
