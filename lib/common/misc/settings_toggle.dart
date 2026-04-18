import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// Settings row: icon + title + optional subtitle + switch.
/// Uses theme text styles: bodyMedium for title, bodySmall for subtitle.
class SettingsToggle extends StatelessWidget {
  const SettingsToggle({
    required this.title,
    required this.value,
    required this.onChanged,
    super.key,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final AppSpacing spacing = context.spacing;

    return Padding(
      padding: spacing.cardContentPadding,
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(
              icon,
              size: 22,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: spacing.compactSpacing),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  SizedBox(height: spacing.tightSpacing),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
