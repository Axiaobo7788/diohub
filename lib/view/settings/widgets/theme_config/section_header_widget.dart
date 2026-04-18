import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// Reusable widget for section headers in settings
class SectionHeaderWidget extends StatelessWidget {
  const SectionHeaderWidget({
    required this.title,
    super.key,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final AppSpacing spacing = context.spacing;

    return Padding(
      padding: spacing.sectionTitlePaddingLarge,
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(
              icon,
              size: 22,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: spacing.tightSpacing * 2),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
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
        ],
      ),
    );
  }
}
